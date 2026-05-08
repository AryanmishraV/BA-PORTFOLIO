"""
Regional Sales Performance Analysis
Business Analyst Portfolio Project | Finance & Sales Reporting
Author: Saswat Mishra | github.com/AryanmishraV
"""

import pandas as pd
import numpy as np
import os

# ── Load Data ────────────────────────────────────────────────────────────────
BASE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(BASE, '../data/sales_data.csv'))

print("=" * 60)
print("  REGIONAL SALES PERFORMANCE ANALYSIS")
print("=" * 60)

# ── KPI Summary ──────────────────────────────────────────────────────────────
total_revenue  = df['revenue'].sum()
total_returns  = df['returns'].sum()
net_revenue    = total_revenue - total_returns
total_target   = df['target'].sum()
attainment_pct = (total_revenue / total_target) * 100
avg_discount   = df['discount_pct'].mean()

print(f"\n📊 KPI DASHBOARD")
print(f"  Total Gross Revenue : ₹{total_revenue:,.0f}")
print(f"  Total Returns       : ₹{total_returns:,.0f}")
print(f"  Net Revenue         : ₹{net_revenue:,.0f}")
print(f"  Target Attainment   : {attainment_pct:.1f}%")
print(f"  Avg Discount Given  : {avg_discount:.1f}%")

# ── Regional Breakdown ───────────────────────────────────────────────────────
print(f"\n📍 REVENUE BY REGION")
region_summary = (
    df.groupby('region')
    .agg(
        Revenue=('revenue', 'sum'),
        Target=('target', 'sum'),
        Transactions=('revenue', 'count'),
        Avg_Discount=('discount_pct', 'mean'),
        Returns=('returns', 'sum')
    )
    .assign(
        Attainment_Pct=lambda x: (x['Revenue'] / x['Target'] * 100).round(1),
        Net_Revenue=lambda x: x['Revenue'] - x['Returns']
    )
    .sort_values('Revenue', ascending=False)
)
print(region_summary[['Revenue', 'Target', 'Attainment_Pct', 'Net_Revenue', 'Avg_Discount']].to_string())

# ── Product Performance ──────────────────────────────────────────────────────
print(f"\n📦 REVENUE BY PRODUCT")
product_summary = (
    df.groupby('product')
    .agg(Revenue=('revenue', 'sum'), Qty=('quantity', 'sum'), Avg_Price=('unit_price', 'mean'))
    .assign(Revenue_Share=lambda x: (x['Revenue'] / x['Revenue'].sum() * 100).round(1))
    .sort_values('Revenue', ascending=False)
)
print(product_summary.to_string())

# ── Month-over-Month Trend ───────────────────────────────────────────────────
print(f"\n📅 MONTHLY REVENUE TREND")
monthly = df.groupby('month')['revenue'].sum().reset_index()
monthly['MoM_Change_Pct'] = monthly['revenue'].pct_change() * 100
monthly['MoM_Change_Pct'] = monthly['MoM_Change_Pct'].round(1)
print(monthly.to_string(index=False))

# ── Top & Bottom Sales Reps ──────────────────────────────────────────────────
print(f"\n🏆 TOP 5 SALES REPS")
rep_perf = df.groupby('sales_rep')['revenue'].sum().sort_values(ascending=False)
print(rep_perf.head(5).to_string())

print(f"\n⚠️  BOTTOM 5 SALES REPS (Need Coaching)")
print(rep_perf.tail(5).to_string())

# ── Root Cause: High Discount Regions ────────────────────────────────────────
print(f"\n🔍 ROOT CAUSE: HIGH DISCOUNT REGIONS")
high_disc = df.groupby('region').agg(
    Avg_Discount=('discount_pct', 'mean'),
    Revenue_Lost_Est=('revenue', lambda x: (x * df.loc[x.index, 'discount_pct'] / 100).sum())
).sort_values('Avg_Discount', ascending=False)
print(high_disc.to_string())

# ── Export Summary ───────────────────────────────────────────────────────────
region_summary.to_csv(os.path.join(BASE, '../report/regional_summary.csv'))
monthly.to_csv(os.path.join(BASE, '../report/monthly_trend.csv'), index=False)
print(f"\n✅ Reports exported to /report/ folder")
print("=" * 60)
