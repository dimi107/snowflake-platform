-- Phase 2, Step 2: CORTEX.COMPLETE — custom LLM prompting from SQL
-- Blocked on free trial. SQL is correct for any paid account.

USE ROLE AI_ENGINEER_ROLE;
USE WAREHOUSE AI_WH;
USE DATABASE ENTERPRISE_DB;
USE SCHEMA AI_SCHEMA;

-- ─────────────────────────────────────────────
-- Example 1: Classify feedback into custom categories
-- SENTIMENT gives a score. COMPLETE gives whatever YOU define.
-- ─────────────────────────────────────────────
SELECT
    CUSTOMER_NAME,
    PRODUCT,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-7b',
        'Classify this customer feedback into exactly one category: '
        || 'DELIVERY, PRODUCT_QUALITY, SUPPORT, PRICING, or GENERAL. '
        || 'Reply with the category name only, no explanation.\n\n'
        || 'Feedback: ' || FEEDBACK_TEXT
    ) AS CATEGORY
FROM CUSTOMER_FEEDBACK;

-- ─────────────────────────────────────────────
-- Example 2: Extract the specific issue in one sentence
-- ─────────────────────────────────────────────
SELECT
    CUSTOMER_NAME,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-7b',
        'In one sentence, state the main issue or praise in this customer feedback. '
        || 'Be specific and factual.\n\nFeedback: ' || FEEDBACK_TEXT
    ) AS MAIN_POINT
FROM CUSTOMER_FEEDBACK;

-- ─────────────────────────────────────────────
-- Example 3: Combine SENTIMENT score + COMPLETE classification in one query
-- This is what you put in a view for the business user
-- ─────────────────────────────────────────────
CREATE OR REPLACE VIEW FEEDBACK_ENRICHED_VW AS
SELECT
    FEEDBACK_ID,
    CUSTOMER_NAME,
    PRODUCT,
    SUBMITTED_AT,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) AS SENTIMENT_SCORE,
    CASE
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) >=  0.3 THEN 'Positive'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) <= -0.3 THEN 'Negative'
        ELSE 'Neutral'
    END AS SENTIMENT_LABEL,
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-7b',
        'Classify this customer feedback into exactly one category: '
        || 'DELIVERY, PRODUCT_QUALITY, SUPPORT, PRICING, or GENERAL. '
        || 'Reply with the category name only.\n\nFeedback: ' || FEEDBACK_TEXT
    ) AS CATEGORY
FROM CUSTOMER_FEEDBACK;

-- Business user query — no AI knowledge needed
SELECT * FROM FEEDBACK_ENRICHED_VW
ORDER BY SENTIMENT_SCORE ASC; -- worst first
