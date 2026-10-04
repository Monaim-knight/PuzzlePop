SELECT
    fi.channel_id,
    dc.channel_name,
    SUM(fi.cost) / COUNT(fi.install_id) AS cpi
FROM fact_installs fi
JOIN dim_channel dc ON fi.channel_id = dc.channel_id
GROUP BY fi.channel_id, dc.channel_name
ORDER BY cpi;

SELECT
    fi.channel_id,
    dc.channel_name,
    SUM(fi.clicks) / SUM(fi.impressions) AS ctr
FROM fact_installs fi
JOIN dim_channel dc ON fi.channel_id = dc.channel_id
GROUP BY fi.channel_id, dc.channel_name
ORDER BY ctr DESC;

SELECT
    fi.channel_id,
    dc.channel_name,
    COUNT(fi.install_id) / SUM(fi.clicks) AS cvr
FROM fact_installs fi
JOIN dim_channel dc ON fi.channel_id = dc.channel_id
GROUP BY fi.channel_id, dc.channel_name
ORDER BY cvr DESC;

SELECT
    fi.channel_id,
    dc.channel_name,
    SUM(fr.revenue_amount) / SUM(fi.cost) AS roas
FROM fact_installs fi
JOIN dim_channel dc ON fi.channel_id = dc.channel_id
LEFT JOIN fact_revenue fr ON fi.user_id = fr.user_id
GROUP BY fi.channel_id, dc.channel_name
ORDER BY roas DESC;

