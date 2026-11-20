-- =========================================================
-- PuzzlePop Marketing Analytics
-- 02 - Load Processed Analytical Data
-- =========================================================
--
-- Purpose:
-- Load the four analysis-ready CSV files produced by the
-- R cleaning pipeline into the MySQL analytical tables.
--
-- IMPORTANT:
-- Replace each /ABSOLUTE/PATH/TO/PuzzlePop placeholder with
-- the local absolute path to this project before execution.
--
-- The source data is entirely synthetic.
--
-- Key ingestion controls:
-- - explicit date/datetime parsing
-- - TRUE/FALSE and 1/0 Boolean conversion
-- - blank/NA attribution values mapped to SQL NULL
-- - explicit six-decimal revenue precision
--
-- Prerequisite:
-- Run 01_schema.sql first.
-- =========================================================

USE puzzlepop_marketing;

-- =========================================================
-- 1. LOAD AD DELIVERY DATA
-- =========================================================

LOAD DATA LOCAL INFILE
'/ABSOLUTE/PATH/TO/PuzzlePop/data/processed/analytics_ad_delivery.csv'
INTO TABLE analytics_ad_delivery
CHARACTER SET utf8mb4
FIELDS
    TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES
(
    raw_row_id,
    @date,
    channel_code,
    channel,
    campaign_id,
    campaign_name,
    strategy_code,
    strategy_name,
    creative_id,
    creative_name,
    creative_type,
    creative_concept,
    country_code,
    country_name,
    platform,
    spend,
    impressions,
    clicks
)
SET
    date = STR_TO_DATE(@date, '%Y-%m-%d');

-- =========================================================
-- 2. LOAD INSTALL / ATTRIBUTION DATA
-- =========================================================

LOAD DATA LOCAL INFILE
'/ABSOLUTE/PATH/TO/PuzzlePop/data/processed/analytics_installs.csv'
INTO TABLE analytics_installs
CHARACTER SET utf8mb4
FIELDS
    TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES
(
    appsflyer_id,
    customer_user_id,
    @install_time_raw,
    @attributed_touch_time_raw,
    @attributed_touch_type_raw,
    acquisition_type,
    @is_organic_raw,
    @is_retargeting_raw,
    channel,
    @campaign_id_raw,
    @campaign_name_raw,
    @creative_id_raw,
    @creative_name_raw,
    @creative_type_raw,
    @creative_concept_raw,
    country_code,
    country_name,
    platform
)
SET
    install_time =
        STR_TO_DATE(
            @install_time_raw,
            '%Y-%m-%dT%H:%i:%sZ'
        ),

    attributed_touch_time =
        CASE
            WHEN TRIM(@attributed_touch_time_raw) IN ('', 'NA')
            THEN NULL
            ELSE STR_TO_DATE(
                @attributed_touch_time_raw,
                '%Y-%m-%dT%H:%i:%sZ'
            )
        END,

    attributed_touch_type =
        CASE
            WHEN TRIM(@attributed_touch_type_raw) IN ('', 'NA')
            THEN NULL
            ELSE TRIM(@attributed_touch_type_raw)
        END,

    is_organic =
        CASE
            WHEN UPPER(TRIM(@is_organic_raw)) = 'TRUE' THEN 1
            WHEN UPPER(TRIM(@is_organic_raw)) = 'FALSE' THEN 0
            ELSE NULL
        END,

    is_retargeting =
        CASE
            WHEN UPPER(TRIM(@is_retargeting_raw)) = 'TRUE' THEN 1
            WHEN UPPER(TRIM(@is_retargeting_raw)) = 'FALSE' THEN 0
            ELSE NULL
        END,

    campaign_id =
        CASE
            WHEN TRIM(@campaign_id_raw) IN ('', 'NA') THEN NULL
            ELSE TRIM(@campaign_id_raw)
        END,

    campaign_name =
        CASE
            WHEN TRIM(@campaign_name_raw) IN ('', 'NA') THEN NULL
            ELSE TRIM(@campaign_name_raw)
        END,

    creative_id =
        CASE
            WHEN TRIM(@creative_id_raw) IN ('', 'NA') THEN NULL
            ELSE TRIM(@creative_id_raw)
        END,

    creative_name =
        CASE
            WHEN TRIM(@creative_name_raw) IN ('', 'NA') THEN NULL
            ELSE TRIM(@creative_name_raw)
        END,

    creative_type =
        CASE
            WHEN TRIM(@creative_type_raw) IN ('', 'NA') THEN NULL
            ELSE TRIM(@creative_type_raw)
        END,

    creative_concept =
        CASE
            WHEN TRIM(@creative_concept_raw) IN ('', 'NA') THEN NULL
            ELSE TRIM(@creative_concept_raw)
        END;
