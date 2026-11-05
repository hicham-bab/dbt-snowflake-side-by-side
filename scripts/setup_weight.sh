#!/usr/bin/env bash
# Act 1: count what each side asks your team to write and maintain, beyond the
# dbt models themselves. Run from the repo root: ./scripts/setup_weight.sh
set -euo pipefail
cd "$(dirname "$0")/.."

count() {  # non-blank, non-comment lines
  grep -vE '^\s*(--|#|$)' "$1" | wc -l | tr -d ' '
}

printf "\n%-58s %8s\n" "dbt Projects on Snowflake: files you own" "LOC"
printf "%-58s %8s\n" "----------------------------------------------------------" "--------"
total=0; files=0
for f in snowflake/setup/*.sql .github/workflows/snow_*.yml \
         snowflake/atlas_platform/profiles.yml snowflake/atlas_platform/env.yml \
         snowflake/atlas_finance/profiles.yml snowflake/atlas_finance/env.yml; do
  n=$(count "$f"); total=$((total + n)); files=$((files + 1))
  printf "%-58s %8s\n" "$f" "$n"
done
printf "%-58s %8s\n" "TOTAL ($files files, 2 projects)" "$total"

cat <<'TXT'

  Plus, outside the repo:
    - GitHub environment "prod", secret + 2 variables, branch protection on main
    - one Git secret (PAT) per developer, rotated on expiry
    - MONITOR grants re-run for every new dbt project object
    - every new project or team: copy the workflows, extend the roles

TXT

printf "%-58s %8s\n" "dbt platform: files you own" "LOC"
printf "%-58s %8s\n" "----------------------------------------------------------" "--------"
f=dbt_platform/setup/01_snowflake_for_dbt_platform.sql
printf "%-58s %8s\n" "$f" "$(count $f)"
printf "%-58s %8s\n" "TOTAL (1 file, 2 projects)" "$(count $f)"

cat <<'TXT'

  In the UI, once per project:
    - connect the GitHub repo (GitHub app, one click)
    - environments: Development, CI, Production (pick database + schema)
    - CI job: "Run on pull request", commands: dbt build --select state:modified+
      with lint (SQLFluff) and dbt compare toggles
    - deploy job: schedule, or "run after" the upstream project's job
TXT
echo
