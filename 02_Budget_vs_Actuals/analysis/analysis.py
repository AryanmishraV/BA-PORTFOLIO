"""
Budget vs Actuals Variance Report
Business Analyst Portfolio Project | Finance & Sales Reporting
Author: Saswat Mishra | github.com/AryanmishraV
"""

import pandas as pd
import numpy as np
import os

BASE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(BASE, '../data/budget_actuals.csv'))

print("=" * 60)
print("  BUDGET VS ACTUALS VARIANCE ANALYSIS")
print("=" * 60)

# ── Overall Variance Summary ──────────────────────────────────────────────────
total_budget = df['budget'].sum()
total_actual = df['actual'].sum()
total_variance = df['variance'].sum()
over_budget_rows = df[df['variance'] > 0]
under_budget_rows = df[df['variance'] < 0]

print(f"\n📊 OVERALL SUMMARY (FY 2024)")
print(f"  Total Budget   : ₹{total_budget:,.0f}")
print(f"  Total Actual   : ₹{total_actual:,.0f}")
print(f"  Net Variance   : ₹{total_variance:,.0f} ({'OVER BUDGET' if total_variance > 0 else 'UNDER BUDGET'})")
print(f"  Over-Budget Instances  : {len(over_budget_rows)}")
print(f"  Under-Budget Instances : {len(under_budget_rows)}")

# ── Department-wise Variance ──────────────────────────────────────────────────
print(f"\n🏢 VARIANCE BY DEPARTMENT")
dept_summary = (
    df.groupby('department')
    .agg(Budget=('budget', 'sum'), Actual=('actual', 'sum'), Variance=('variance', 'sum'))
    .assign(Variance_Pct=lambda x: (x['Variance'] / x['Budget'] * 100).round(1),
            Status=lambda x: x['Variance'].apply(lambda v: '🔴 OVER' if v > 0 else '🟢 UNDER'))
    .sort_values('Variance', ascending=False)
)
print(dept_summary.to_string())

# ── Category Breakdown ────────────────────────────────────────────────────────
print(f"\n📂 VARIANCE BY EXPENSE CATEGORY")
cat_summary = (
    df.groupby('category')
    .agg(Budget=('budget', 'sum'), Actual=('actual', 'sum'), Variance=('variance', 'sum'))
    .assign(Variance_Pct=lambda x: (x['Variance'] / x['Budget'] * 100).round(1))
    .sort_values('Variance', ascending=False)
)
print(cat_summary.to_string())

# ── Monthly Variance Trend ────────────────────────────────────────────────────
print(f"\n📅 MONTHLY VARIANCE TREND")
monthly = (
    df.groupby('month')
    .agg(Budget=('budget', 'sum'), Actual=('actual', 'sum'), Variance=('variance', 'sum'))
    .assign(Variance_Pct=lambda x: (x['Variance'] / x['Budget'] * 100).round(1))
)
print(monthly.to_string())

# ── Top 10 Biggest Overruns ───────────────────────────────────────────────────
print(f"\n⚠️  TOP 10 BIGGEST BUDGET OVERRUNS")
overruns = df[df['variance'] > 0].nlargest(10, 'variance')[
    ['month', 'department', 'category', 'budget', 'actual', 'variance', 'variance_pct']
]
print(overruns.to_string(index=False))

# ── Risk Flagging ─────────────────────────────────────────────────────────────
print(f"\n🚨 HIGH-RISK FLAGS (Variance > 20%)")
high_risk = df[df['variance_pct'] > 20][['month', 'department', 'category', 'budget', 'actual', 'variance_pct']]
print(f"  Total flagged: {len(high_risk)} line items")
print(high_risk.head(15).to_string(index=False))

# ── Export ────────────────────────────────────────────────────────────────────
dept_summary.to_csv(os.path.join(BASE, '../report/dept_variance.csv'))
monthly.to_csv(os.path.join(BASE, '../report/monthly_variance.csv'))
high_risk.to_csv(os.path.join(BASE, '../report/high_risk_flags.csv'), index=False)
print(f"\n✅ Reports exported to /report/ folder")
print("=" * 60)
