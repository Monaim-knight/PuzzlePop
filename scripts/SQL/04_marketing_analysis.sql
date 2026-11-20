-- =========================================================
-- PuzzlePop Marketing Analytics
-- 04 - Marketing Performance Analysis
-- =========================================================
--
-- Purpose:
-- Analyze Paid user-acquisition performance from media
-- delivery through acquisition, retention, monetization,
-- campaign economics, and creative-level diagnostics.
--
-- Decision hierarchy:
-- Channel -> Campaign -> Creative
--
-- Modeling principle:
-- Aggregate fact tables to compatible business grains before
-- joining them to prevent spend or revenue multiplication.
--
-- All project data is synthetic.
-- =========================================================

USE puzzlepop_marketing;

# Channel level Marketing Delivery Baseline 
SELECT
    channel,

    ROUND(
        SUM(spend),
        2
    ) AS total_spend,

    SUM(impressions) AS total_impressions,

    SUM(clicks) AS total_clicks,

    ROUND(
        100.0 * SUM(clicks)
        / NULLIF(SUM(impressions), 0),
        2
    ) AS ctr_pct,

    ROUND(
        1000.0 * SUM(spend)
        / NULLIF(SUM(impressions), 0),
        2
    ) AS cpm,

    ROUND(
        100.0 * SUM(spend)
        / SUM(SUM(spend)) OVER (),
        2
    ) AS spend_share_pct

FROM analytics_ad_delivery

GROUP BY
    channel

ORDER BY
    total_spend DESC;
    
# Channel-level Acquisition Efficiency 
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

channel_installs AS (

    SELECT
        channel,

        COUNT(*) AS paid_installs

    FROM analytics_installs

    WHERE acquisition_type = 'Paid'

    GROUP BY
        channel
)

SELECT
    d.channel,

    ROUND(
        d.total_spend,
        2
    ) AS total_spend,

    i.paid_installs,

    ROUND(
        d.total_spend
        / NULLIF(i.paid_installs, 0),
        2
    ) AS cpi,

    ROUND(
        100.0 * i.paid_installs
        / SUM(i.paid_installs) OVER (),
        2
    ) AS paid_install_share_pct,

    ROUND(
        100.0 * d.total_spend
        / SUM(d.total_spend) OVER (),
        2
    ) AS spend_share_pct

FROM channel_delivery AS d

INNER JOIN channel_installs AS i
    ON d.channel = i.channel

ORDER BY
    cpi ASC;
    
# Channel-Level Acquisition Quality 
WITH channel_spend AS (

    SELECT
        channel,
        SUM(spend) AS total_spend

    FROM analytics_ad_delivery

    GROUP BY
        channel
),

channel_user_quality AS (

    SELECT
        i.channel,

        COUNT(*) AS paid_installs,

        ROUND(
            AVG(p.sessions_first_7d),
            2
        ) AS avg_sessions_first_7d,

        SUM(p.retained_d1 = 1)
            AS d1_retained_users,

        SUM(p.retained_d7 = 1)
            AS d7_retained_users,

        SUM(p.retained_d30 = 1)
            AS d30_retained_users,

        ROUND(
            100.0 * AVG(p.retained_d1),
            2
        ) AS d1_retention_pct,

        ROUND(
            100.0 * AVG(p.retained_d7),
            2
        ) AS d7_retention_pct,

        ROUND(
            100.0 * AVG(p.retained_d30),
            2
        ) AS d30_retention_pct

    FROM analytics_installs AS i

    INNER JOIN analytics_user_performance AS p
        ON i.appsflyer_id = p.appsflyer_id

    WHERE
        i.acquisition_type = 'Paid'

    GROUP BY
        i.channel
)

SELECT
    q.channel,

    q.paid_installs,

    q.avg_sessions_first_7d,

    q.d1_retention_pct,
    q.d7_retention_pct,
    q.d30_retention_pct,

    ROUND(
        s.total_spend
        / NULLIF(q.d7_retained_users, 0),
        2
    ) AS cost_per_d7_retained_user,

    ROUND(
        s.total_spend
        / NULLIF(q.d30_retained_users, 0),
        2
    ) AS cost_per_d30_retained_user

FROM channel_user_quality AS q

INNER JOIN channel_spend AS s
    ON q.channel = s.channel

ORDER BY
    q.d30_retention_pct DESC;


