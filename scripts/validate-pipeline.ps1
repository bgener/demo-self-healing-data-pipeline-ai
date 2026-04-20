Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComposeArgs
    )

    $process = Start-Process `
        -FilePath "docker" `
        -ArgumentList (@("compose") + $ComposeArgs) `
        -NoNewWindow `
        -PassThru `
        -Wait `
        -RedirectStandardOutput "$env:TEMP\\shdp-stdout.txt" `
        -RedirectStandardError "$env:TEMP\\shdp-stderr.txt"

    $stdout = if (Test-Path "$env:TEMP\\shdp-stdout.txt") { Get-Content "$env:TEMP\\shdp-stdout.txt" -Raw } else { "" }
    $stderr = if (Test-Path "$env:TEMP\\shdp-stderr.txt") { Get-Content "$env:TEMP\\shdp-stderr.txt" -Raw } else { "" }
    $commandText = ($ComposeArgs -join " ")

    if ($process.ExitCode -ne 0) {
        throw "docker compose $commandText failed.`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
    }

    if ($stdout) {
        Write-Host $stdout.TrimEnd()
    }
    if ($stderr) {
        Write-Host $stderr.TrimEnd()
    }
}

function Wait-ForHttp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$MaxAttempts = 30
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return Invoke-RestMethod -Uri $Url -Method Get
        } catch {
            Start-Sleep -Seconds 2
        }
    }

    throw "Timed out waiting for $Url"
}

function Wait-ForAirflowRun {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        [int]$MaxAttempts = 45
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $runs = docker compose exec -T airflow-webserver airflow dags list-runs -d self_healing_data_pipeline --no-backfill
        $runLine = ($runs | Out-String) -split "`r?`n" | Where-Object { $_ -match [regex]::Escape($RunId) } | Select-Object -First 1

        if (-not $runLine) {
            Start-Sleep -Seconds 4
            continue
        }

        $state = if ($runLine -match "\|\s+(queued|running|success|failed)\s+\|") { $Matches[1] } else { "" }

        if ($state -eq "success") {
            return $state
        }

        if ($state -eq "failed") {
            throw "Airflow DAG failed for logical date $LogicalDate"
        }

        Start-Sleep -Seconds 4
    }

    throw "Timed out waiting for Airflow DAG run $RunId"
}

Push-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
try {
    Invoke-Compose -ComposeArgs @("up", "-d")

    $health = Wait-ForHttp -Url "http://localhost:5100/health"
    Write-Host ("Orders API health: " + ($health | ConvertTo-Json -Compress))

    $orders = Invoke-RestMethod -Uri "http://localhost:5100/api/orders?limit=2" -Method Get
    $customers = Invoke-RestMethod -Uri "http://localhost:5100/api/customers?limit=2" -Method Get

    if ($orders.Count -lt 1 -or $customers.Count -lt 1) {
        throw "Seed verification failed. Orders or customers are missing."
    }

    Write-Host "Seed verification passed."

    Invoke-Compose -ComposeArgs @("exec", "-T", "airflow-webserver", "python", "/opt/airflow/scripts/init_timescaledb.py")
    Invoke-Compose -ComposeArgs @("exec", "-T", "airflow-webserver", "python", "/opt/airflow/scripts/ingest_mongo_to_timescale.py")
    Invoke-Compose -ComposeArgs @("exec", "-T", "airflow-webserver", "bash", "-lc", "cd /opt/airflow/dbt && dbt deps --profiles-dir . && dbt source freshness --profiles-dir . --target dev && dbt build --profiles-dir . --target dev")

    $rawCounts = docker compose exec -T timescaledb psql -U pipeline -d warehouse -t -A -c "select 'raw.orders=' || count(*) from raw.orders union all select 'raw.customers=' || count(*) from raw.customers order by 1;"
    $rawCounts = ($rawCounts | Out-String).Trim()
    Write-Host $rawCounts

    $martMetrics = docker compose exec -T timescaledb psql -U pipeline -d warehouse -t -A -c "select 'marts_marts.fct_order_lines=' || count(*) from marts_marts.fct_order_lines union all select 'marts_marts.dim_customers=' || count(*) from marts_marts.dim_customers union all select 'marts_marts.fct_daily_revenue=' || count(*) from marts_marts.fct_daily_revenue order by 1;"
    $martMetrics = ($martMetrics | Out-String).Trim()
    Write-Host $martMetrics

    $triggerOutput = docker compose exec -T airflow-webserver airflow dags trigger self_healing_data_pipeline
    $triggerText = ($triggerOutput | Out-String)
    Write-Host $triggerText.Trim()

    $runIdLine = $triggerText -split "`r?`n" | Where-Object { $_ -match "manual__" } | Select-Object -First 1
    if (-not $runIdLine) {
        throw "Could not parse Airflow trigger output."
    }

    $runId = if ($runIdLine -match "manual__([0-9T:\-\+]+)") { "manual__" + $Matches[1] } else { throw "Could not extract Airflow run id." }
    $dagState = Wait-ForAirflowRun -RunId $runId
    Write-Host "Airflow DAG state: $dagState"
} finally {
    Pop-Location
}
