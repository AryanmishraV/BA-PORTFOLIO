-- ============================================================
-- Regional Sales Performance Analysis
-- Business Analyst Portfolio | Finance & Sales Reporting
-- Author: Saswat Mishra | github.com/AryanmishraV
-- ============================================================

-- TABLE SCHEMA:
-- sales_data(month, region, product, sales_rep, quantity,
--            unit_price, revenue, target, returns, discount_pct)

-- ── 1. Overall KPIs ──────────────────────────────────────────
SELECT
    SUM(revenue)                                    AS total_gross_revenue,
    SUM(returns)                                    AS total_returns,
    SUM(revenue) - SUM(returns)                     AS net_revenue,
    SUM(target)                                     AS total_target,
    ROUND(SUM(revenue) / SUM(target) * 100, 1)     AS attainment_pct,
    ROUND(AVG(discount_pct), 2)                     AS avg_discount_pct,
    COUNT(*)                                        AS total_transactions
FROM sales_data;

-- ── 2. Revenue by Region with Attainment ─────────────────────
SELECT
    region,
    SUM(revenue)                                    AS gross_revenue,
    SUM(returns)                                    AS total_returns,
    SUM(revenue) - SUM(returns)                     AS net_revenue,
    SUM(target)                                     AS target,
    ROUND(SUM(revenue) / SUM(target) * 100, 1)     AS attainment_pct,
    ROUND(AVG(discount_pct), 2)                     AS avg_discount,
    COUNT(*)                                        AS transactions
FROM sales_data
GROUP BY region
ORDER BY gross_revenue DESC;

-- ── 3. Product Performance ────────────────────────────────────
SELECT
    product,
    SUM(revenue)                                          AS revenue,
    SUM(quantity)                                         AS units_sold,
    ROUND(AVG(unit_price), 2)                             AS avg_unit_price,
    ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER(), 1) AS revenue_share_pct
FROM sales_data
GROUP BY product
ORDER BY revenue DESC;

-- ── 4. Month-over-Month Revenue Trend ────────────────────────
SELECT
    month,
    SUM(revenue)                                             AS revenue,
    LAG(SUM(revenue)) OVER (ORDER BY month)                  AS prev_month_revenue,
    ROUND(
        (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY month))
        / LAG(SUM(revenue)) OVER (ORDER BY month) * 100, 1
    )                                                        AS mom_growth_pct
FROM sales_data
GROUP BY month
ORDER BY month;

-- ── 5. Top 10 Sales Reps by Revenue ──────────────────────────
SELECT
    sales_rep,
    SUM(revenue)                    AS total_revenue,
    COUNT(*)                        AS transactions,
    ROUND(AVG(discount_pct), 2)     AS avg_discount,
    SUM(returns)                    AS total_returns
FROM sales_data
GROUP BY sales_rep
ORDER BY total_revenue DESC
LIMIT 10;

-- ── 6. Region × Product Revenue Matrix ───────────────────────
SELECT
    region,
    product,
    SUM(revenue)    AS revenue,
    SUM(quantity)   AS units_sold
FROM sales_data
GROUP BY region, product
ORDER BY region, revenue DESC;

-- ── 7. Discount Impact Analysis ───────────────────────────────
SELECT
    region,
    ROUND(AVG(discount_pct), 2)                             AS avg_discount_pct,
    SUM(revenue)                                            AS actual_revenue,
    ROUND(SUM(revenue * discount_pct / 100), 0)             AS estimated_revenue_lost,
    ROUND(SUM(revenue) + SUM(revenue * discount_pct/100), 0) AS potential_revenue
FROM sales_data
GROUP BY region
ORDER BY estimated_revenue_lost DESC;

-- ── 8. Underperforming Reps (Below 50% of Avg Revenue) ───────
WITH rep_stats AS (
    SELECT
        sales_rep,
        SUM(revenue) AS total_revenue,
        AVG(SUM(revenue)) OVER () AS overall_avg
    FROM sales_data
    GROUP BY sales_rep
)
SELECT
    sales_rep,
    ROUND(total_revenue, 0)   AS total_revenue,
    ROUND(overall_avg, 0)     AS team_avg,
    ROUND(total_revenue / overall_avg * 100, 1) AS pct_of_avg
FROM rep_stats
WHERE total_revenue < overall_avg * 0.5
ORDER BY total_revenue;

-- ── 9. Return Rate by Product ─────────────────────────────────
SELECT
    product,
    SUM(revenue)                                    AS revenue,
    SUM(returns)                                    AS returns,
    ROUND(SUM(returns) / SUM(revenue) * 100, 2)    AS return_rate_pct
FROM sales_data
GROUP BY product
ORDER BY return_rate_pct DESC;

-- ── 10. Running Total Revenue (Cumulative) ────────────────────
SELECT
    month,
    SUM(revenue)                                        AS monthly_revenue,
    SUM(SUM(revenue)) OVER (ORDER BY month)             AS cumulative_revenue
FROM sales_data
GROUP BY month
ORDER BY month;