-- =========================================================
-- 3. LOAD USER PERFORMANCE DATA
-- =========================================================
--
-- Boolean source values may appear as either TRUE/FALSE
-- or 1/0. Revenue fields are explicitly converted and
-- rounded to six decimal places to match the final schema.
-- =========================================================

LOAD DATA LOCAL INFILE
'/ABSOLUTE/PATH/TO/PuzzlePop/data/processed/analytics_user_performance.csv'
INTO TABLE analytics_user_performance
CHARACTER SET utf8mb4
FIELDS
    TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES
(
    appsflyer_id,
    customer_user_id,
    sessions_first_7d,
    @retained_d1_raw,
    @retained_d7_raw,
    @retained_d30_raw,
    @is_payer_raw,
    purchase_count,
    iap_revenue,
    ad_impressions,
    @ad_revenue_raw,
    @total_revenue_raw
)
SET
    retained_d1 =
        CASE
            WHEN UPPER(TRIM(@retained_d1_raw)) IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@retained_d1_raw)) IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    retained_d7 =
        CASE
            WHEN UPPER(TRIM(@retained_d7_raw)) IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@retained_d7_raw)) IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    retained_d30 =
        CASE
            WHEN UPPER(TRIM(@retained_d30_raw)) IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@retained_d30_raw)) IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    is_payer =
        CASE
            WHEN UPPER(TRIM(@is_payer_raw)) IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@is_payer_raw)) IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    ad_revenue =
        ROUND(
            CAST(
                TRIM(@ad_revenue_raw)
                AS DECIMAL(30,15)
            ),
            6
        ),

    total_revenue =
        ROUND(
            CAST(
                TRIM(@total_revenue_raw)
                AS DECIMAL(30,15)
            ),
            6
        );

-- =========================================================
-- 4. LOAD EXPERIMENT DATA
-- =========================================================

LOAD DATA LOCAL INFILE
'/ABSOLUTE/PATH/TO/PuzzlePop/data/processed/analytics_experiment.csv'
INTO TABLE analytics_experiment
CHARACTER SET utf8mb4
FIELDS
    TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
LINES
    TERMINATED BY '\n'
IGNORE 1 LINES
(
    customer_user_id,
    experiment_id,
    experiment_variant,
    @tutorial_completed_raw,
    @retained_d1_raw,
    @retained_d7_raw,
    @retained_d30_raw,
    @is_payer_raw,
    @total_revenue_raw
)
SET
    tutorial_completed =
        CASE
            WHEN UPPER(TRIM(@tutorial_completed_raw))
                 IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@tutorial_completed_raw))
                 IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    retained_d1 =
        CASE
            WHEN UPPER(TRIM(@retained_d1_raw))
                 IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@retained_d1_raw))
                 IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    retained_d7 =
        CASE
            WHEN UPPER(TRIM(@retained_d7_raw))
                 IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@retained_d7_raw))
                 IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    retained_d30 =
        CASE
            WHEN UPPER(TRIM(@retained_d30_raw))
                 IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@retained_d30_raw))
                 IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    is_payer =
        CASE
            WHEN UPPER(TRIM(@is_payer_raw))
                 IN ('1', 'TRUE')
            THEN 1
            WHEN UPPER(TRIM(@is_payer_raw))
                 IN ('0', 'FALSE')
            THEN 0
            ELSE NULL
        END,

    total_revenue =
        ROUND(
            CAST(
                TRIM(@total_revenue_raw)
                AS DECIMAL(30,15)
            ),
            6
        );