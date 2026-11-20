-- =========================================================
-- PuzzlePop Marketing Analytics
-- 03 - Validation & Referential Integrity
-- =========================================================
--
-- Purpose:
-- Validate the analytical tables after ingestion and enforce
-- only the relationships that were confirmed by the data.
--
-- Validation principles:
-- - verify row counts and business grain
-- - verify primary/unique identifiers
-- - verify Paid vs Organic attribution logic
-- - verify retention and monetization outcomes
-- - verify parent-child key coverage before adding FKs
--
-- Relationships:
-- analytics_installs
--     -> analytics_user_performance via appsflyer_id
--
-- analytics_user_performance
--     -> analytics_experiment via customer_user_id
--
-- No row-level FK is created between ad delivery and installs
-- because those datasets operate at different analytical grains.
--
-- Prerequisites:
-- 01_schema.sql
-- 02_load_data.sql
--
-- All project data is synthetic.
-- =========================================================

USE puzzlepop_marketing;
-- =========================================================
-- 1. TABLE GRAIN & UNIQUENESS VALIDATION
-- =========================================================

-- Ad delivery:
-- expected grain = one row per raw_row_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT raw_row_id) AS unique_delivery_rows
FROM analytics_ad_delivery;


-- Installs:
-- expected grain = one row per appsflyer_id / customer_user_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT appsflyer_id) AS unique_appsflyer_ids,
    COUNT(DISTINCT customer_user_id) AS unique_customer_ids
FROM analytics_installs;


-- User performance:
-- expected grain = one row per appsflyer_id / customer_user_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT appsflyer_id) AS unique_appsflyer_ids,
    COUNT(DISTINCT customer_user_id) AS unique_customer_ids
FROM analytics_user_performance;


-- Experiment:
-- expected grain = one row per customer_user_id × experiment_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(
        DISTINCT customer_user_id,
        experiment_id
    ) AS unique_user_experiments
FROM analytics_experiment;
-- =========================================================
-- 2. PAID VS ORGANIC ATTRIBUTION VALIDATION
-- =========================================================
--
-- Organic users are expected to have structural NULL values
-- for Paid campaign/creative attribution.
-- Paid users should retain the required attribution fields.
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(is_organic = 1) AS organic_rows,

    SUM(is_organic = 0) AS paid_rows,

    SUM(is_retargeting = 1) AS retargeting_rows,

    SUM(
        acquisition_type = 'Paid'
        AND campaign_id IS NULL
    ) AS paid_missing_campaign,

    SUM(
        acquisition_type = 'Paid'
        AND creative_id IS NULL
    ) AS paid_missing_creative,

    SUM(
        acquisition_type = 'Organic'
        AND campaign_id IS NULL
    ) AS organic_missing_campaign,

    SUM(
        acquisition_type = 'Organic'
        AND creative_id IS NULL
    ) AS organic_missing_creative,

    SUM(
        acquisition_type = 'Paid'
        AND attributed_touch_time IS NULL
    ) AS paid_missing_touch_time,

    SUM(
        acquisition_type = 'Organic'
        AND attributed_touch_time IS NULL
    ) AS organic_missing_touch_time

FROM analytics_installs;

-- =========================================================
-- 3. RELATIONSHIP COVERAGE VALIDATION
-- =========================================================
--
-- Validate parent-child coverage before enforcing
-- foreign-key constraints.
-- =========================================================


-- ---------------------------------------------------------
-- Relationship 1:
-- analytics_user_performance -> analytics_installs
-- Key: appsflyer_id
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS performance_rows,
    SUM(
        i.appsflyer_id IS NULL
    ) AS performance_rows_without_install
FROM analytics_user_performance AS p
LEFT JOIN analytics_installs AS i
    ON p.appsflyer_id = i.appsflyer_id;


-- ---------------------------------------------------------
-- Relationship 2:
-- analytics_experiment -> analytics_user_performance
-- Key: customer_user_id
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS experiment_rows,
    SUM(
        p.customer_user_id IS NULL
    ) AS experiment_rows_without_user_performance
FROM analytics_experiment AS e
LEFT JOIN analytics_user_performance AS p
    ON e.customer_user_id = p.customer_user_id;

-- =========================================================
-- 4. ENFORCE VALIDATED RELATIONSHIPS
-- =========================================================

-- Relationship 1:
-- User performance must correspond to an existing install.

ALTER TABLE analytics_user_performance
ADD CONSTRAINT fk_performance_install
FOREIGN KEY (appsflyer_id)
REFERENCES analytics_installs (appsflyer_id)
ON UPDATE RESTRICT
ON DELETE RESTRICT;


-- Relationship 2:
-- Experiment participants must correspond to an existing
-- user-performance record.

ALTER TABLE analytics_experiment
ADD CONSTRAINT fk_experiment_user_performance
FOREIGN KEY (customer_user_id)
REFERENCES analytics_user_performance (customer_user_id)
ON UPDATE RESTRICT
ON DELETE RESTRICT;
-- =========================================================
-- 5. VERIFY FOREIGN-KEY CONSTRAINTS
-- =========================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'puzzlepop_marketing'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY
    TABLE_NAME,
    CONSTRAINT_NAME;