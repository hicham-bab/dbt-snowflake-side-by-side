# Replicate this demo (about 90 minutes, once)

You need: a Snowflake account where you can use ACCOUNTADMIN (a trial works), a dbt platform account where you can create projects, and a GitHub account.

## 1. Fork the repo

Fork `dbt-snowflake-side-by-side` into your GitHub org. Everywhere you see `<YOUR_GITHUB_ORG>` or `<DEMO_USER>` in `snowflake/setup/` and `dbt_platform/setup/`, replace it.

## Before you start: two gotchas

- **Unique project names.** If your dbt platform account already has a project called `atlas_platform` (from another demo), rename these projects (`name:` in `dbt_project.yml`, plus `dependencies.yml` and the `ref('atlas_platform', ...)` calls in finance). dbt State and Mesh key on the project name, and a duplicate will defer to or clone from the wrong project.
- **Existing roles or warehouse.** The Snowflake-side profiles read `DBT_ROLE` and `DBT_WAREHOUSE` env vars (defaults `ATLAS_SNOW_*_ROLE`, `ATLAS_WH`). Set them in `env.yml` if you reuse what you already have.

## 2. Shared raw data (both sides, 5 min)

Run `setup/00_shared_raw.sql` in a Snowsight worksheet. It creates warehouse `ATLAS_WH` (XS) and `ATLAS_RAW.ECOMMERCE` with about 300K orders, 900K order lines, 12K customers (about 15 seconds).

## 3. dbt Projects on Snowflake side (45 min)

1. Run, in order: `snowflake/setup/01_env.sql`, `02_git_integration.sql` (fill in your GitHub org and a PAT), `03_external_access.sql`, `04_ci_cd_oidc.sql` (the `GRANT MONITOR` lines fail until step 4 below; re-run them then).
2. GitHub, in your fork: Settings > Environments > New environment `prod`. Add secret `SNOWFLAKE_ACCOUNT` (account identifier, e.g. `orgname-accountname`), variables `SNOWFLAKE_DATABASE=ATLAS_SNOW_PROD` and `SNOWFLAKE_SCHEMA=DBT_OBJECTS`. Add branch protection on `main` (require PR).
3. Snowsight > Projects > Workspaces > Create from Git repository: your fork, `ATLAS_GIT_API_INTEGRATION`, your PAT secret. Open `snowflake/atlas_platform`, run `deps` then `build` with environment `dev`.
4. First prod deploy: Actions > `Snowflake | Deploy to prod` > Run workflow. It deploys `ATLAS_SNOW_PROD.DBT_OBJECTS.ATLAS_PLATFORM` and `ATLAS_FINANCE` and builds both. Then re-run the `GRANT MONITOR` lines from `04_ci_cd_oidc.sql`.
5. Optional: `snowflake/setup/05_tasks.sql` for a daily schedule (suspend the tasks after the demo).

## 4. dbt platform side (30 min)

1. Run `dbt_platform/setup/01_snowflake_for_dbt_platform.sql` (generate a key pair for the service user first).
2. Create project **atlas_platform**: connect your fork with the GitHub app, set **project subdirectory** to `dbt_platform/atlas_platform`. Snowflake connection with warehouse `ATLAS_WH`.
3. Environments:
   - Development: your user, role `ATLAS_DBTP_DEV_ROLE`, database `ATLAS_DBTP_DEV`.
   - CI: service user, role `ATLAS_DBTP_JOB_ROLE`, database `ATLAS_DBTP_CI`.
   - Production (deployment type Production): service user, role `ATLAS_DBTP_JOB_ROLE`, database `ATLAS_DBTP_PROD`, schema `prod`.
4. Jobs:
   - `Prod - atlas_platform`: Production env, `dbt build`, run once now.
   - `CI - atlas_platform`: CI env, trigger "Run on pull requests", command `dbt build --select state:modified+`, enable SQL linting and dbt compare, defer to Production.
5. Repeat 2 to 4 for **atlas_finance** (subdirectory `dbt_platform/atlas_finance`). Its prod job: trigger "run when another job finishes" on `Prod - atlas_platform`. Run it once; Mesh needs the producer's prod run first.
6. Set the source database env var if you renamed `ATLAS_RAW`: `ATLAS_RAW_DATABASE` (both projects, both sides).

## 5. Check both sides

- `select count(*) from ATLAS_SNOW_PROD.PROD_MARTS_FINANCE.FCT_REVENUE_DAILY;` and the same in `ATLAS_DBTP_PROD.PROD_MARTS_FINANCE` return the same number.
- Catalog in dbt platform shows `atlas_finance` models downstream of `fct_orders`.

## 6. Pre-stage the demo PRs (10 min, before each demo)

The branches already exist in the repo. Open one PR per branch against `main` and let checks finish:

| Branch | Expected result |
|---|---|
| `demo/same-pr-snowflake` | Both Slim CI checks green |
| `demo/same-pr-dbt-platform` | dbt platform CI green, compare shows the new column |
| `demo/breaking-change-snowflake` | Both Slim CI checks green (that's the point). Then **merge it**: `Snowflake | Deploy to prod` fails on `atlas_finance` |
| `demo/breaking-change-dbt-platform` | dbt platform CI red: contract error on `fct_orders` |
| `demo/versioned-change-dbt-platform` | dbt platform CI green, finance stays on v1 |

Don't merge the dbt platform PRs. After the demo, revert the Snowflake merge (`git revert`) and re-run the deploy workflow so prod is green for the next presenter.

## Teardown

```sql
DROP DATABASE IF EXISTS ATLAS_SNOW_DEV; DROP DATABASE IF EXISTS ATLAS_SNOW_PROD; DROP DATABASE IF EXISTS ATLAS_SNOW_ADMIN;
DROP DATABASE IF EXISTS ATLAS_DBTP_DEV; DROP DATABASE IF EXISTS ATLAS_DBTP_CI; DROP DATABASE IF EXISTS ATLAS_DBTP_PROD;
DROP DATABASE IF EXISTS ATLAS_RAW;
DROP USER IF EXISTS GITHUB_ACTIONS_ATLAS; DROP USER IF EXISTS ATLAS_DBTP_SERVICE;
DROP INTEGRATION IF EXISTS DBT_EXT_ACCESS; DROP INTEGRATION IF EXISTS ATLAS_GIT_API_INTEGRATION;
```
