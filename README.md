# ELT Data Pipeline: Airbyte + dbt + Dagster

A production-style ELT pipeline that extracts data from **Microsoft DocumentDB** (NoSQL) and the **CoinGecko REST API**, loads it into **ClickHouse** for analytics, transforms it with **dbt**, and orchestrates everything with **Dagster**. Airbyte connections are managed as **Terraform** infrastructure-as-code.

> Companion code for the blog post: [Build a Production ELT Pipeline with Airbyte, dbt, and Dagster](https://bgener.nl/blog/modern-elt-pipeline-airbyte-dbt-dagster)

[![CI](https://github.com/bgener/demo-elt-data-pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/bgener/demo-elt-data-pipeline/actions/workflows/ci.yml)
[![Pipeline Test](https://github.com/bgener/demo-elt-data-pipeline/actions/workflows/pipeline-integration.yml/badge.svg)](https://github.com/bgener/demo-elt-data-pipeline/actions/workflows/pipeline-integration.yml)

## Architecture

```
DocumentDB (NoSQL) ──→ Airbyte (MongoDB connector) ──→ ClickHouse (raw)
CoinGecko REST API ──→ Airbyte (HTTP connector)    ──→ ClickHouse (raw)
                                                          │
                                                    dbt (transform, dedup, enrich)
                                                          │
                                                    ClickHouse (analytics)
                                                          │
                                                    Dagster (orchestrate, freshness)
```

### What each component does

| Component | Role | Port |
|---|---|---|
| **DocumentDB** | Source database. MongoDB-compatible NoSQL (the engine behind Azure Cosmos DB). Stores orders and customers as nested documents. | `10260` |
| **Orders API** | .NET Web API that seeds DocumentDB with realistic data on startup. Also exposes a MongoDB aggregation pipeline endpoint to show the source DB doing real work. See [Why the Orders API exists](#the-orders-api-why-it-exists). | `5100` |
| **CoinGecko** | External REST API source. Provides real-time BTC/ETH prices used to convert crypto orders to USD. | (external) |
| **Airbyte** | Extracts data from DocumentDB (MongoDB connector) and CoinGecko (HTTP connector), loads raw JSON into ClickHouse. | `8000` |
| **ClickHouse** | Columnar analytics database. Stores raw data (from Airbyte), staging/intermediate views, and final analytical tables (from dbt). | `8123` |
| **dbt** | Transforms raw data: flattens nested documents, deduplicates Airbyte append-mode rows, enriches orders with CoinGecko crypto prices for USD conversion. | - |
| **Dagster** | Orchestrates the pipeline. Triggers Airbyte syncs, runs dbt models, enforces freshness policies (orders < 1h, prices < 15min). | `3000` |
| **Terraform** | Manages Airbyte configuration (sources, destinations, connections) as code. No shell scripts, no clicking through UIs. | - |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Docker Compose v2)
- [Terraform](https://developer.hashicorp.com/terraform/install) (>= 1.0)
- [Task](https://taskfile.dev/installation/) (task runner, optional but recommended)
- [.NET 10 SDK](https://dotnet.microsoft.com/download) (only if running the API locally outside Docker)
- [pre-commit](https://pre-commit.com/#install) (optional, for local quality gates)

## Quick Start

The fastest way to get everything running:

```bash
task setup
```

This starts all services, initializes ClickHouse, configures Airbyte via Terraform, installs dbt packages, and runs the full transform pipeline. When it finishes, open [http://localhost:3000](http://localhost:3000) for Dagster and [http://localhost:8000](http://localhost:8000) for Airbyte.

### Step-by-step (manual)

<details>
<summary>Click to expand manual steps</summary>

#### 1. Start infrastructure

```bash
docker compose up -d
docker compose ps
```

#### 2. Verify data was seeded

The Orders API populates DocumentDB with 50 customers and 500 orders on startup:

```bash
curl http://localhost:5100/api/orders
curl http://localhost:5100/api/customers
curl http://localhost:5100/api/orders/revenue/daily?days=30
```

#### 3. Initialize ClickHouse databases

```bash
docker exec -i clickhouse clickhouse-client --password clickhouse < scripts/init-clickhouse.sql
```

#### 4. Configure Airbyte with Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Terraform creates two sources (DocumentDB, CoinGecko), one destination (ClickHouse), and two connections with sync schedules. Set the connection IDs for Dagster:

```bash
export AIRBYTE_ORDERS_CONNECTION_ID=$(terraform output -raw documentdb_connection_id)
export AIRBYTE_COINGECKO_CONNECTION_ID=$(terraform output -raw coingecko_connection_id)
```

#### 5. Run dbt transformations

```bash
cd dbt && dbt deps && dbt build
```

#### 6. Open Dagster

Open [http://localhost:3000](http://localhost:3000). Click **Materialize All** to run the full pipeline, or wait for the hourly schedule.

#### 7. Query the analytics

```bash
docker exec -i clickhouse clickhouse-client --password clickhouse < scripts/sample-queries.sql
```

</details>

## Testing the Pipeline

### Integration test (local)

Run the full pipeline test locally. This spins up DocumentDB + ClickHouse, loads synthetic Airbyte output into ClickHouse raw tables, runs dbt, and validates the analytical output:

```bash
task test-pipeline
```

What it validates:
- dbt models compile and produce correct output
- Deduplication removes duplicate rows (test data includes deliberate duplicates)
- Crypto enrichment correctly converts BTC/ETH to USD using CoinGecko prices
- All completed orders have positive USD revenue
- Mart tables contain expected row counts

### Integration test (CI)

The same test runs automatically on every push and PR via the **Pipeline Integration Test** GitHub Actions workflow. It:

1. Starts DocumentDB + ClickHouse as GitHub Actions services
2. Builds and runs the .NET API to seed DocumentDB
3. Loads synthetic data into ClickHouse raw tables (simulating Airbyte output)
4. Runs `dbt build` (all models + schema tests + custom tests)
5. Validates mart output with SQL assertions
6. Fails the build if duplicates exist or USD amounts are incorrect

This lets you test the entire transform layer before merging, without needing Airbyte in CI.

## CI/CD Pipelines

### GitHub Actions Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** (`ci.yml`) | Push, PR | .NET build, Terraform fmt/validate/tflint/checkov, dbt compile, Dockerfile lint (hadolint) |
| **Pipeline Integration Test** (`pipeline-integration.yml`) | Push, PR | Full end-to-end: seed DocumentDB, load raw data, dbt build, validate output |
| **Infracost** (`infracost.yml`) | PR (infra/ changes) | Posts cloud cost estimate as a PR comment |

### Quality tooling

| Tool | What it checks | Runs in |
|---|---|---|
| **terraform fmt** | Consistent formatting | CI + pre-commit |
| **terraform validate** | HCL syntax and provider schema | CI + pre-commit |
| **tflint** | Best practices, naming conventions, unused variables | CI + pre-commit |
| **Checkov** | Security misconfigurations (credentials, permissions) | CI |
| **hadolint** | Dockerfile best practices | CI |
| **sqlfluff** | SQL style and consistency | pre-commit |
| **dbt test** | Data quality (uniqueness, not-null, accepted values, custom assertions) | CI + dbt build |
| **Infracost** | Cloud cost estimation on PR | CI (PR only) |

### Pre-commit hooks (local)

```bash
pre-commit install
pre-commit run --all-files
```

Runs terraform fmt, validate, tflint, hadolint, sqlfluff, YAML/JSON checks, and blocks direct commits to main.

## Task Runner

All common operations are available as [Taskfile](https://taskfile.dev) commands:

```bash
task --list
```

| Command | Description |
|---|---|
| `task setup` | First-time setup: start infra, configure Airbyte, run dbt |
| `task up` / `task down` | Start / stop all services |
| `task test-pipeline` | Run full pipeline integration test locally |
| `task validate` | Validate analytical output in ClickHouse |
| `task query` | Run sample analytical queries |
| `task tf-plan` | Preview Airbyte config changes |
| `task tf-apply` | Apply Airbyte config |
| `task tf-lint` | Lint Terraform files |
| `task dbt-build` | Run dbt models + tests |
| `task dbt-docs` | Generate and serve dbt documentation |
| `task lint` | Run all linters |
| `task seed-check` | Verify DocumentDB seed data |

## Project Structure

```
├── .github/workflows/
│   ├── ci.yml                      # Build, lint, validate (Terraform, dbt, Docker, .NET)
│   ├── pipeline-integration.yml    # End-to-end pipeline test with real databases
│   └── infracost.yml               # Cost estimation on PRs
├── infra/                          # Terraform: Airbyte configuration as code
│   ├── sources.tf                  # DocumentDB + CoinGecko sources
│   ├── destinations.tf             # ClickHouse destination
│   ├── connections.tf              # Sync schedules (hourly orders, 15min prices)
│   ├── variables.tf                # Connection parameters (with defaults)
│   ├── outputs.tf                  # Connection IDs for Dagster
│   └── .tflint.hcl                 # Linter rules
├── src/OrdersApi/                  # .NET API (seeds DocumentDB, exposes aggregations)
│   ├── Models/                     # Document models (nested orders, customers)
│   ├── Services/
│   │   ├── DatabaseSeeder.cs       # Seeds 50 customers + 500 orders
│   │   └── RevenueAggregationService.cs  # $unwind/$group/$sort pipeline
│   └── Endpoints/                  # Minimal API endpoints
├── airbyte/                        # Reference configs (JSON) for Airbyte connectors
├── dbt/                            # dbt project (ClickHouse)
│   ├── models/staging/             # Flatten documents, parse JSON
│   ├── models/intermediate/        # Deduplicate, enrich with CoinGecko
│   ├── models/marts/               # fct_order_lines, dim_customers, fct_daily_revenue
│   └── tests/                      # Data quality assertions (dedup, positive revenue)
├── dagster/                        # Orchestration
│   └── definitions.py              # Assets, freshness policies, hourly schedule
├── scripts/
│   ├── testdata/                   # Synthetic Airbyte output for CI testing
│   │   ├── create-raw-tables.sql   # ClickHouse raw table DDL
│   │   ├── seed-raw-orders.sql     # 10 orders (incl. deliberate duplicate)
│   │   ├── seed-raw-customers.sql  # 6 customers
│   │   └── seed-raw-crypto-prices.sql  # BTC/ETH price snapshots
│   ├── init-clickhouse.sql         # Create databases
│   └── sample-queries.sql          # Analytical queries
├── Taskfile.yml                    # Task runner commands
├── .pre-commit-config.yaml         # Local quality gates
└── docker-compose.yml              # All services
```

## The Orders API: Why It Exists

The Orders API is not part of the ELT pipeline itself. It represents **the application that already exists**: a .NET service backed by DocumentDB that serves your product.

It does two things for this demo:

1. **Seeds realistic data.** On startup, it populates DocumentDB with 50 customers and 500 orders containing nested line items (`items[]`) and shipping info (`shipping{}`). This gives the ELT pipeline real documents to extract.

2. **Demonstrates source-side aggregations.** The `/api/orders/revenue/daily` endpoint runs a MongoDB aggregation pipeline (`$unwind`, `$group`, `$sort`) directly on DocumentDB. This shows that the source database is doing real work. The ELT pipeline complements this by adding things the source cannot do alone: cross-source enrichment (CoinGecko prices), deduplication across syncs, and feeding a columnar analytics engine (ClickHouse) that handles dashboards far better than a document store.

After seeding, you can stop the API. The ELT pipeline connects directly to DocumentDB, not through the API.

## Key Concepts Demonstrated

### Infrastructure as code
Airbyte connections are defined in Terraform, not configured manually through a UI. This means your entire pipeline config is version-controlled, reviewable, and reproducible. Run `terraform apply` on a new environment and you get the same pipeline.

### Pipeline testing without Airbyte
The CI pipeline tests the dbt transform layer end-to-end by loading synthetic data directly into ClickHouse raw tables, bypassing Airbyte. This is faster, cheaper, and more reliable than running Airbyte in CI. The synthetic test data includes deliberate duplicates and multi-currency orders to exercise dedup and enrichment logic.

### Data freshness
Dagster freshness policies define SLAs: orders must be less than 1 hour stale, crypto prices less than 15 minutes. The Dagster UI shows which assets are fresh and which are overdue.

### Deduplication
Airbyte in append mode can insert duplicate rows when re-syncing. The dbt intermediate layer uses `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY _airbyte_extracted_at DESC)` to keep only the latest version of each record.

### Data enrichment
Orders paid in BTC or ETH get a USD conversion by joining with CoinGecko price snapshots. Fiat orders (USD, EUR, GBP) use static exchange rates. This cross-source join happens in `int_order_items_enriched.sql`.

### Document flattening
DocumentDB stores orders as nested documents with `items[]` arrays. The staging model `stg_order_items.sql` uses ClickHouse's `arrayJoin(JSONExtractArrayRaw(...))` to explode each item into its own row.

### Cost visibility
Every PR that changes Terraform files gets an automatic Infracost comment showing the estimated cloud cost impact. This keeps cost awareness in the development workflow, not as an afterthought.

## License

MIT
