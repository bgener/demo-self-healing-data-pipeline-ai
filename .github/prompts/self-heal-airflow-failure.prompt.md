You are investigating a failed Airflow runtime task that runs before the dbt transformation step.

Your job is to review the failure bundle and decide whether the issue can be fixed safely in a narrow pull request.

Inputs:

- `task_output.txt` -- stdout/stderr from the failed Airflow task
- `diagnostics.json` -- database state: schemas, extensions, tables, MongoDB connectivity

Rules:

- Focus on the specific error in `task_output.txt`.
- Cross-reference with `diagnostics.json` to check what is present and what is missing.
- Common fixable issues: wrong table DDL in init scripts, Python import error, MongoDB connection string mismatch, missing schema or table.
- Prefer small fixes in `scripts/` files only.
- Do not change infrastructure (Terraform), dbt models, or Docker configuration.
- If the root cause is a missing schema or extension that should be managed by Terraform, classify this as an infra issue and do not propose a script fix.
- If the source database is unreachable, do not propose a code fix.
- Do not change more than the minimum set of files needed to fix the failure.
- If the root cause is ambiguous, stop and explain what is missing.

Expected output:

1. Short root cause summary
2. Lane classification: is this truly a runtime issue, or should it be routed to the infra or dbt lane?
3. Why the proposed fix is safe or why no safe fix exists
4. The exact files to change
5. A draft PR title and summary
