from __future__ import annotations

import json
import os
from pathlib import Path


def check_postgres() -> dict:
    """Check TimescaleDB state: schemas, extensions, tables."""
    try:
        import psycopg2

        conn = psycopg2.connect(
            host=os.getenv("PGHOST", "localhost"),
            port=int(os.getenv("PGPORT", "5432")),
            user=os.getenv("PGUSER", "pipeline"),
            password=os.getenv("PGPASSWORD", "pipeline"),
            database=os.getenv("PGDATABASE", "warehouse"),
        )
        cur = conn.cursor()

        cur.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT LIKE 'pg_%' AND schema_name != 'information_schema';")
        schemas = [row[0] for row in cur.fetchall()]

        cur.execute("SELECT extname, extversion FROM pg_extension;")
        extensions = {row[0]: row[1] for row in cur.fetchall()}

        cur.execute("SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('raw', 'staging', 'intermediate', 'marts');")
        tables = [f"{row[0]}.{row[1]}" for row in cur.fetchall()]

        conn.close()
        return {"reachable": True, "schemas": schemas, "extensions": extensions, "tables": tables}
    except Exception as e:
        return {"reachable": False, "error": str(e)}


def check_mongo() -> dict:
    """Check MongoDB connectivity and collection counts."""
    try:
        from pymongo import MongoClient

        client = MongoClient(
            os.getenv("MONGO_CONNECTION_STRING", "mongodb://localhost:27017"),
            serverSelectionTimeoutMS=5000,
        )
        db = client[os.getenv("MONGO_DATABASE", "ecommerce")]
        collections = {}
        for name in db.list_collection_names():
            collections[name] = db[name].estimated_document_count()
        client.close()
        return {"reachable": True, "collections": collections}
    except Exception as e:
        return {"reachable": False, "error": str(e)}


def main() -> None:
    airflow_artifacts = Path("/opt/airflow/artifacts")
    default_artifacts = str(airflow_artifacts) if airflow_artifacts.exists() else str(Path.cwd() / "artifacts")
    artifacts_root = Path(os.getenv("ARTIFACTS_DIR", default_artifacts))
    output_dir = artifacts_root / "runtime-failure-pack"
    output_dir.mkdir(parents=True, exist_ok=True)

    # Capture task output if provided via env
    task_output = os.getenv("TASK_OUTPUT", "No task output captured. Check Airflow task logs.")
    (output_dir / "task_output.txt").write_text(task_output, encoding="utf-8")

    # Run diagnostics
    diagnostics = {
        "postgres": check_postgres(),
        "mongo": check_mongo(),
    }
    (output_dir / "diagnostics.json").write_text(json.dumps(diagnostics, indent=2), encoding="utf-8")

    summary = {
        "message": "Runtime failure bundle created for AI triage",
        "lane": "runtime",
        "postgres_reachable": diagnostics["postgres"]["reachable"],
        "mongo_reachable": diagnostics["mongo"]["reachable"],
        "files": sorted(str(p.relative_to(output_dir)) for p in output_dir.rglob("*") if p.is_file()),
    }
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
