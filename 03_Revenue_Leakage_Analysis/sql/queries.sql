-- ============================================================
-- Revenue Leakage & Root Cause Analysis
-- Business Analyst Portfolio | Finance & Sales Reporting
-- Author: Saswat Mishra | github.com/AryanmishraV
-- ============================================================

-- TABLE SCHEMA:
-- leakage_data(transaction_id, date, leakage_type, amount_lost,
--              region, product, detected_by, status, recovery_amount)

-- ── 1. Executive Leakage Summary ─────────────────────────────
SELECT
    COUNT(*)                                                AS total_incidents,
    ROUND(SUM(amount_lost), 0)                              AS total_amount_lost,
    ROUND(SUM(recovery_amount), 0)                          AS total_recovered,
    ROUND(SUM(amount_lost) - SUM(recovery_amount), 0)       AS net_leakage,
    ROUND(SUM(recovery_amount) / SUM(amount_lost) * 100, 1) AS recovery_rate_pct,
    ROUND(AVG(amount_lost), 0)                              AS avg_loss_per_incident
FROM leakage_data;

-- ── 2. Leakage by Type (Root Cause) ──────────────────────────
SELECT
    leakage_type,
    COUNT(*)                                                AS incidents,
    ROUND(SUM(amount_lost), 0)                              AS total_loss,
    ROUND(SUM(recovery_amount), 0)                          AS recovered,
    ROUND(SUM(amount_lost) - SUM(recovery_amount), 0)       AS net_loss,
    ROUND(SUM(recovery_amount) / SUM(amount_lost) * 100, 1) AS recovery_rate_pct,
    ROUND(SUM(amount_lost) * 100.0 / SUM(SUM(amount_lost)) OVER(), 1) AS share_pct
FROM leakage_data
GROUP BY leakage_type
ORDER BY total_loss DESC;

-- ── 3. Leakage by Region ──────────────────────────────────────
SELECT
    region,
    COUNT(*)                                                AS incidents,
    ROUND(SUM(amount_lost), 0)                              AS total_loss,
    ROUND(SUM(recovery_amount), 0)                          AS recovered,
    ROUND(SUM(amount_lost) - SUM(recovery_amount), 0)       AS net_loss,
    ROUND(SUM(recovery_amount) / SUM(amount_lost) * 100, 1) AS recovery_rate_pct
FROM leakage_data
GROUP BY region
ORDER BY net_loss DESC;

-- ── 4. Detection Method Effectiveness ────────────────────────
SELECT
    detected_by,
    COUNT(*)                                                AS incidents,
    ROUND(SUM(amount_lost), 0)                              AS amount_flagged,
    ROUND(SUM(recovery_amount), 0)                          AS amount_recovered,
    ROUND(SUM(recovery_amount) / SUM(amount_lost) * 100, 1) AS recovery_efficiency_pct
FROM leakage_data
GROUP BY detected_by
ORDER BY recovery_efficiency_pct DESC;

-- ── 5. Monthly Leakage Trend ──────────────────────────────────
SELECT
    SUBSTR(date, 1, 7)                                      AS month,
    COUNT(*)                                                AS incidents,
    ROUND(SUM(amount_lost), 0)                              AS total_loss,
    ROUND(SUM(recovery_amount), 0)                          AS recovered,
    ROUND(SUM(amount_lost) - SUM(recovery_amount), 0)       AS net_loss
FROM leakage_data
GROUP BY month
ORDER BY month;

-- ── 6. Written Off Analysis ───────────────────────────────────
SELECT
    leakage_type,
    COUNT(*)                        AS written_off_count,
    ROUND(SUM(amount_lost), 0)      AS amount_written_off
FROM leakage_data
WHERE status = 'Written Off'
GROUP BY leakage_type
ORDER BY amount_written_off DESC;

-- ── 7. Top 20 Highest Leakage Transactions ────────────────────
SELECT
    transaction_id,
    date,
    leakage_type,
    region,
    ROUND(amount_lost, 0)       AS amount_lost,
    ROUND(recovery_amount, 0)   AS recovery_amount,
    status
FROM leakage_data
ORDER BY amount_lost DESC
LIMIT 20;

-- ── 8. Recovery Gap by Status ─────────────────────────────────
SELECT
    status,
    COUNT(*)                                                AS incidents,
    ROUND(SUM(amount_lost), 0)                              AS total_loss,
    ROUND(SUM(recovery_amount), 0)                          AS recovered,
    ROUND(SUM(amount_lost) - SUM(recovery_amount), 0)       AS gap
FROM leakage_data
GROUP BY status;

-- ── 9. Region × Leakage Type Cross-Analysis ───────────────────
SELECT
    region,
    leakage_type,
    COUNT(*)                        AS incidents,
    ROUND(SUM(amount_lost), 0)      AS total_loss
FROM leakage_data
GROUP BY region, leakage_type
ORDER BY total_loss DESC;

-- ── 10. Running Cumulative Leakage (2024) ─────────────────────
SELECT
    SUBSTR(date, 1, 7)                                          AS month,
    ROUND(SUM(amount_lost), 0)                                  AS monthly_loss,
    ROUND(SUM(SUM(amount_lost)) OVER (ORDER BY SUBSTR(date, 1, 7)), 0) AS cumulative_loss
FROM leakage_data
GROUP BY month
ORDER BY month;
