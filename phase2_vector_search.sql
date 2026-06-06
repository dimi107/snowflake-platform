-- Phase 2, Step 3: Vector Search / RAG
-- Blocked on free trial. SQL is correct for any paid account.

USE ROLE AI_ENGINEER_ROLE;
USE WAREHOUSE AI_WH;
USE DATABASE ENTERPRISE_DB;
USE SCHEMA AI_SCHEMA;

-- ─────────────────────────────────────────────
-- Step 1: Create a knowledge base table
-- VECTOR(FLOAT, 768) = a column that holds 768 numbers representing meaning
-- ─────────────────────────────────────────────
CREATE OR REPLACE TABLE SUPPORT_DOCS (
    DOC_ID      INT AUTOINCREMENT PRIMARY KEY,
    TITLE       VARCHAR(200),
    CONTENT     TEXT,
    EMBEDDING   VECTOR(FLOAT, 768)
);

-- ─────────────────────────────────────────────
-- Step 2: Insert documents + generate embeddings in one step
-- EMBED_TEXT converts text → 768 numbers (a "meaning fingerprint")
-- ─────────────────────────────────────────────
INSERT INTO SUPPORT_DOCS (TITLE, CONTENT, EMBEDDING)
SELECT
    TITLE,
    CONTENT,
    SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', CONTENT)
FROM (VALUES
    ('Delivery times',       'Standard delivery takes 3-5 business days. Express shipping takes 1-2 days and costs an additional fee.'),
    ('Return policy',        'You can return any product within 30 days of purchase. Items must be unused and in original packaging.'),
    ('Damaged goods',        'If your item arrived damaged, take a photo and contact support within 48 hours. We will ship a replacement at no cost.'),
    ('Account billing',      'Invoices are issued on the 1st of each month. Payment is due within 14 days. Late payments incur a 2% fee.'),
    ('Product setup',        'Download the setup guide from our portal. Most products are ready to use within 15 minutes of installation.')
) AS docs(TITLE, CONTENT);

-- ─────────────────────────────────────────────
-- Step 3: Search by meaning, not by keyword
-- User asks a question → embed it → find the closest document
-- VECTOR_COSINE_SIMILARITY returns 0 (unrelated) to 1 (identical meaning)
-- ─────────────────────────────────────────────
WITH USER_QUESTION AS (
    SELECT 'My package never arrived and it has been two weeks' AS QUESTION
),
QUESTION_EMBEDDED AS (
    SELECT
        QUESTION,
        SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', QUESTION) AS QUESTION_VECTOR
    FROM USER_QUESTION
)
SELECT
    d.TITLE,
    d.CONTENT,
    VECTOR_COSINE_SIMILARITY(d.EMBEDDING, q.QUESTION_VECTOR) AS SIMILARITY
FROM SUPPORT_DOCS d, QUESTION_EMBEDDED q
ORDER BY SIMILARITY DESC
LIMIT 1;

-- ─────────────────────────────────────────────
-- Step 4: Full RAG — find the doc, pass it to COMPLETE, get a real answer
-- This is what a chatbot does behind the scenes
-- ─────────────────────────────────────────────
WITH USER_QUESTION AS (
    SELECT 'My package never arrived and it has been two weeks' AS QUESTION
),
QUESTION_EMBEDDED AS (
    SELECT
        QUESTION,
        SNOWFLAKE.CORTEX.EMBED_TEXT_768('e5-base-v2', QUESTION) AS QUESTION_VECTOR
    FROM USER_QUESTION
),
BEST_DOC AS (
    SELECT d.CONTENT AS CONTEXT, q.QUESTION
    FROM SUPPORT_DOCS d, QUESTION_EMBEDDED q
    ORDER BY VECTOR_COSINE_SIMILARITY(d.EMBEDDING, q.QUESTION_VECTOR) DESC
    LIMIT 1
)
SELECT
    SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-7b',
        'Answer the customer question using only the context below. Be concise.'
        || '\n\nContext: ' || CONTEXT
        || '\n\nQuestion: ' || QUESTION
    ) AS ANSWER
FROM BEST_DOC;
