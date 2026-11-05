-- =============================================================================
-- 02_git_integration.sql  (dbt Projects on Snowflake side)
-- Connect Snowflake to GitHub so Workspaces can clone, commit and push.
-- Each developer creates their own workspace and their own GitHub token;
-- there is no shared project that everyone opens. Run as ACCOUNTADMIN.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS ATLAS_SNOW_ADMIN;
CREATE SCHEMA   IF NOT EXISTS ATLAS_SNOW_ADMIN.INTEGRATIONS;
USE SCHEMA ATLAS_SNOW_ADMIN.INTEGRATIONS;

-- One API integration for the GitHub org (account-level object)
CREATE OR REPLACE API INTEGRATION ATLAS_GIT_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<YOUR_GITHUB_ORG>')
  ALLOWED_AUTHENTICATION_SECRETS = ALL
  ENABLED = TRUE;

GRANT USAGE ON INTEGRATION ATLAS_GIT_API_INTEGRATION TO ROLE ATLAS_SNOW_DEV_ROLE;
GRANT USAGE ON INTEGRATION ATLAS_GIT_API_INTEGRATION TO ROLE ATLAS_SNOW_PROD_ROLE;

-- Per developer: a secret holding their GitHub PAT (repeat for every developer,
-- and rotate when tokens expire). Workspaces can also prompt for OAuth.
CREATE OR REPLACE SECRET ATLAS_SNOW_ADMIN.INTEGRATIONS.GIT_PAT_<DEVELOPER>
  TYPE = password
  USERNAME = '<github_username>'
  PASSWORD = '<github_personal_access_token>';
GRANT USAGE ON DATABASE ATLAS_SNOW_ADMIN TO ROLE ATLAS_SNOW_DEV_ROLE;
GRANT USAGE ON SCHEMA ATLAS_SNOW_ADMIN.INTEGRATIONS TO ROLE ATLAS_SNOW_DEV_ROLE;
GRANT READ ON SECRET ATLAS_SNOW_ADMIN.INTEGRATIONS.GIT_PAT_<DEVELOPER> TO ROLE ATLAS_SNOW_DEV_ROLE;

-- Then, in Snowsight: Projects > Workspaces > From Git repository
--   URL: https://github.com/<YOUR_GITHUB_ORG>/dbt-snowflake-side-by-side
--   API integration: ATLAS_GIT_API_INTEGRATION, secret: GIT_PAT_<DEVELOPER>
-- Note: Git is optional on this side. A workspace or a dbt project object can be
-- created without any repository at all.