# Channel-Level Monetization 
WITH channel_monetization AS (

    SELECT
        i.channel,

        COUNT(*) AS paid_installs,

        SUM(p.is_payer = 1) AS payer_users,

        SUM(p.iap_revenue) AS iap_revenue,

        SUM(p.ad_revenue) AS ad_revenue,

        SUM(p.total_revenue) AS total_revenue

    FROM analytics_installs AS i

    INNER JOIN analytics_user_performance AS p
        ON i.appsflyer_id = p.appsflyer_id

    WHERE
        i.acquisition_type = 'Paid'

    GROUP BY
        i.channel
)

SELECT
    channel,

    paid_installs,

    payer_users,

    ROUND(
        100.0 * payer_users
        / NULLIF(paid_installs, 0),
        2
    ) AS payer_rate_pct,

    ROUND(
        iap_revenue,
        2
    ) AS iap_revenue,

    ROUND(
        ad_revenue,
        2
    ) AS ad_revenue,

    ROUND(
        total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        total_revenue
        / NULLIF(paid_installs, 0),
        2
    ) AS arpu,

    ROUND(
        iap_revenue
        / NULLIF(payer_users, 0),
        2
    ) AS arppu,

    ROUND(
        100.0 * ad_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS ad_revenue_share_pct

FROM channel_monetization

ORDER BY
    arpu DESC;

# Channel-Level Marketing Economics 
WITH channel_spend AS (

    SELECT
        channel,
        SUM(spend) AS total_spend

    FROM analytics_ad_delivery

    GROUP BY
        channel
),

channel_value AS (

    SELECT
        i.channel,

        COUNT(*) AS paid_installs,

        SUM(p.is_payer = 1) AS payer_users,

        SUM(p.retained_d7 = 1) AS d7_retained_users,

        SUM(p.retained_d30 = 1) AS d30_retained_users,

        SUM(p.total_revenue) AS total_revenue

    FROM analytics_installs AS i

    INNER JOIN analytics_user_performance AS p
        ON i.appsflyer_id = p.appsflyer_id

    WHERE
        i.acquisition_type = 'Paid'

    GROUP BY
        i.channel
)

SELECT
    v.channel,

    ROUND(
        s.total_spend,
        2
    ) AS total_spend,

    v.paid_installs,

    ROUND(
        s.total_spend
        / NULLIF(v.paid_installs, 0),
        2
    ) AS cpi,

    ROUND(
        v.total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        v.total_revenue
        / NULLIF(v.paid_installs, 0),
        2
    ) AS arpu,

    ROUND(
        100.0 * v.total_revenue
        / NULLIF(s.total_spend, 0),
        2
    ) AS roas_pct,

    ROUND(
        v.total_revenue
        - s.total_spend,
        2
    ) AS revenue_gap,

    ROUND(
        s.total_spend
        / NULLIF(v.d7_retained_users, 0),
        2
    ) AS cost_per_d7_retained_user,

    ROUND(
        s.total_spend
        / NULLIF(v.d30_retained_users, 0),
        2
    ) AS cost_per_d30_retained_user

FROM channel_value AS v

INNER JOIN channel_spend AS s
    ON v.channel = s.channel

ORDER BY
    roas_pct DESC;
    
# Campaign-Level Performance Diagnostics 
WITH campaign_spend AS (

    SELECT
        channel,
        campaign_id,
        campaign_name,
        strategy_code,
        strategy_name,

        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks

    FROM analytics_ad_delivery

    GROUP BY
        channel,
        campaign_id,
        campaign_name,
        strategy_code,
        strategy_name
),

campaign_user_value AS (

    SELECT
        i.channel,
        i.campaign_id,
        i.campaign_name,

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
        i.campaign_name
),

campaign_economics AS (

    SELECT
        s.channel,
        s.campaign_id,
        s.campaign_name,
        s.strategy_code,
        s.strategy_name,

        s.total_spend,
        s.total_impressions,
        s.total_clicks,

        v.paid_installs,
        v.d7_retained_users,
        v.d30_retained_users,
        v.payer_users,
        v.total_revenue,

        s.total_spend
        / NULLIF(v.paid_installs, 0)
            AS cpi,

        100.0 * v.d7_retained_users
        / NULLIF(v.paid_installs, 0)
            AS d7_retention_pct,

        100.0 * v.d30_retained_users
        / NULLIF(v.paid_installs, 0)
            AS d30_retention_pct,

        100.0 * v.payer_users
        / NULLIF(v.paid_installs, 0)
            AS payer_rate_pct,

        v.total_revenue
        / NULLIF(v.paid_installs, 0)
            AS arpu,

        100.0 * v.total_revenue
        / NULLIF(s.total_spend, 0)
            AS roas_pct,

        v.total_revenue - s.total_spend
            AS revenue_gap

    FROM campaign_spend AS s

    INNER JOIN campaign_user_value AS v
        ON s.campaign_id = v.campaign_id
)

SELECT
    channel,
    campaign_id,
    campaign_name,
    strategy_name,

    ROUND(
        total_spend,
        2
    ) AS total_spend,

    paid_installs,

    ROUND(
        cpi,
        2
    ) AS cpi,

    ROUND(
        d7_retention_pct,
        2
    ) AS d7_retention_pct,

    ROUND(
        d30_retention_pct,
        2
    ) AS d30_retention_pct,

    payer_users,

    ROUND(
        payer_rate_pct,
        2
    ) AS payer_rate_pct,

    ROUND(
        total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        arpu,
        2
    ) AS arpu,

    ROUND(
        roas_pct,
        2
    ) AS roas_pct,

    ROUND(
        revenue_gap,
        2
    ) AS revenue_gap,

    DENSE_RANK() OVER (
        PARTITION BY channel
        ORDER BY roas_pct DESC
    ) AS roas_rank_within_channel

FROM campaign_economics

ORDER BY
    channel,
    roas_rank_within_channel,
    campaign_id;

# Integrated Creative Diagnostic 
WITH creative_delivery AS (

    SELECT
        channel,
        campaign_id,
        campaign_name,
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
        SUM(p.retained_d7 = 1) AS d7_retained_users,
        SUM(p.is_payer = 1) AS payer_users,
        SUM(p.total_revenue) AS total_revenue

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
),

creative_economics AS (

    SELECT
        d.channel,
        d.campaign_id,
        d.campaign_name,
        d.creative_id,
        d.creative_name,
        d.creative_type,
        d.creative_concept,
        d.total_spend,
        d.total_impressions,
        d.total_clicks,
        v.paid_installs,
        v.d7_retained_users,
        v.payer_users,
        v.total_revenue,

        100.0 * d.total_clicks
            / NULLIF(d.total_impressions, 0)
            AS ctr_pct,

        1000.0 * d.total_spend
            / NULLIF(d.total_impressions, 0)
            AS cpm,

        d.total_spend
            / NULLIF(v.paid_installs, 0)
            AS cpi,

        100.0 * v.d7_retained_users
            / NULLIF(v.paid_installs, 0)
            AS d7_retention_pct,

        100.0 * v.payer_users
            / NULLIF(v.paid_installs, 0)
            AS payer_rate_pct,

        v.total_revenue
            / NULLIF(v.paid_installs, 0)
            AS arpu,

        100.0 * v.total_revenue
            / NULLIF(d.total_spend, 0)
            AS roas_pct,

        v.total_revenue - d.total_spend
            AS revenue_gap

    FROM creative_delivery AS d

    INNER JOIN creative_user_value AS v
        ON d.creative_id = v.creative_id
        AND d.campaign_id = v.campaign_id
),

creative_rankings AS (

    SELECT
        channel,
        campaign_id,
        campaign_name,
        creative_id,
        creative_name,
        creative_type,
        creative_concept,
        total_spend,
        total_impressions,
        total_clicks,
        paid_installs,
        ctr_pct,
        cpm,
        cpi,
        d7_retention_pct,
        payer_rate_pct,
        total_revenue,
        arpu,
        roas_pct,
        revenue_gap,

        DENSE_RANK() OVER (
            PARTITION BY campaign_id
            ORDER BY roas_pct DESC
        ) AS roas_rank_within_campaign,

        DENSE_RANK() OVER (
            PARTITION BY campaign_id
            ORDER BY total_spend DESC
        ) AS spend_rank_within_campaign

    FROM creative_economics
)

SELECT
    channel,
    campaign_id,
    campaign_name,
    creative_id,
    creative_name,
    creative_type,
    creative_concept,

    ROUND(total_spend, 2) AS total_spend,

    total_impressions,
    total_clicks,

    ROUND(ctr_pct, 2) AS ctr_pct,
    ROUND(cpm, 2) AS cpm,

    paid_installs,

    ROUND(cpi, 2) AS cpi,
    ROUND(d7_retention_pct, 2) AS d7_retention_pct,
    ROUND(payer_rate_pct, 2) AS payer_rate_pct,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(arpu, 2) AS arpu,
    ROUND(roas_pct, 2) AS roas_pct,
    ROUND(revenue_gap, 2) AS revenue_gap,

    roas_rank_within_campaign,
    spend_rank_within_campaign

FROM creative_rankings

ORDER BY
    channel,
    campaign_name,
    roas_rank_within_campaign,
    creative_id;
    
