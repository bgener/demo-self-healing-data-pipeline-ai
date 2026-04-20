from __future__ import annotations

import os
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.trigger_rule import TriggerRule


DBT_ENV = {
    "PGHOST": os.getenv("PGHOST", "timescaledb"),
    "PGPORT": os.getenv("PGPORT", "5432"),
    "PGUSER": os.getenv("PGUSER", "pipeline"),
    "PGPASSWORD": os.getenv("PGPASSWORD", "pipeline"),
    "PGDATABASE": os.getenv("PGDATABASE", "warehouse"),
    "DBT_PROFILES_DIR": "/opt/airflow/dbt",
    "PATH": f"/home/airflow/.local/bin:{os.getenv('PATH', '')}",
}

DBT_BIN = "/home/airflow/.local/bin/dbt"


with DAG(
    dag_id="self_healing_data_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule="0 * * * *",
    catchup=False,
    default_args={"owner": "data-platform"},
    tags=["dbt", "airflow", "ai"],
) as dag:
    init_warehouse = BashOperator(
        task_id="init_warehouse",
        bash_command="python /opt/airflow/scripts/init_timescaledb.py",
    )

    ingest_mongo = BashOperator(
        task_id="ingest_mongo_to_timescale",
        bash_command="python /opt/airflow/scripts/ingest_mongo_to_timescale.py",
    )

    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command=f"{DBT_BIN} deps --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt",
        env=DBT_ENV,
    )

    dbt_freshness = BashOperator(
        task_id="dbt_source_freshness",
        bash_command=f"{DBT_BIN} source freshness --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt",
        env=DBT_ENV,
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"{DBT_BIN} build --project-dir /opt/airflow/dbt --profiles-dir /opt/airflow/dbt",
        env=DBT_ENV,
    )

    collect_runtime_evidence = BashOperator(
        task_id="collect_runtime_failure_evidence",
        bash_command="python /opt/airflow/scripts/collect_runtime_failure_evidence.py",
        trigger_rule=TriggerRule.ONE_FAILED,
    )

    collect_dbt_evidence = BashOperator(
        task_id="collect_dbt_failure_evidence",
        bash_command="python /opt/airflow/scripts/collect_failure_evidence.py",
        env=DBT_ENV,
        trigger_rule=TriggerRule.ONE_FAILED,
    )

    init_warehouse >> ingest_mongo >> dbt_deps >> dbt_freshness >> dbt_build
    [init_warehouse, ingest_mongo] >> collect_runtime_evidence
    [dbt_freshness, dbt_build] >> collect_dbt_evidence
