You are investigating a failed Terraform infrastructure run for a TimescaleDB data warehouse.

Your job is to review the failure bundle and decide whether the issue can be fixed safely in a narrow pull request.

Inputs:

- `plan_output.txt` -- Terraform plan or apply output showing the error
- `terraform_files/` -- all `.tf` configuration files

Rules:

- Focus on the specific Terraform error message.
- Common fixable issues: wrong schema name in the `pg_schemas` variable, missing `postgresql_extension` resource, credential mismatch, wrong provider argument.
- Prefer small fixes in `infra/*.tf` files only.
- Do not change application code, dbt models, Airflow DAGs, or Docker configuration.
- Do not change more than the minimum set of files needed to fix the failure.
- If the failure is a real infrastructure outage (database unreachable, network issue), do not propose a code fix.
- If the root cause is ambiguous, stop and explain what is missing.

Expected output:

1. Short root cause summary
2. Why the proposed fix is safe or why no safe fix exists
3. The exact files to change
4. A draft PR title and summary
