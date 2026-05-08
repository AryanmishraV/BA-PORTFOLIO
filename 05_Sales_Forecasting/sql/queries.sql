-- ============================================================
-- Sales Forecasting & Trend Analysis
-- Business Analyst Portfolio | Finance & Sales Reporting
-- Author: Saswat Mishra | github.com/AryanmishraV
-- ============================================================

-- TABLE SCHEMA:
-- monthly_revenue(month, year, month_num, revenue, units_sold,
--                 new_customers, avg_deal_size, sales_cycle_days, win_rate_pct)

-- ── 1. Annual Revenue Summary ─────────────────────────────────
SELECT
    year,
    SUM(revenue)                                    AS annual_revenue,
    ROUND(AVG(revenue), 0)                          AS avg_monthly_revenue,
    MAX(revenue)                                    AS peak_month_revenue,
    MIN(revenue)                                    AS trough_month_revenue,
    SUM(units_sold)                                 AS total_units,
    ROUND(AVG(win_rate_pct), 1)                     AS avg_win_rate
FROM monthly_revenue
GROUP BY year
ORDER BY year;

-- ── 2. YoY Revenue Growth ─────────────────────────────────────
WITH annual AS (
    SELECT year, SUM(revenue) AS revenue
    FROM monthly_revenue
    GROUP BY year
)
SELECT
    a.year,
    ROUND(a.revenue, 0)                                         AS revenue,
    ROUND(b.revenue, 0)                                         AS prev_year_revenue,
    ROUND((a.revenue - b.revenue) / b.revenue * 100, 1)         AS yoy_growth_pct
FROM annual a
LEFT JOIN annual b ON a.year = b.year + 1
ORDER BY a.year;

-- ── 3. Seasonality Index by Month ────────────────────────────
WITH monthly_avg AS (
    SELECT month_num, AVG(revenue) AS avg_revenue
    FROM monthly_revenue
    GROUP BY month_num
),
overall AS (
    SELECT AVG(revenue) AS overall_avg FROM monthly_revenue
)
SELECT
    m.month_num,
    CASE m.month_num
        WHEN 1 THEN 'Jan' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar'
        WHEN 4 THEN 'Apr' WHEN 5 THEN 'May' WHEN 6 THEN 'Jun'
        WHEN 7 THEN 'Jul' WHEN 8 THEN 'Aug' WHEN 9 THEN 'Sep'
        WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dec'
    END AS month_name,
    ROUND(m.avg_revenue, 0)                         AS avg_revenue,
    ROUND(m.avg_revenue / o.overall_avg, 3)         AS seasonality_index
FROM monthly_avg m, overall o
ORDER BY m.month_num;

-- ── 4. 3-Month & 6-Month Moving Average ──────────────────────
SELECT
    month,
    ROUND(revenue, 0)                                       AS revenue,
    ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS ma_3m,
    ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW), 0) AS ma_6m,
    ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW), 0) AS ma_12m
FROM monthly_revenue
ORDER BY month;

-- ── 5. Best and Worst Performing Months ──────────────────────
SELECT
    month,
    year,
    ROUND(revenue, 0)   AS revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM monthly_revenue
ORDER BY revenue DESC
LIMIT 10;

-- ── 6. Sales Efficiency Metrics Trend ────────────────────────
SELECT
    year,
    ROUND(AVG(avg_deal_size), 0)        AS avg_deal_size,
    ROUND(AVG(sales_cycle_days), 0)     AS avg_sales_cycle_days,
    ROUND(AVG(win_rate_pct), 1)         AS avg_win_rate_pct,
    ROUND(AVG(new_customers), 0)        AS avg_new_customers_per_month
FROM monthly_revenue
GROUP BY year
ORDER BY year;

-- ── 7. Revenue per Customer Trend ─────────────────────────────
SELECT
    month,
    ROUND(revenue, 0)                               AS revenue,
    new_customers,
    ROUND(revenue / NULLIF(new_customers, 0), 0)    AS revenue_per_new_customer,
    ROUND(avg_deal_size, 0)                         AS avg_deal_size
FROM monthly_revenue
ORDER BY month;

-- ── 8. Cumulative Revenue Progress ───────────────────────────
SELECT
    month,
    year,
    ROUND(revenue, 0)                                           AS monthly_revenue,
    ROUND(SUM(revenue) OVER (PARTITION BY year ORDER BY month), 0) AS ytd_revenue
FROM monthly_revenue
ORDER BY month;

-- ── 9. Revenue Volatility by Year ─────────────────────────────
SELECT
    year,
    ROUND(AVG(revenue), 0)      AS avg_revenue,
    ROUND(MAX(revenue), 0)      AS max_revenue,
    ROUND(MIN(revenue), 0)      AS min_revenue,
    ROUND(MAX(revenue) - MIN(revenue), 0) AS revenue_range
FROM monthly_revenue
GROUP BY year;

-- ── 10. Win Rate vs Revenue Correlation ──────────────────────
SELECT
    month,
    ROUND(revenue, 0)       AS revenue,
    win_rate_pct,
    avg_deal_size,
    CASE
        WHEN win_rate_pct > 50 AND revenue > (SELECT AVG(revenue) FROM monthly_revenue) THEN 'High Win, High Rev'
        WHEN win_rate_pct > 50 AND revenue <= (SELECT AVG(revenue) FROM monthly_revenue) THEN 'High Win, Low Rev'
        WHEN win_rate_pct <= 50 AND revenue > (SELECT AVG(revenue) FROM monthly_revenue) THEN 'Low Win, High Rev'
        ELSE 'Low Win, Low Rev'
    END AS performance_quadrant
FROM monthly_revenue
ORDER BY month;
