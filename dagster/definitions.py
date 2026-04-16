"""
Dagster definitions: orchestrates Airbyte syncs and dbt transformations.

Asset graph:
  Airbyte (extract + load) -> dbt staging -> dbt intermediate -> dbt marts

Freshness policies:
  - Orders: must be < 1 hour old
  - CoinGecko prices: must be < 15 minutes old
"""

import os
from pathlib import Path

from dagster import (
    AssetSelection,
    Definitions,
    FreshnessPolicy,
    ScheduleDefinition,
    define_asset_job,
)
from dagster_airbyte import (
    AirbyteResource,
    build_airbyte_assets,
)
from dagster_dbt import (
    DbtCliResource,
    dbt_assets,
    DagsterDbtTranslator,
    DagsterDbtTranslatorSettings,
)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
AIRBYTE_HOST = os.getenv("AIRBYTE_HOST", "http://localhost:8000")
DBT_PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", str(Path(__file__).parent.parent / "dbt"))

# These connection IDs are set after configuring Airbyte.
# Replace with actual UUIDs from your Airbyte instance.
AIRBYTE_ORDERS_CONNECTION_ID = os.getenv(
    "AIRBYTE_ORDERS_CONNECTION_ID", "00000000-0000-0000-0000-000000000001"
)
AIRBYTE_COINGECKO_CONNECTION_ID = os.getenv(
    "AIRBYTE_COINGECKO_CONNECTION_ID", "00000000-0000-0000-0000-000000000002"
)

# ---------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------
airbyte_resource = AirbyteResource(
    host=AIRBYTE_HOST,
    port="8000",
)

dbt_resource = DbtCliResource(
    project_dir=DBT_PROJECT_DIR,
    profiles_dir=DBT_PROJECT_DIR,
)

# ---------------------------------------------------------------------------
# Airbyte assets (extract + load)
# ---------------------------------------------------------------------------
documentdb_assets = build_airbyte_assets(
    connection_id=AIRBYTE_ORDERS_CONNECTION_ID,
    destination_tables=["orders", "customers"],
    asset_key_prefix=["airbyte", "documentdb"],
    freshness_policy=FreshnessPolicy(maximum_lag_minutes=60),
)

coingecko_assets = build_airbyte_assets(
    connection_id=AIRBYTE_COINGECKO_CONNECTION_ID,
    destination_tables=["coingecko_prices"],
    asset_key_prefix=["airbyte", "coingecko"],
    freshness_policy=FreshnessPolicy(maximum_lag_minutes=15),
)

# ---------------------------------------------------------------------------
# dbt assets (transform)
# ---------------------------------------------------------------------------
dbt_translator = DagsterDbtTranslator(
    settings=DagsterDbtTranslatorSettings(
        enable_asset_checks=True,
    )
)


@dbt_assets(
    manifest=Path(DBT_PROJECT_DIR) / "target" / "manifest.json",
    dagster_dbt_translator=dbt_translator,
)
def elt_dbt_assets(context, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()


# ---------------------------------------------------------------------------
# Jobs and schedules
# ---------------------------------------------------------------------------
sync_and_transform_job = define_asset_job(
    name="sync_and_transform",
    selection=AssetSelection.all(),
    description="Full ELT pipeline: Airbyte sync then dbt transform",
)

# Run the full pipeline every hour
hourly_schedule = ScheduleDefinition(
    job=sync_and_transform_job,
    cron_schedule="0 * * * *",
    name="hourly_elt_pipeline",
    description="Sync data from DocumentDB and CoinGecko, then run dbt transforms",
)

# ---------------------------------------------------------------------------
# Definitions
# ---------------------------------------------------------------------------
defs = Definitions(
    assets=[*documentdb_assets, *coingecko_assets, elt_dbt_assets],
    resources={
        "airbyte": airbyte_resource,
        "dbt": dbt_resource,
    },
    schedules=[hourly_schedule],
    jobs=[sync_and_transform_job],
)
