-- Phase 2, Step 6: RBAC for AI outputs
-- Creates CS_ROLE for business users (customer success team)
-- They get the Streamlit app and the view — nothing else

USE ROLE ACCOUNTADMIN;

-- ─────────────────────────────────────────────
-- Step 1: Create the business user role
-- ─────────────────────────────────────────────
CREATE ROLE IF NOT EXISTS CS_ROLE;

-- ─────────────────────────────────────────────
-- Step 2: Grant compute access (needed to run any query)
-- ─────────────────────────────────────────────
GRANT USAGE ON WAREHOUSE AI_WH TO ROLE CS_ROLE;

-- ─────────────────────────────────────────────
-- Step 3: Grant navigation access (database → schema)
-- Without this the role cannot even see inside the database
-- ─────────────────────────────────────────────
GRANT USAGE ON DATABASE ENTERPRISE_DB TO ROLE CS_ROLE;
GRANT USAGE ON SCHEMA ENTERPRISE_DB.AI_SCHEMA TO ROLE CS_ROLE;

-- ─────────────────────────────────────────────
-- Step 4: Grant SELECT on the view only — NOT the raw table
-- Business users see clean processed data, not raw rows
-- ─────────────────────────────────────────────
GRANT SELECT ON VIEW ENTERPRISE_DB.AI_SCHEMA.FEEDBACK_SENTIMENT_VW TO ROLE CS_ROLE;

-- ─────────────────────────────────────────────
-- Step 5: Grant access to the Streamlit app
-- ─────────────────────────────────────────────
GRANT USAGE ON STREAMLIT ENTERPRISE_DB.AI_SCHEMA.FEEDBACK_DASHBOARD TO ROLE CS_ROLE;

-- ─────────────────────────────────────────────
-- Step 6: Verify — what can CS_ROLE actually see?
-- ─────────────────────────────────────────────
SHOW GRANTS TO ROLE CS_ROLE;
