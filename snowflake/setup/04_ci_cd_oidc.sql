-- =============================================================================
-- 04_ci_cd_oidc.sql  (dbt Projects on Snowflake side)
-- Service user for GitHub Actions (OIDC, no long-lived secret), a CI role that
-- can clone prod per PR, and the grants Slim CI needs to read prod state.
-- Snowflake's tutorial grants ACCOUNTADMIN to this user; we scope it down,
-- which is exactly the kind of decision your team now owns. Run as ACCOUNTADMIN.
-- Based on: docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-ci-cd-tutorial
--           docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-dbt-state-integration
-- =============================================================================

USE ROLE SECURITYADMIN;
CREATE ROLE IF NOT EXISTS ATLAS_SNOW_CI_ROLE COMMENT = 'GitHub Actions: PR clones + Slim CI + prod deploy';
GRANT ROLE ATLAS_SNOW_CI_ROLE TO ROLE SYSADMIN;
GRANT ROLE ATLAS_SNOW_PROD_ROLE TO ROLE ATLAS_SNOW_CI_ROLE;   -- merge-to-main deploys to prod

USE ROLE ACCOUNTADMIN;
CREATE USER IF NOT EXISTS GITHUB_ACTIONS_ATLAS
  TYPE = SERVICE
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://token.actions.githubusercontent.com'
    SUBJECT = 'repo:<YOUR_GITHUB_ORG>/dbt-platform-vs-snowflake-dbt-projects:environment:prod'
  )
  DEFAULT_ROLE = ATLAS_SNOW_CI_ROLE
  DEFAULT_WAREHOUSE = ATLAS_WH
  COMMENT = 'Service user for GitHub Actions (OIDC)';
GRANT ROLE ATLAS_SNOW_CI_ROLE TO USER GITHUB_ACTIONS_ATLAS;

-- Per-PR databases are zero-copy clones of prod: the CI role must create databases
GRANT CREATE DATABASE ON ACCOUNT TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT USAGE ON WAREHOUSE ATLAS_WH TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT USAGE ON INTEGRATION DBT_EXT_ACCESS TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT USAGE ON DATABASE ATLAS_RAW TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT USAGE ON SCHEMA ATLAS_RAW.ECOMMERCE TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA ATLAS_RAW.ECOMMERCE TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ATLAS_RAW.ECOMMERCE TO ROLE ATLAS_SNOW_CI_ROLE;

-- Slim CI reads the last successful prod run (manifest) of each dbt project object.
-- Run these AFTER the first merge-to-main deploy has created the objects.
GRANT MONITOR ON DBT PROJECT ATLAS_SNOW_PROD.DBT_OBJECTS.ATLAS_PLATFORM TO ROLE ATLAS_SNOW_CI_ROLE;
GRANT MONITOR ON DBT PROJECT ATLAS_SNOW_PROD.DBT_OBJECTS.ATLAS_PLATFORM TO ROLE ATLAS_SNOW_DEV_ROLE;
GRANT MONITOR ON DBT PROJECT ATLAS_SNOW_PROD.DBT_OBJECTS.ATLAS_FINANCE  TO ROLE ATLAS_SNOW_DEV_ROLE;

-- Optional: lock the service user to GitHub Actions IP ranges
CREATE NETWORK POLICY IF NOT EXISTS GITHUB_ACTIONS_POLICY
  ALLOWED_NETWORK_RULE_LIST = ('SNOWFLAKE.NETWORK_SECURITY.GITHUBACTIONS_GLOBAL');
ALTER USER GITHUB_ACTIONS_ATLAS SET NETWORK_POLICY = GITHUB_ACTIONS_POLICY;

-- GitHub side (not SQL, still yours to maintain):
--   repo Settings > Environments > "prod"
--   secret SNOWFLAKE_ACCOUNT, variables SNOWFLAKE_DATABASE=ATLAS_SNOW_PROD, SNOWFLAKE_SCHEMA=DBT_OBJECTS
--   .github/workflows/snow_*.yml (three workflows)
--   branch protection on main (otherwise anyone with write access can push to main)
