-- Migration 002: DEV warehouse for environment promotion
-- Creates a separate compute resource for DEV so dev workloads
-- don't share the PROD warehouse. Account-level object — runs once.

USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS DEV_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEV environment warehouse — smaller, auto-suspends fast to save credits';

-- DEV engineers use AI_ENGINEER_ROLE, so grant them access to DEV_WH
GRANT USAGE   ON WAREHOUSE DEV_WH TO ROLE AI_ENGINEER_ROLE;
GRANT OPERATE ON WAREHOUSE DEV_WH TO ROLE AI_ENGINEER_ROLE;

SELECT 'DEV_WH created and granted to AI_ENGINEER_ROLE' AS status
