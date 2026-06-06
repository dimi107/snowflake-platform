-- Phase 2: Cortex AI Workloads — Sentiment Analysis
-- Uses ENTERPRISE_DB.AI_SCHEMA created in Phase 1

USE WAREHOUSE AI_WH;
USE DATABASE ENTERPRISE_DB;
USE SCHEMA AI_SCHEMA;

-- ─────────────────────────────────────────────
-- Step 1: Create the feedback table
-- ─────────────────────────────────────────────
CREATE OR REPLACE TABLE CUSTOMER_FEEDBACK (
    FEEDBACK_ID     INT AUTOINCREMENT PRIMARY KEY,
    CUSTOMER_NAME   VARCHAR(100),
    PRODUCT         VARCHAR(100),
    FEEDBACK_TEXT   VARCHAR(2000),
    SUBMITTED_AT    DATE
);

-- ─────────────────────────────────────────────
-- Step 2: Insert mock data (mix of positive / neutral / negative)
-- ─────────────────────────────────────────────
INSERT INTO CUSTOMER_FEEDBACK (CUSTOMER_NAME, PRODUCT, FEEDBACK_TEXT, SUBMITTED_AT) VALUES
    ('Anna Müller',    'AI Dashboard',   'Absolutely love the new dashboard. Everything is fast, clear, and intuitive. Best tool we have used in years.',         '2026-05-01'),
    ('Thomas Bauer',   'Data Pipeline',  'The pipeline setup was straightforward and the documentation was helpful. Works exactly as expected.',                    '2026-05-03'),
    ('Sofia Klein',    'AI Dashboard',   'It is okay. Not bad, not great. Some features are missing but it gets the job done.',                                     '2026-05-05'),
    ('Markus Weber',   'Data Pipeline',  'Very disappointing. The pipeline crashed twice during our first week and support took three days to respond.',             '2026-05-07'),
    ('Laura Schmidt',  'Cortex Search',  'The semantic search is impressive. It found relevant documents even when the exact keywords were not present.',            '2026-05-09'),
    ('Jan Fischer',    'Cortex Search',  'Search results are sometimes irrelevant. We expected better accuracy for the price we are paying.',                       '2026-05-11'),
    ('Emma Hoffmann',  'AI Dashboard',   'The onboarding experience was smooth. The team was up and running within a day.',                                         '2026-05-13'),
    ('Lukas Braun',    'Data Pipeline',  'Nothing works as advertised. Constant errors, poor logging, and no clear error messages. Extremely frustrated.',          '2026-05-15'),
    ('Nina Wolf',      'Cortex Search',  'Decent product. Some rough edges but the core functionality is solid.',                                                   '2026-05-17'),
    ('Felix Richter',  'AI Dashboard',   'Outstanding support team. They resolved our issue within hours and followed up the next day to confirm everything worked.','2026-05-19');

-- ─────────────────────────────────────────────
-- Step 3: Verify the data loaded
-- ─────────────────────────────────────────────
SELECT * FROM CUSTOMER_FEEDBACK ORDER BY FEEDBACK_ID;

-- ─────────────────────────────────────────────
-- Step 4: Run Cortex sentiment on every row
-- Score is between -1.0 (very negative) and +1.0 (very positive)
-- ─────────────────────────────────────────────
SELECT
    FEEDBACK_ID,
    CUSTOMER_NAME,
    PRODUCT,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) AS SENTIMENT_SCORE
FROM CUSTOMER_FEEDBACK
ORDER BY SENTIMENT_SCORE DESC;

-- ─────────────────────────────────────────────
-- Step 5: Create a self-service view with sentiment label
-- Engineers and business users query this — no AI knowledge needed
-- ─────────────────────────────────────────────
CREATE OR REPLACE VIEW FEEDBACK_SENTIMENT_VW AS
SELECT
    FEEDBACK_ID,
    CUSTOMER_NAME,
    PRODUCT,
    SUBMITTED_AT,
    FEEDBACK_TEXT,
    SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT)                        AS SENTIMENT_SCORE,
    CASE
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) >= 0.3  THEN 'Positive'
        WHEN SNOWFLAKE.CORTEX.SENTIMENT(FEEDBACK_TEXT) <= -0.3 THEN 'Negative'
        ELSE 'Neutral'
    END                                                              AS SENTIMENT_LABEL
FROM CUSTOMER_FEEDBACK;

-- ─────────────────────────────────────────────
-- Step 6: Query the view — this is what a business user would run
-- ─────────────────────────────────────────────
SELECT * FROM FEEDBACK_SENTIMENT_VW ORDER BY SENTIMENT_SCORE DESC;

-- Bonus: summary by product
SELECT
    PRODUCT,
    COUNT(*)                        AS TOTAL_FEEDBACK,
    ROUND(AVG(SENTIMENT_SCORE), 3)  AS AVG_SENTIMENT,
    SUM(CASE WHEN SENTIMENT_LABEL = 'Positive' THEN 1 ELSE 0 END) AS POSITIVE,
    SUM(CASE WHEN SENTIMENT_LABEL = 'Neutral'  THEN 1 ELSE 0 END) AS NEUTRAL,
    SUM(CASE WHEN SENTIMENT_LABEL = 'Negative' THEN 1 ELSE 0 END) AS NEGATIVE
FROM FEEDBACK_SENTIMENT_VW
GROUP BY PRODUCT
ORDER BY AVG_SENTIMENT DESC;
