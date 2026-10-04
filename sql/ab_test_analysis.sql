SELECT
    variant,
    AVG(metric_value) AS avg_metric,
    COUNT(*) AS sample_size
FROM fact_ab_tests
GROUP BY variant;

SELECT
    (AVG(CASE WHEN variant = 'B' THEN metric_value END) -
     AVG(CASE WHEN variant = 'A' THEN metric_value END)) AS uplift
FROM fact_ab_tests;

SELECT
    du.country,
    variant,
    AVG(metric_value) AS avg_metric
FROM fact_ab_tests ab
JOIN dim_user du ON ab.user_id = du.user_id
GROUP BY du.country, variant
ORDER BY du.country;

