-- =============================================================================
-- 03_external_access.sql  (dbt Projects on Snowflake side)
-- dbt deps needs to reach hub.getdbt.com and GitHub. Without this, any project
-- with packages.yml (here: dbt_utils) cannot install packages. Run as ACCOUNTADMIN.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE SCHEMA ATLAS_SNOW_ADMIN.INTEGRATIONS;

CREATE OR REPLACE NETWORK RULE DBT_DEPS_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION DBT_EXT_ACCESS
  ALLOWED_NETWORK_RULES = (DBT_DEPS_NETWORK_RULE)
  ENABLED = TRUE;

GRANT USAGE ON INTEGRATION DBT_EXT_ACCESS TO ROLE ATLAS_SNOW_DEV_ROLE;
GRANT USAGE ON INTEGRATION DBT_EXT_ACCESS TO ROLE ATLAS_SNOW_PROD_ROLE;
