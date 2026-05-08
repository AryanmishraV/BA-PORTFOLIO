-- ============================================================
-- Customer RFM Segmentation & Sales Analytics
-- Business Analyst Portfolio | Finance & Sales Reporting
-- Author: Saswat Mishra | github.com/AryanmishraV
-- ============================================================

-- TABLE SCHEMA:
-- customer_data(customer_id, region, segment, last_purchase_date,
--               frequency, monetary_value, recency_days, product_category, channel)

-- ── 1. RFM Score Calculation ──────────────────────────────────
WITH rfm_base AS (
    SELECT
        customer_id,
        region,
        segment,
        channel,
        recency_days,
        frequency,
        monetary_value,
        NTILE(5) OVER (ORDER BY recency_days DESC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)       AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value ASC)  AS m_score
    FROM customer_data
),
rfm_scored AS (
    SELECT *,
        r_score + f_score + m_score AS rfm_total,
        CASE
            WHEN r_score + f_score + m_score >= 13 THEN 'Champions'
            WHEN r_score + f_score + m_score >= 10 AND r_score >= 4 THEN 'Loyal Customers'
            WHEN r_score + f_score + m_score >= 10 AND r_score < 4  THEN 'At Risk - High Value'
            WHEN r_score + f_score + m_score >= 7  AND r_score >= 3 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score <= 2                       THEN 'New Customers'
            WHEN r_score + f_score + m_score >= 7  AND r_score < 3  THEN 'Needs Attention'
            WHEN r_score <= 2 AND f_score >= 4                       THEN 'Cannot Lose Them'
            ELSE 'Hibernating'
        END AS customer_segment
    FROM rfm_base
)
SELECT
    customer_segment,
    COUNT(*)                                    AS customer_count,
    ROUND(AVG(recency_days), 0)                 AS avg_recency_days,
    ROUND(AVG(frequency), 1)                    AS avg_frequency,
    ROUND(AVG(monetary_value), 0)               AS avg_clv,
    ROUND(SUM(monetary_value), 0)               AS total_revenue,
    ROUND(SUM(monetary_value) * 100.0 / SUM(SUM(monetary_value)) OVER(), 1) AS revenue_share_pct
FROM rfm_scored
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- ── 2. Revenue by Sales Channel ───────────────────────────────
SELECT
    channel,
    COUNT(*)                                    AS customers,
    ROUND(SUM(monetary_value), 0)               AS total_revenue,
    ROUND(AVG(monetary_value), 0)               AS avg_clv,
    ROUND(AVG(frequency), 1)                    AS avg_purchase_freq
FROM customer_data
GROUP BY channel
ORDER BY total_revenue DESC;

-- ── 3. Regional Customer Value ────────────────────────────────
SELECT
    region,
    COUNT(*)                                    AS customers,
    ROUND(SUM(monetary_value), 0)               AS total_revenue,
    ROUND(AVG(monetary_value), 0)               AS avg_clv,
    ROUND(AVG(recency_days), 0)                 AS avg_recency
FROM customer_data
GROUP BY region
ORDER BY total_revenue DESC;

-- ── 4. B2B vs B2C vs Enterprise Comparison ───────────────────
SELECT
    segment,
    COUNT(*)                                    AS customers,
    ROUND(AVG(monetary_value), 0)               AS avg_clv,
    ROUND(SUM(monetary_value), 0)               AS total_revenue,
    ROUND(AVG(frequency), 1)                    AS avg_freq,
    ROUND(AVG(recency_days), 0)                 AS avg_recency
FROM customer_data
GROUP BY segment
ORDER BY avg_clv DESC;

-- ── 5. High-Value Customers (Top 20%) ─────────────────────────
SELECT
    customer_id,
    region,
    segment,
    channel,
    ROUND(monetary_value, 0)    AS clv,
    frequency,
    recency_days
FROM customer_data
WHERE monetary_value >= (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY monetary_value) FROM customer_data)
ORDER BY monetary_value DESC
LIMIT 50;

-- ── 6. Churn Risk - Long Inactive Customers ───────────────────
SELECT
    customer_id,
    region,
    ROUND(monetary_value, 0)    AS clv,
    frequency,
    recency_days,
    CASE
        WHEN recency_days > 300 THEN 'Critical Churn Risk'
        WHEN recency_days > 200 THEN 'High Churn Risk'
        WHEN recency_days > 120 THEN 'Medium Churn Risk'
    END AS churn_risk
FROM customer_data
WHERE recency_days > 120
ORDER BY monetary_value DESC
LIMIT 30;

-- ── 7. Channel × Region Revenue Matrix ───────────────────────
SELECT
    region,
    channel,
    COUNT(*)                        AS customers,
    ROUND(SUM(monetary_value), 0)   AS revenue
FROM customer_data
GROUP BY region, channel
ORDER BY region, revenue DESC;

-- ── 8. Product Category Performance ──────────────────────────
SELECT
    product_category,
    COUNT(*)                                    AS customers,
    ROUND(SUM(monetary_value), 0)               AS revenue,
    ROUND(AVG(monetary_value), 0)               AS avg_clv,
    ROUND(AVG(frequency), 1)                    AS avg_frequency
FROM customer_data
GROUP BY product_category
ORDER BY revenue DESC;
