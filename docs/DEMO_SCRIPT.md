# Demo script: dbt platform and dbt Projects on Snowflake, side by side (8 minutes)

Same data, same models, same dbt Core v2 engine, same Snowflake warehouse. The only variable is the control plane. That is the whole point: do not let this turn into "Snowflake bad". Snowflake runs the SQL on both sides.

## Before you start (5 minutes, do this before the call)

- Two browser windows side by side: **left = Snowsight**, **right = dbt platform**. Same order every act.
- Tabs open, left: Workspace on `atlas_platform`, GitHub Actions run of the `demo/same-pr-snowflake` PR, the failed `Snowflake | Deploy to prod` run.
- Tabs open, right: Studio on `atlas_platform`, CI run of the `demo/same-pr-dbt-platform` PR, the red PR `demo/breaking-change-dbt-platform`, the green PR `demo/versioned-change-dbt-platform`, Catalog page for `fct_orders`.
- Terminal at the repo root with `./scripts/setup_weight.sh` ready.
- Nothing runs live. Every run is pre-staged (see `REPLICATE.md`, step 6). Re-trigger live only if you have spare time.
- Fallback screenshots for every beat live in `docs/img/`.

## 0:00 to 0:45. Framing

> "Both sides here run the same dbt project on the same Snowflake account. dbt Projects on Snowflake is a real, supported way to run dbt, and for one team in one repo it can be enough. The question we are answering is different: when you have several teams, CI, production SLAs, and models shared between domains, who owns the control plane, and how much of it do you build yourself?"

Show the repo tree for 5 seconds: `snowflake/` and `dbt_platform/` hold the same two projects (`atlas_platform` producer, `atlas_finance` consumer).

## 0:45 to 2:15. Act 1: Setup weight (parity vs turnkey)

**Left (terminal):** `./scripts/setup_weight.sh`

> "To get dev, prod, Slim CI and scheduling for two projects on Snowflake we wrote about 300 lines across 12 files: roles, a Git integration, an external access integration so `dbt deps` works, an OIDC service user, a task graph, three GitHub Actions workflows. Every line came from Snowflake's own tutorials. Snowflake's tutorial even grants ACCOUNTADMIN to the CI user; we scoped it down. That's a decision your team now owns."

Scroll `.github/workflows/snow_pr_slim_ci.yml` for 10 seconds. Point at `SYSTEM$DBT_GET_LAST_SUCCESSFUL_RUN_TARGET`.

> "To be fair: Slim CI with state and defer works on Snowflake today. It's parity. It's not turnkey."

**Right (dbt platform):** Orchestration > Jobs > `CI - atlas_platform` > Settings.

> "Same outcome here: one CI job, triggered on pull request, `dbt build --select state:modified+`, lint and dbt compare are checkboxes. The only Snowflake setup on this side is one 30-line file: a role, a service user, databases."

**So what:** technical, no pipeline code to own; business, adding project number 3, 10 or 50 doesn't mean copying workflows and extending grants.

## 2:15 to 4:15. Act 2: Same PR, two CIs

Both PRs make the same change: a new column `is_high_value_order` on `fct_orders`.

**Left:** GitHub > PR `demo/same-pr-snowflake` > Checks > `Slim CI: atlas_platform`.

> "It works: PR database created, throwaway dbt project object deployed, modified models built with defer. What do I get as a reviewer? A log. Did row counts change? Which columns? Open the log and read."

**Right:** PR `demo/same-pr-dbt-platform` > dbt platform check > run page.

> "Same change. Run steps, lineage of what was built, and dbt compare: rows added, removed, changed, and the new column, compared against production. The reviewer sees the impact before merging."

Click the compare tab, then the contract change in the diff.

> "Notice the contract: adding a column to a public model forced the author to declare it in YAML. Intent is explicit."

**So what:** technical, impact review without custom tooling; business, faster, safer merges and no second control plane in GitHub.

