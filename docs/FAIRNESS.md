# Fairness notes

This demo only works if a Snowflake-savvy person in the room can't catch us overstating anything. Everything below comes from Snowflake's public documentation, checked on **2026-11-05**. Re-check before using this with customers; Snowflake ships fast.

## What dbt Projects on Snowflake does well (say this out loud)

- Runs dbt natively in Snowflake: no infrastructure to host, Snowflake-native authentication, Workspaces as an in-browser IDE.
- Supports dbt Core 1.9.4, 1.10.15, 1.11.11, 1.12.3 and dbt 2.0.0 (the dbt Core v2 engine), version selected per project object.
- Supports `seed`, `snapshot`, `deps` (with an external access integration for remote packages).
- Slim CI is possible: `SYSTEM$DBT_GET_LAST_SUCCESSFUL_RUN_TARGET` imports the last successful prod run's artifacts, then `--defer --state ./imports/state --select state:modified+`. Workspaces have a "Defer to Production" option.
- A good starting point for a single team, a single repo, Snowflake only.

## What this demo claims, and the source

| Claim in the script | Source |
|---|---|
| CI/CD is built by you, with Snowflake CLI and a CI runner (GitHub Actions) | Snowflake CI/CD tutorial: docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-ci-cd-tutorial |
| The tutorial's GitHub service user gets ACCOUNTADMIN | Same tutorial, "Create a GitHub service user" step |
| State for Slim CI comes from importing the last prod run | docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-dbt-state-integration |
| Only same-folder project references; workaround is copying the other project into `local_packages/` | docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-dependencies |
| A project can come from a workspace, a Git repo, or a stage: Git is optional | docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake (and `CREATE DBT PROJECT ... FROM '@stage'`) |
| The target can be overridden per execution (`--target` in ARGS); environments come from `env.yml` | Same docs, deploy and workspace pages |
| Model contracts, versions, access modifiers are not covered by Snowflake's docs | Not stated in any Snowflake dbt Projects page we read. They're dbt Core features and parse fine; what's missing is the cross-project consumer side. Phrase it as "no cross-project refs", never "contracts don't work". |

## Things we deliberately did NOT claim

- "Snowflake can't do Slim CI." It can. We use it.
- "Snowflake doesn't support dbt v2 / Fusion." It does (2.0.0).
- "Contracts don't work on Snowflake." Within a single project they parse and enforce. The gap is consumers in other projects.
- "dbt platform roles don't matter." They do. We split dev and job roles on the dbt platform side too (`dbt_platform/setup/01_snowflake_for_dbt_platform.sql`). The difference is the IDE is bound to the Development environment.

## Choices we made that you should know about

- Both sides read one shared raw database (`setup/00_shared_raw.sql`), which isn't counted in setup weight.
- The Snowflake CI uses an empty database per PR plus defer, not a full prod clone (the tutorial clones). Cheaper, and simpler to read.
- We added a PR cleanup workflow the tutorial doesn't have. Without it, PR databases pile up.
- Same dbt version both sides: dbt 2.0.0.
