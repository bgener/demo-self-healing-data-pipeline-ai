# Self-Healing Data Pipeline with GitHub Agentic Workflows

A demo showing how to build a data pipeline that fixes itself using AI. When the pipeline fails, GitHub Actions collects the failure evidence and hands it to an AI agent. The agent classifies the failure, reads the right prompt, and opens a draft PR with a targeted fix.

Three failure surfaces. Three repair lanes. One review surface.

## How it works

```text
GitHub Actions -> Terraform -> deploy warehouse schemas
                         |
                         +-> infra failure -> collect evidence -> AI agent -> draft PR

Airflow -> init warehouse -> ingest data -> dbt build -> publish results
              |                  |               |
              +-> runtime fail   +-> runtime fail +-> dbt fail
                       |                  |               |
                  collect evidence   collect evidence  collect evidence
                       |                  |               |
                       +------ GitHub Agentic Workflow ------+
                                      |
                              classify -> label -> draft PR
```

### Runtime path

1. **Terraform** creates TimescaleDB schemas and extensions.
2. **Orders API** (.NET) seeds MongoDB with 50 customers and 500 orders.
3. **Ingestion script** loads MongoDB documents into TimescaleDB `raw` schema.
4. **dbt** transforms raw data through staging, intermediate, and marts layers.
5. **Airflow** orchestrates the full pipeline on an hourly schedule.

### Self-healing path

When something fails, the pipeline collects structured evidence and uploads it as a GitHub Actions artifact. A GitHub Agentic Workflow downloads the artifact, classifies the failure lane, reads the matching AI prompt, and proposes a draft PR.

| Lane | Trigger | Evidence | Prompt |
|---|---|---|---|
| **Infra** | Terraform plan/apply fails | `.tf` files + plan output | `self-heal-infra-failure.prompt.md` |
| **Runtime** | Init or ingest task fails | DB diagnostics + task output | `self-heal-airflow-failure.prompt.md` |
| **dbt** | dbt build or freshness fails | run_results + manifest + compiled SQL | `self-heal-dbt-failure.prompt.md` |

## Project structure

```text
.
├── .github/
│   ├── prompts/
│   │   ├── self-heal-dbt-failure.prompt.md
│   │   ├── self-heal-infra-failure.prompt.md
│   │   └── self-heal-airflow-failure.prompt.md
│   └── workflows/
│       ├── ci.yml
│       ├── pipeline-integration.yml
│       ├── infra-validate.yml
│       └── self-heal.md
├── airflow/
│   ├── dags/self_healing_pipeline.py
│   ├── Dockerfile
│   └── requirements.txt
├── dbt/
│   ├── models/staging/
│   ├── models/intermediate/
│   ├── models/marts/
│   ├── tests/
│   ├── dbt_project.yml
│   └── profiles.yml
├── infra/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── schemas.tf
│   └── outputs.tf
├── scripts/
│   ├── init-timescaledb.sql
│   ├── init_timescaledb.py
│   ├── ingest_mongo_to_timescale.py
│   ├── collect_failure_evidence.py
│   ├── collect_infra_failure_evidence.py
│   ├── collect_runtime_failure_evidence.py
│   └── validate-pipeline.ps1
├── src/OrdersApi/
├── artifacts/
└── docker-compose.yml
```

## Quick start

### Prerequisites

- Docker and Docker Compose
- [Task](https://taskfile.dev) runner
- Python 3.12 with `psycopg2-binary` and `pymongo`
- Terraform (for the infra lane)

### Start the stack

```bash
docker compose up -d
```

| Service | Port | Purpose |
|---|---|---|
| MongoDB | 27017 | Source database |
| TimescaleDB | 5432 | Data warehouse |
| Orders API | 5100 | Seeds MongoDB with demo data |
| Airflow UI | 8080 | Pipeline orchestration |

### Run the pipeline

```bash
task test-pipeline
```

### Manage infrastructure with Terraform

```bash
task infra-init
task infra-plan
task infra-apply
```

## Demo: introducing failures

### Infra lane

Edit `infra/variables.tf` and change `"raw"` to `"rw"` in `pg_schemas`:

```hcl
default = ["rw", "staging", "intermediate", "marts"]
```

Run `task infra-plan` to see the failure. Push to a branch to trigger the infra-validate workflow. The agent will see the wrong schema name and propose a fix.

### Runtime lane

Edit `scripts/init-timescaledb.sql` and rename the `raw.orders` table to `raw.orders_old`. The ingestion script will fail trying to insert into a table that does not exist. The agent will see the missing table in the diagnostics and trace it to the DDL script.

### dbt lane

Edit `dbt/models/staging/stg_orders.sql` and change `order_status` to `order_status_v2`:

```sql
order_status_v2 as order_status,
```

The dbt build will fail with `column "order_status_v2" does not exist`. The agent will read the compiled SQL and propose the fix.

## GitHub workflows

### CI (`ci.yml`)

Builds the Orders API, validates dbt, and lints Docker assets.

### Pipeline Integration Test (`pipeline-integration.yml`)

Runs the full pipeline with MongoDB and TimescaleDB services. On failure, collects evidence into the appropriate failure pack (runtime or dbt) and uploads it as an artifact.

### Infrastructure Validation (`infra-validate.yml`)

Runs `terraform plan` against a TimescaleDB service. On failure, collects infrastructure evidence and uploads it as an artifact.

### Self-Heal Agent (`self-heal.md`)

GitHub Copilot agentic workflow. Triggers after the Pipeline Integration Test or Infrastructure Validation workflow fails. Downloads the failure artifact, classifies the lane, reads the matching prompt, and opens a draft PR with the fix.

## Airflow DAG

The DAG `self_healing_data_pipeline` runs hourly:

1. `init_warehouse`
2. `ingest_mongo_to_timescale`
3. `dbt_deps`
4. `dbt_source_freshness`
5. `dbt_build`
6. `collect_runtime_failure_evidence` (runs only when init or ingest fails)
7. `collect_dbt_failure_evidence` (runs only when dbt fails)

## Local commands

```bash
task up                        # start Docker services
task down                      # stop services
task infra-init                # terraform init
task infra-plan                # terraform plan
task infra-apply               # terraform apply
task db-init                   # init TimescaleDB via SQL
task ingest                    # load MongoDB to raw schema
task dbt-build                 # run dbt models and tests
task test-pipeline             # full end-to-end pipeline
task collect-dbt-evidence      # package dbt failure artifacts
task collect-runtime-evidence  # package runtime failure evidence
task collect-infra-evidence    # package Terraform failure evidence
```

## License

MIT
