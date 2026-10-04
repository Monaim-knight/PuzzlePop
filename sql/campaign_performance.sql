SELECT
    dca.campaign_name,
    dc.channel_name,
    COUNT(fi.install_id) AS installs,
    SUM(fi.cost) AS total_cost,
    SUM(fr.revenue_amount) AS total_revenue,
    SUM(fr.revenue_amount) / SUM(fi.cost) AS roas,
    SUM(fi.clicks) / SUM(fi.impressions) AS ctr,
    COUNT(fi.install_id) / SUM(fi.clicks) AS cvr
FROM fact_installs fi
JOIN dim_campaign dca ON fi.campaign_id = dca.campaign_id
JOIN dim_channel dc ON fi.channel_id = dc.channel_id
LEFT JOIN fact_revenue fr ON fi.user_id = fr.user_id
GROUP BY dca.campaign_name, dc.channel_name
ORDER BY roas DESC;

