-- =========================================================
-- PuzzlePop Marketing Analytics
-- 06 - Reusable Tableau Views
-- =========================================================
--
-- Purpose:
-- Create the governed SQL semantic layer used by Tableau.
--
-- Design principle:
-- Aggregate fact tables to compatible business grains before
-- joining them, preventing spend, install, and revenue
-- multiplication.
--
-- All project data is synthetic.
-- =========================================================

USE puzzlepop_marketing;


-- =========================================================
-- 1. CHANNEL PERFORMANCE
-- Grain: one row per Paid acquisition channel
-- =========================================================

CREATE OR REPLACE VIEW vw_tableau_channel_performance AS

WITH channel_delivery AS (

    SELECT
        channel,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks

    FROM analytics_ad_delivery

    GROUP BY
        channel
),

channel_users AS (

    SELECT
        i.channel,

        COUNT(*) AS paid_installs,

        SUM(p.retained_d7 = 1)
            AS d7_retained_users,

        SUM(p.retained_d30 = 1)
            AS d30_retained_users,

        SUM(p.is_payer = 1)
            AS payer_users,

        SUM(p.total_revenue)
            AS total_revenue

    FROM analytics_installs AS i

    INNER JOIN analytics_user_performance AS p
        ON i.appsflyer_id = p.appsflyer_id

    WHERE
        i.acquisition_type = 'Paid'

    GROUP BY
        i.channel
)

SELECT
    d.channel,
    d.total_spend,
    d.total_impressions,
    d.total_clicks,

    100.0 * d.total_clicks
        / NULLIF(d.total_impressions, 0)
        AS ctr_pct,

    1000.0 * d.total_spend
        / NULLIF(d.total_impressions, 0)
        AS cpm,

    u.paid_installs,

    d.total_spend
        / NULLIF(u.paid_installs, 0)
        AS cpi,

    100.0 * u.d7_retained_users
        / NULLIF(u.paid_installs, 0)
        AS d7_retention_pct,

    100.0 * u.d30_retained_users
        / NULLIF(u.paid_installs, 0)
        AS d30_retention_pct,

    100.0 * u.payer_users
        / NULLIF(u.paid_installs, 0)
        AS payer_rate_pct,

    u.total_revenue,

    u.total_revenue
        / NULLIF(u.paid_installs, 0)
        AS arpu,

    100.0 * u.total_revenue
        / NULLIF(d.total_spend, 0)
        AS roas_pct,

    u.total_revenue
        - d.total_spend
        AS revenue_gap

FROM channel_delivery AS d

INNER JOIN channel_users AS u
    ON d.channel = u.channel;


-- =========================================================
-- 2. CAMPAIGN + CREATIVE PERFORMANCE
-- Grain: one row per creative
-- =========================================================

CREATE OR REPLACE VIEW vw_tableau_campaign_creative_performance AS

WITH creative_delivery AS (

    SELECT
        channel,
        campaign_id,
        campaign_name,
        strategy_code,
        strategy_name,
        creative_id,
        creative_name,
        creative_type,
        creative_concept,

        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks

    FROM analytics_ad_delivery

    GROUP BY
        channel,
        campaign_id,
        campaign_name,
        strategy_code,
        strategy_name,
        creative_id,
        creative_name,
        creative_type,
        creative_concept
),

creative_user_value AS (

    SELECT
        i.channel,
        i.campaign_id,
        i.campaign_name,
        i.creative_id,
        i.creative_name,
        i.creative_type,
        i.creative_concept,

        COUNT(*) AS paid_installs,

        SUM(p.retained_d7 = 1)
            AS d7_retained_users,

        SUM(p.retained_d30 = 1)
            AS d30_retained_users,

        SUM(p.is_payer = 1)
            AS payer_users,

        SUM(p.total_revenue)
            AS total_revenue

    FROM analytics_installs AS i

    INNER JOIN analytics_user_performance AS p
        ON i.appsflyer_id = p.appsflyer_id

    WHERE
        i.acquisition_type = 'Paid'

    GROUP BY
        i.channel,
        i.campaign_id,
        i.campaign_name,
        i.creative_id,
        i.creative_name,
        i.creative_type,
        i.creative_concept
)

SELECT
    d.channel,
    d.campaign_id,
    d.campaign_name,
    d.strategy_code,
    d.strategy_name,
    d.creative_id,
    d.creative_name,
    d.creative_type,
    d.creative_concept,

    d.total_spend,
    d.total_impressions,
    d.total_clicks,

    100.0 * d.total_clicks
        / NULLIF(d.total_impressions, 0)
        AS ctr_pct,

    1000.0 * d.total_spend
        / NULLIF(d.total_impressions, 0)
        AS cpm,

    u.paid_installs,

    d.total_spend
        / NULLIF(u.paid_installs, 0)
        AS cpi,

    100.0 * u.d7_retained_users
        / NULLIF(u.paid_installs, 0)
        AS d7_retention_pct,

    100.0 * u.d30_retained_users
        / NULLIF(u.paid_installs, 0)
        AS d30_retention_pct,

    100.0 * u.payer_users
        / NULLIF(u.paid_installs, 0)
        AS payer_rate_pct,

    u.total_revenue,

    u.total_revenue
        / NULLIF(u.paid_installs, 0)
        AS arpu,

    100.0 * u.total_revenue
        / NULLIF(d.total_spend, 0)
        AS roas_pct,

    u.total_revenue
        - d.total_spend
        AS revenue_gap

FROM creative_delivery AS d

INNER JOIN creative_user_value AS u
    ON d.campaign_id = u.campaign_id
    AND d.creative_id = u.creative_id;


-- =========================================================
-- 3. EXPERIMENT PERFORMANCE
-- Grain: one row per experiment × variant
-- =========================================================

CREATE OR REPLACE VIEW vw_tableau_experiment_performance AS

SELECT
    experiment_id,
    experiment_variant,

    COUNT(*) AS participants,

    SUM(tutorial_completed = 1)
        AS tutorial_completions,

    100.0 * AVG(tutorial_completed)
        AS tutorial_completion_pct,

    100.0 * AVG(retained_d1)
        AS d1_retention_pct,

    100.0 * AVG(retained_d7)
        AS d7_retention_pct,

    100.0 * AVG(retained_d30)
        AS d30_retention_pct,

    100.0 * AVG(is_payer)
        AS payer_rate_pct,

    SUM(total_revenue)
        AS total_revenue,

    AVG(total_revenue)
        AS revenue_per_participant

FROM analytics_experiment

GROUP BY
    experiment_id,
    experiment_variant;