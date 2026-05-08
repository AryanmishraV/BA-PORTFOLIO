"""
Customer RFM Segmentation & Sales Analytics
Business Analyst Portfolio Project | Finance & Sales Reporting
Author: Saswat Mishra | github.com/AryanmishraV
"""

import pandas as pd
import numpy as np
import os

BASE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(BASE, '../data/customer_data.csv'))

print("=" * 60)
print("  CUSTOMER RFM SEGMENTATION & SALES ANALYTICS")
print("=" * 60)

# ── RFM Scoring ───────────────────────────────────────────────────────────────
# Recency: Lower days = better (score 5 is best)
df['R_Score'] = pd.qcut(df['recency_days'], 5, labels=[5, 4, 3, 2, 1]).astype(int)
# Frequency: Higher = better
df['F_Score'] = pd.qcut(df['frequency'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5]).astype(int)
# Monetary: Higher = better
df['M_Score'] = pd.qcut(df['monetary_value'], 5, labels=[1, 2, 3, 4, 5]).astype(int)
df['RFM_Score'] = df['R_Score'] + df['F_Score'] + df['M_Score']

# ── Segment Assignment ────────────────────────────────────────────────────────
def assign_segment(row):
    score = row['RFM_Score']
    r = row['R_Score']
    f = row['F_Score']
    if score >= 13:
        return 'Champions'
    elif score >= 10 and r >= 4:
        return 'Loyal Customers'
    elif score >= 10 and r < 4:
        return 'At Risk - High Value'
    elif score >= 7 and r >= 3:
        return 'Potential Loyalists'
    elif r >= 4 and f <= 2:
        return 'New Customers'
    elif score >= 7 and r < 3:
        return 'Needs Attention'
    elif r <= 2 and f >= 4:
        return 'Cannot Lose Them'
    else:
        return 'Hibernating'

df['Segment'] = df.apply(assign_segment, axis=1)

# ── Segment Summary ───────────────────────────────────────────────────────────
print(f"\n📊 RFM SEGMENT OVERVIEW")
seg_summary = (
    df.groupby('Segment')
    .agg(
        Customers=('customer_id', 'count'),
        Avg_Recency=('recency_days', 'mean'),
        Avg_Frequency=('frequency', 'mean'),
        Avg_Monetary=('monetary_value', 'mean'),
        Total_Revenue=('monetary_value', 'sum')
    )
    .round(1)
    .assign(Revenue_Share=lambda x: (x['Total_Revenue'] / x['Total_Revenue'].sum() * 100).round(1))
    .sort_values('Total_Revenue', ascending=False)
)
print(seg_summary.to_string())

# ── Channel Analysis ──────────────────────────────────────────────────────────
print(f"\n📡 REVENUE BY SALES CHANNEL")
channel = (
    df.groupby('channel')
    .agg(Customers=('customer_id', 'count'), Revenue=('monetary_value', 'sum'),
         Avg_Value=('monetary_value', 'mean'), Avg_Frequency=('frequency', 'mean'))
    .assign(Revenue_Share=lambda x: (x['Revenue'] / x['Revenue'].sum() * 100).round(1))
    .sort_values('Revenue', ascending=False)
)
print(channel.to_string())

# ── Segment × Channel Cross-tab ───────────────────────────────────────────────
print(f"\n🔀 SEGMENT × CHANNEL (Customer Count)")
cross = pd.crosstab(df['Segment'], df['channel'])
print(cross.to_string())

# ── High-Value Customers at Risk ──────────────────────────────────────────────
print(f"\n🚨 HIGH-VALUE CUSTOMERS AT RISK (Action Required)")
at_risk = df[df['Segment'].isin(['At Risk - High Value', 'Cannot Lose Them'])].sort_values('monetary_value', ascending=False)
print(f"  Count: {len(at_risk)}")
print(f"  Total Revenue at Risk: ₹{at_risk['monetary_value'].sum():,.0f}")
print(at_risk[['customer_id', 'region', 'recency_days', 'frequency', 'monetary_value', 'Segment']].head(10).to_string(index=False))

# ── Regional Customer Value ───────────────────────────────────────────────────
print(f"\n📍 CUSTOMER VALUE BY REGION")
region = df.groupby('region').agg(
    Customers=('customer_id', 'count'), Total_Revenue=('monetary_value', 'sum'),
    Avg_CLV=('monetary_value', 'mean')
).sort_values('Total_Revenue', ascending=False)
print(region.to_string())

# ── Export ────────────────────────────────────────────────────────────────────
df.to_csv(os.path.join(BASE, '../report/rfm_scored_customers.csv'), index=False)
seg_summary.to_csv(os.path.join(BASE, '../report/segment_summary.csv'))
at_risk[['customer_id', 'region', 'recency_days', 'frequency', 'monetary_value', 'Segment']].to_csv(
    os.path.join(BASE, '../report/at_risk_customers.csv'), index=False)
print(f"\n✅ Reports exported to /report/ folder")
print("=" * 60)
