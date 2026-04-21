You are investigating a failed dbt pipeline run.

Your job is to review the failure bundle and decide whether the issue can be fixed safely in a narrow pull request.

## Why these artifacts exist

dbt produces machine-readable failure artifacts by design. Unlike raw log files, these are structured JSON documents meant for programmatic analysis. Use them as your primary evidence, not as supplementary data.

## Inputs

- `run_results.json` -- structured results for every dbt node: status, timing, error message, and the exact SQL that failed. Start here.
- `manifest.json` -- the full dependency graph. Use it to trace upstream dependencies of the failed node and check whether the root cause is in a parent model.
- `sources.json` -- source freshness results. Check whether the failure correlates with stale or missing source data.
- `compiled/` -- the exact SQL that dbt sent to the database. Read the compiled SQL for the failed node to see the full query with all refs and macros resolved.

## Diagnosis steps

1. Parse `run_results.json`. Find the first node with `status: "error"`. Read its `message` field.
2. Read the compiled SQL for that node from `compiled/`. This is the exact query the database rejected.
3. Check `manifest.json` for upstream dependencies. If a parent model also failed, the root cause is likely upstream.
4. Check `sources.json` for freshness. If the source is stale or errored, the fix may not be in dbt code.

## Rules

- Focus on the first failed dbt node unless the bundle clearly shows a shared root cause.
- Prefer small fixes in `dbt/models` and `dbt/tests`.
- Do not change infrastructure, credentials, or container setup.
- Do not change more than the minimum set of files needed to fix the failure.
- If the root cause is ambiguous, stop and explain what is missing.
- If the failure looks like an upstream outage or missing source data, do not prepare a code fix.

## Expected output

1. Short root cause summary
2. Which artifacts confirmed the diagnosis (run_results error message, compiled SQL, manifest dependency chain)
3. Why the proposed fix is safe or why no safe fix exists
4. The exact files to change
5. A draft PR title and summary
