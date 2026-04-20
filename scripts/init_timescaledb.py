from __future__ import annotations

import os
from pathlib import Path

import psycopg2


def main() -> None:
    connection = psycopg2.connect(
        host=os.getenv("PGHOST", "timescaledb"),
        port=os.getenv("PGPORT", "5432"),
        user=os.getenv("PGUSER", "pipeline"),
        password=os.getenv("PGPASSWORD", "pipeline"),
        dbname=os.getenv("PGDATABASE", "warehouse"),
    )
    connection.autocommit = True

    sql = Path("/opt/airflow/scripts/init-timescaledb.sql").read_text(encoding="utf-8")

    with connection, connection.cursor() as cursor:
        cursor.execute(sql)


if __name__ == "__main__":
    main()
