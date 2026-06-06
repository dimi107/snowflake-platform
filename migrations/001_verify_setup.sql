-- Migration 001: verify Phase 1 setup is intact
-- This runs automatically via GitHub Actions on every push to master

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE AI_WH;
USE DATABASE ENTERPRISE_DB;
USE SCHEMA AI_SCHEMA;

SELECT
    CURRENT_USER()      AS deployed_by,
    CURRENT_TIMESTAMP() AS deployed_at,
    CURRENT_WAREHOUSE() AS warehouse,
    CURRENT_DATABASE()  AS database,
    CURRENT_SCHEMA()    AS schema
