-- Phase 1: Foundation Architecture & RBAC
-- Creates the core platform objects and access control for AI workloads

-- Step 1: Create the compute warehouse
CREATE WAREHOUSE IF NOT EXISTS AI_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'AI workload warehouse';

-- Step 2: Create the database and schema
CREATE DATABASE IF NOT EXISTS ENTERPRISE_DB
    COMMENT = 'Enterprise AI platform database';

CREATE SCHEMA IF NOT EXISTS ENTERPRISE_DB.AI_SCHEMA
    COMMENT = 'AI workloads schema';

-- Step 3: Create the custom role
CREATE ROLE IF NOT EXISTS AI_ENGINEER_ROLE
    COMMENT = 'Role for AI engineers with Cortex access';

-- Step 4: Grant access to warehouse, database and schema
GRANT USAGE ON WAREHOUSE AI_WH TO ROLE AI_ENGINEER_ROLE;
GRANT USAGE ON DATABASE ENTERPRISE_DB TO ROLE AI_ENGINEER_ROLE;
GRANT USAGE ON SCHEMA ENTERPRISE_DB.AI_SCHEMA TO ROLE AI_ENGINEER_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA ENTERPRISE_DB.AI_SCHEMA TO ROLE AI_ENGINEER_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA ENTERPRISE_DB.AI_SCHEMA TO ROLE AI_ENGINEER_ROLE;

-- Step 5: Grant Cortex AI function access
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AI_ENGINEER_ROLE;

-- Step 6: Assign the role to your user
GRANT ROLE AI_ENGINEER_ROLE TO USER Dimitar;
