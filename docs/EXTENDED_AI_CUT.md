# Extended cut: AI-ready context (+2 minutes)

Run this only if the audience cares about Cortex agents or Snowflake Intelligence. Needs extra setup (below).

## The beat

Ask both agents the same three questions about revenue:

1. "What was revenue last month?"
2. "Where does that number come from?"
3. "Are there any upstream data quality issues I should know about?"

**Snowflake side:** a Cortex agent over a semantic view on `fct_orders`. Question 1 is fine. Question 2 gets one hop: "from FCT_ORDERS, SUM of net revenue". Question 3: the agent has no access to dbt lineage, test results or freshness, so it guesses or says it can't tell. To change that you hand-curate context into each agent.

**dbt side:** an assistant connected to the dbt MCP server (dbt platform). Question 2 gets the full lineage: raw tables, staging, intermediate, `fct_orders`. Question 3 returns real test results and source freshness from the last prod run, per layer.

> "Same warehouse, same tables. The difference is whether the agent sees the dbt project's metadata (lineage, tests, contracts, owners) or just the final table."

## Setup

- Snowflake: create a semantic view on `ATLAS_SNOW_PROD.PROD_MARTS_CORE.FCT_ORDERS` (start from `snowflake_semantic_views/01_revenue_semantic_view.sql` in `hicham-bab/snowflake-summit-demo`, change the table name), then a Cortex agent using it.
- dbt: enable the dbt MCP server on the dbt platform project (remote MCP, service token), then connect Claude, Cursor or VS Code to it.

## Known gap, say it before anyone asks

You can't register the dbt MCP server inside Snowflake Intelligence today: Snowflake requires a confidential OAuth client, and dbt issues public (PKCE) clients plus a header Snowflake can't send. So the dbt side of this beat runs from an MCP client outside Snowflake. Check the current status before presenting.
