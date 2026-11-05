-- =============================================================================
-- 05_tasks.sql  (dbt Projects on Snowflake side)
-- Prod orchestration with Snowflake Tasks. Cross-project ordering (platform
-- before finance) is a hand-built task graph. Run as ATLAS_SNOW_PROD_ROLE.
-- =============================================================================

USE ROLE ATLAS_SNOW_PROD_ROLE;
USE SCHEMA ATLAS_SNOW_PROD.DBT_OBJECTS;

ALTER TASK IF EXISTS ATLAS_FINANCE_DAILY SUSPEND;
ALTER TASK IF EXISTS ATLAS_PLATFORM_DAILY SUSPEND;

CREATE OR ALTER TASK ATLAS_PLATFORM_DAILY
  WAREHOUSE = ATLAS_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  AS
    EXECUTE DBT PROJECT ATLAS_SNOW_PROD.DBT_OBJECTS.ATLAS_PLATFORM ARGS = 'build --target prod';

-- Finance only knows the platform finished, not whether what it reads changed shape
CREATE OR ALTER TASK ATLAS_FINANCE_DAILY
  WAREHOUSE = ATLAS_WH
  AFTER ATLAS_PLATFORM_DAILY
  AS
    EXECUTE DBT PROJECT ATLAS_SNOW_PROD.DBT_OBJECTS.ATLAS_FINANCE ARGS = 'build --target prod';

-- Resume child before root
ALTER TASK ATLAS_FINANCE_DAILY RESUME;
ALTER TASK ATLAS_PLATFORM_DAILY RESUME;
