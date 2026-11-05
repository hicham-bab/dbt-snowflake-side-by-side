# dbt platform vs dbt Projects on Snowflake: side-by-side demo

An 8-minute, replicable demo that runs **the same dbt project, on the same Snowflake account, with the same dbt engine** two ways: on dbt Projects on Snowflake and on the dbt platform. The only variable is the control plane.

Built for field teams (SAs, partner SAs, SIs) who get asked "why not just use dbt Projects on Snowflake?". The Snowflake CI pieces are adapted from [rachaelgfriedman/snow_dbt_projects_demo](https://github.com/rachaelgfriedman/snow_dbt_projects_demo) and Snowflake's own tutorials.

## The 8 minutes

| Time | Beat | The point |
|---|---|---|
| 0:00 | Framing | Snowflake runs the SQL either way. The question is who owns the control plane. |
| 0:45 | 1. Setup weight | ~300 lines across 12 files to own on Snowflake vs one 30-line SQL file and a few clicks. Parity, not turnkey. |
| 2:15 | 2. Same PR, two CIs | GitHub Actions log vs a run page with lineage and dbt compare. |
| 4:15 | 3. Guardrails | A prod picker in the workspace vs an IDE bound to dev, branch required. |
| 5:30 | 4. Mesh breaking change | Rename a column: Snowflake finance breaks in prod; dbt platform contract catches it in producer CI, versions keep finance green. |
| 7:30 | Close | Support model, roadmap, three discovery questions. |

Full talk track: [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md). Optional AI beat: [`docs/EXTENDED_AI_CUT.md`](docs/EXTENDED_AI_CUT.md).

## Repo layout

```
setup/00_shared_raw.sql        raw data both sides read (not counted in setup weight)
snowflake/                     dbt Projects on Snowflake
  setup/01..05_*.sql           roles, Git integration, external access, OIDC CI user, tasks
  atlas_platform/              producer
  atlas_finance/               consumer: producer tables re-declared as sources
dbt_platform/
  setup/01_*.sql               the only Snowflake setup this side needs
  atlas_platform/              producer: group, owner, public access, enforced contract
  atlas_finance/               consumer: dependencies.yml + cross-project ref
.github/workflows/snow_*.yml   Snowflake-side CI/CD (dbt platform needs none)
scripts/setup_weight.sh        Act 1, live
docs/                          script, replication guide, fairness notes
```

## Get started

1. [`docs/REPLICATE.md`](docs/REPLICATE.md): set up both sides once (~90 min).
2. [`docs/FAIRNESS.md`](docs/FAIRNESS.md): read it before presenting. What Snowflake does well, and the source for every claim.
3. Rehearse with the script. Pre-stage the demo branches.
4. After you present, [open a field-feedback issue](../../issues/new?template=field_feedback.md): what landed, what didn't.

## Demo branches

| Branch | Shows |
|---|---|
| `demo/same-pr-snowflake`, `demo/same-pr-dbt-platform` | Act 2: add `is_high_value_order` to `fct_orders` |
| `demo/breaking-change-snowflake` | Act 4: rename `order_level_discount`, CI green, finance fails after merge |
| `demo/breaking-change-dbt-platform` | Act 4: same rename, producer CI fails on the contract |
| `demo/versioned-change-dbt-platform` | Act 4: the rename shipped as `fct_orders` v2, finance stays on v1 |

## Conventions

Code is dbt Core v2 conformant: no `config-version`, `cast()` only, `arguments:` on tests, `require-dbt-version: [">=1.9.0"]`. Both sides pin dbt 2.0.0.
