---
engine:
  id: copilot
  model: gpt-5
  tools:
    - mcp: terraform
on:
  workflow_run:
    workflows:
      - "Pipeline Integration Test"
      - "Infrastructure Validation"
    types: [completed]
permissions:
  contents: read
  actions: read
safe-outputs:
  create-pull-request:
    title-prefix: "fix: "
    labels: [self-heal]
    draft: true
    expires: 7
---

# Self-Heal Pipeline

A CI workflow just failed. Your job is to classify the failure, analyze the evidence using the right tools, and propose a targeted fix.

## Available tools

You have access to the **Terraform MCP server** (configured in `.github/copilot/mcp.json`). Use it when investigating infrastructure failures to look up provider documentation and validate resource arguments.

## Step 1: Download the failure artifacts

Check which artifacts were uploaded by the failed workflow run:

- `infra-failure-pack` means an infrastructure failure (Terraform)
- `runtime-failure-pack` means a runtime failure (Airflow ingestion or init)
- `dbt-failure-pack` means a transformation failure (dbt models or tests)

Download the artifact that exists. If multiple exist, focus on the earliest failure in the pipeline (infra before runtime before dbt).

## Step 2: Read the matching prompt

Based on which artifact you downloaded:

- Infra: read `.github/prompts/self-heal-infra-failure.prompt.md`
- Runtime: read `.github/prompts/self-heal-airflow-failure.prompt.md`
- dbt: read `.github/prompts/self-heal-dbt-failure.prompt.md`

Follow the rules in that prompt exactly.

## Step 3: Analyze the evidence

Read every file in the downloaded artifact. Cross-reference the error message with the source code in the repository.

For infra failures: check `infra/*.tf` files. **Use the Terraform MCP** to look up provider docs for `postgresql_grant`, `postgresql_schema`, and other resources.
For runtime failures: check `scripts/*.py` and `scripts/*.sql` files. If the error is `permission denied`, the root cause may be in `infra/*.tf` (missing grant). Reclassify to infra lane.
For dbt failures: check `dbt/models/**/*.sql` and `dbt/tests/**/*.sql` files. Use the structured JSON artifacts (`run_results.json`, `manifest.json`) as primary evidence. If `run_results.json` shows `permission denied for schema`, the root cause is in `infra/*.tf`, not in dbt code. Reclassify to infra lane.

## Step 4: Decide and act

If a safe, narrow fix exists:
1. Open a draft pull request with the fix.
2. In the PR description, include the root cause summary and why the fix is safe.

If no safe fix exists:
1. Do not open a pull request.
2. Instead, explain what went wrong and why automated repair is not possible.
