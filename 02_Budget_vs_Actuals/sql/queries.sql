-- ============================================================
-- Budget vs Actuals Variance Analysis
-- Business Analyst Portfolio | Finance & Sales Reporting
-- Author: Saswat Mishra | github.com/AryanmishraV
-- ============================================================

-- TABLE SCHEMA:
-- budget_actuals(month, department, category, budget,
--                actual, variance, variance_pct, approved_by)

-- ── 1. Annual Summary ─────────────────────────────────────────
SELECT
    SUM(budget)                                     AS total_budget,
    SUM(actual)                                     AS total_actual,
    SUM(variance)                                   AS net_variance,
    ROUND(SUM(variance) / SUM(budget) * 100, 1)    AS overall_variance_pct,
    COUNT(CASE WHEN variance > 0 THEN 1 END)        AS over_budget_count,
    COUNT(CASE WHEN variance < 0 THEN 1 END)        AS under_budget_count
FROM budget_actuals;

-- ── 2. Department Variance Summary ───────────────────────────
SELECT
    department,
    SUM(budget)                                     AS total_budget,
    SUM(actual)                                     AS total_actual,
    SUM(variance)                                   AS net_variance,
    ROUND(SUM(variance) / SUM(budget) * 100, 1)    AS variance_pct,
    CASE WHEN SUM(variance) > 0 THEN 'OVER BUDGET'
         ELSE 'UNDER BUDGET' END                    AS status
FROM budget_actuals
GROUP BY department
ORDER BY net_variance DESC;

-- ── 3. Category-wise Variance ─────────────────────────────────
SELECT
    category,
    SUM(budget)                                     AS total_budget,
    SUM(actual)                                     AS total_actual,
    SUM(variance)                                   AS net_variance,
    ROUND(SUM(variance) / SUM(budget) * 100, 1)    AS variance_pct
FROM budget_actuals
GROUP BY category
ORDER BY net_variance DESC;

-- ── 4. Monthly Variance Trend ─────────────────────────────────
SELECT
    month,
    SUM(budget)                                     AS budget,
    SUM(actual)                                     AS actual,
    SUM(variance)                                   AS variance,
    ROUND(SUM(variance) / SUM(budget) * 100, 1)    AS variance_pct,
    LAG(SUM(variance)) OVER (ORDER BY month)        AS prev_month_variance
FROM budget_actuals
GROUP BY month
ORDER BY month;

-- ── 5. Top 15 Budget Overruns ─────────────────────────────────
SELECT
    month,
    department,
    category,
    budget,
    actual,
    variance,
    variance_pct
FROM budget_actuals
WHERE variance > 0
ORDER BY variance DESC
LIMIT 15;

-- ── 6. High-Risk Line Items (>20% Variance) ───────────────────
SELECT
    month,
    department,
    category,
    budget,
    actual,
    variance,
    variance_pct,
    CASE
        WHEN variance_pct > 25 THEN 'CRITICAL'
        WHEN variance_pct > 20 THEN 'HIGH'
        ELSE 'MEDIUM'
    END AS risk_level
FROM budget_actuals
WHERE variance_pct > 20
ORDER BY variance DESC;

-- ── 7. Department × Category Heat View ────────────────────────
SELECT
    department,
    category,
    SUM(variance)                                       AS total_variance,
    ROUND(SUM(variance) / SUM(budget) * 100, 1)        AS variance_pct
FROM budget_actuals
GROUP BY department, category
ORDER BY total_variance DESC;

-- ── 8. Consistent Over-Budget Departments ─────────────────────
SELECT
    department,
    COUNT(CASE WHEN variance > 0 THEN 1 END)            AS months_over_budget,
    COUNT(*)                                            AS total_months,
    ROUND(COUNT(CASE WHEN variance > 0 THEN 1 END) * 100.0 / COUNT(*), 1) AS over_budget_rate_pct
FROM budget_actuals
GROUP BY department
HAVING over_budget_rate_pct > 60
ORDER BY over_budget_rate_pct DESC;

-- ── 9. Budget Utilisation Rate ────────────────────────────────
SELECT
    department,
    category,
    ROUND(SUM(actual) / SUM(budget) * 100, 1)  AS utilisation_pct
FROM budget_actuals
GROUP BY department, category
ORDER BY utilisation_pct DESC;

-- ── 10. Savings Opportunities (Under-budget items) ────────────
SELECT
    department,
    SUM(ABS(variance)) AS potential_savings,
    COUNT(*)            AS under_budget_line_items
FROM budget_actuals
WHERE variance < 0
GROUP BY department
ORDER BY potential_savings DESC;
