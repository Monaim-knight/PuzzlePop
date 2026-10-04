SELECT
    dc.channel_name,
    fr.day_number,
    AVG(fr.retained) AS retention_rate
FROM fact_retention fr
JOIN dim_user du ON fr.user_id = du.user_id
JOIN dim_channel dc ON du.attribution_channel = dc.channel_name
GROUP BY dc.channel_name, fr.day_number
ORDER BY fr.day_number, retention_rate DESC;

