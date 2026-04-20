---
engine:
  id: copilot
  model: gpt-5
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

A CI workflow just failed. Your job is to classify the failure, analyze the evidence, and propose a targeted fix.

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

For infra failures: check `infra/*.tf` files.
For runtime failures: check `scripts/*.py` and `scripts/*.sql` files.
For dbt failures: check `dbt/models/**/*.sql` and `dbt/tests/**/*.sql` files.

## Step 4: Decide and act

If a safe, narrow fix exists:
1. Open a draft pull request with the fix.
2. In the PR description, include the root cause summary and why the fix is safe.

If no safe fix exists:
1. Do not open a pull request.
2. Instead, explain what went wrong and why automated repair is not possible.
