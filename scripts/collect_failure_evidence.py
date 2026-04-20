from __future__ import annotations

import json
import os
import shutil
from pathlib import Path


def copy_if_exists(source: Path, destination: Path) -> None:
    if source.exists():
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def main() -> None:
    airflow_dbt = Path("/opt/airflow/dbt")
    project_dir = airflow_dbt if airflow_dbt.exists() else Path.cwd() / "dbt"
    target_dir = project_dir / "target"
    airflow_artifacts = Path("/opt/airflow/artifacts")
    default_artifacts = str(airflow_artifacts) if airflow_artifacts.exists() else str(Path.cwd() / "artifacts")
    artifacts_root = Path(os.getenv("ARTIFACTS_DIR", default_artifacts))
    output_dir = artifacts_root / "dbt-failure-pack"
    output_dir.mkdir(parents=True, exist_ok=True)

    copy_if_exists(target_dir / "run_results.json", output_dir / "run_results.json")
    copy_if_exists(target_dir / "manifest.json", output_dir / "manifest.json")
    copy_if_exists(target_dir / "sources.json", output_dir / "sources.json")

    compiled_dir = target_dir / "compiled"
    if compiled_dir.exists():
        destination = output_dir / "compiled"
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(compiled_dir, destination)

    summary = {
        "message": "dbt failure bundle created for AI triage",
        "files": sorted(str(path.relative_to(output_dir)) for path in output_dir.rglob("*") if path.is_file()),
    }
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