## 4:15 to 5:30. Act 3: Guardrails

**Left:** Workspace `atlas_platform`, open `fct_orders.sql`. Show the environment picker (from `env.yml`): `dev`, `staging`, `prod`.

> "I'm a team lead, so my role has prod grants. I pick `prod`, hit Run, and my unreviewed change is in production. No PR, no CI. Git itself is optional here: a workspace or a dbt project object can exist without a repository. On this side the guardrail is RBAC discipline, maintained by hand, per project."

Do not actually run it into prod. Hover, explain, move on.

**Right:** Studio, on `main`, edit `fct_orders.sql`.

> "Same person, same permissions. Studio won't let me commit to main; it asks for a branch. My runs go to my dev schema, because this IDE is bound to the Development environment. There is no prod option to pick. Everyone, whatever their access, goes dev, PR, CI, merge."

**So what:** technical, the safe path is the only path; business, fewer production incidents, and less-technical contributors can be onboarded safely.

## 5:30 to 7:30. Act 4: Mesh breaking change

Setup line: the platform team renames `order_level_discount` to `discount_amount` in `fct_orders`, a cleanup. Finance reads `order_level_discount` to compute `total_discounts`.

**Left:** open `snowflake/atlas_finance/models/_platform__sources.yml`.

> "No cross-project refs on Snowflake, so finance re-declared the platform's tables as plain sources. The platform team has no record that finance exists."

Show PR `demo/breaking-change-snowflake`: both Slim CI checks green.

> "Platform CI is green: it only selects what changed in its own project. Finance CI is green: nothing changed in finance."

Show the `Snowflake | Deploy to prod` run after merge: `atlas_platform` succeeded (110 of 110), `atlas_finance` failed in `fct_revenue_daily` with `invalid identifier 'ORDER_LEVEL_DISCOUNT'`.

> "You find out in production, from the consumer, after the producer shipped. Or worse: if finance had used `select *`, nothing fails and the numbers just go wrong."

**Right:** Catalog > `fct_orders`: owner `core_platform`, access public, contract enforced, downstream `atlas_finance` models in lineage.

PR `demo/breaking-change-dbt-platform`: red.

> "Same rename. The producer's own CI fails: the contract says `order_level_discount` is a guaranteed column. The breaking change never reaches finance."

PR `demo/versioned-change-dbt-platform`: green.

> "The right way: ship `v2` with the new name, keep `v1` with a deprecation date. Finance stays on `v1`, untouched, and migrates on its own timeline. The platform team can see exactly who still uses `v1`, and every model that still references it gets a deprecation warning at build time."

Point at the `UpcomingReferenceDeprecation` warning in the CI log.

**So what:** technical, cross-project refs, contracts, versions, lineage across projects; business, domains move independently without breaking each other, one trusted source of truth.

## 7:30 to 8:00. Close

> "Snowflake runs the warehouse either way. The decision is the control plane: support from the team that builds dbt, dbt's roadmap and governance features as they ship, and none of these 300 lines to maintain."

Leave them with three questions:

1. How many dbt projects and teams will you have in 18 months, and do they share models?
2. Who on your team owns the CI scripts, grants and task graphs, and what happens when they leave?
3. When a producer changes a model, how does a consumer find out today?

## Extended cut (optional, +2 minutes)

AI context: see `EXTENDED_AI_CUT.md`.

## If something breaks live

| Problem | Do this |
|---|---|
| Snowsight slow or logged out | Use `docs/img/` screenshots, keep talking |
| GitHub Actions run expired | Re-run the job from the Actions tab before the call; logs are kept 90 days by default |
| Someone asks "but Snowflake supports dbt 2.0 / state now" | Agree. "Yes, and this demo uses it. Parity on the engine, the gap is the control plane." |
| Someone asks about cost | Same warehouse both sides; dbt platform adds state-aware orchestration, outside this 8-minute cut |
