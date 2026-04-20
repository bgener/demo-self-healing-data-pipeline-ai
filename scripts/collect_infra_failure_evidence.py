from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path


def main() -> None:
    infra_dir = Path.cwd() / "infra" if (Path.cwd() / "infra").exists() else Path("/opt/airflow/infra")
    airflow_artifacts = Path("/opt/airflow/artifacts")
    default_artifacts = str(airflow_artifacts) if airflow_artifacts.exists() else str(Path.cwd() / "artifacts")
    artifacts_root = Path(os.getenv("ARTIFACTS_DIR", default_artifacts))
    output_dir = artifacts_root / "infra-failure-pack"

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Copy all .tf files so the AI can see the configuration
    tf_dest = output_dir / "terraform_files"
    tf_dest.mkdir(exist_ok=True)
    for tf_file in infra_dir.glob("*.tf"):
        shutil.copy2(tf_file, tf_dest / tf_file.name)

    # Try to capture terraform plan output
    plan_output = os.getenv("TF_PLAN_OUTPUT", "")
    if not plan_output:
        try:
            result = subprocess.run(
                ["terraform", "plan", "-detailed-exitcode", "-no-color"],
                cwd=str(infra_dir),
                capture_output=True,
                text=True,
                timeout=120,
            )
            plan_output = result.stdout + "\n" + result.stderr
        except (FileNotFoundError, subprocess.TimeoutExpired):
            plan_output = "terraform plan could not be executed"

    (output_dir / "plan_output.txt").write_text(plan_output, encoding="utf-8")

    summary = {
        "message": "Infrastructure failure bundle created for AI triage",
        "lane": "infra",
        "files": sorted(str(p.relative_to(output_dir)) for p in output_dir.rglob("*") if p.is_file()),
    }
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
