"""
Revenue Leakage & Root Cause Analysis
Business Analyst Portfolio Project | Finance & Sales Reporting
Author: Saswat Mishra | github.com/AryanmishraV
"""

import pandas as pd
import numpy as np
import os

BASE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(BASE, '../data/leakage_data.csv'))

print("=" * 60)
print("  REVENUE LEAKAGE & ROOT CAUSE ANALYSIS")
print("=" * 60)

# ── Executive Summary ─────────────────────────────────────────────────────────
total_lost     = df['amount_lost'].sum()
total_recovered = df['recovery_amount'].sum()
net_leakage    = total_lost - total_recovered
recovery_rate  = (total_recovered / total_lost) * 100

print(f"\n📊 EXECUTIVE SUMMARY (FY 2024)")
print(f"  Total Revenue Lost   : ₹{total_lost:,.0f}")
print(f"  Amount Recovered     : ₹{total_recovered:,.0f}")
print(f"  Net Leakage          : ₹{net_leakage:,.0f}")
print(f"  Recovery Rate        : {recovery_rate:.1f}%")
print(f"  Avg Leakage/Incident : ₹{total_lost / len(df):,.0f}")

# ── By Leakage Type ───────────────────────────────────────────────────────────
print(f"\n🔍 ROOT CAUSE BREAKDOWN")
type_summary = (
    df.groupby('leakage_type')
    .agg(
        Incidents=('amount_lost', 'count'),
        Total_Loss=('amount_lost', 'sum'),
        Recovered=('recovery_amount', 'sum'),
        Avg_Loss=('amount_lost', 'mean')
    )
    .assign(
        Net_Loss=lambda x: x['Total_Loss'] - x['Recovered'],
        Recovery_Rate=lambda x: (x['Recovered'] / x['Total_Loss'] * 100).round(1),
        Share_Pct=lambda x: (x['Total_Loss'] / x['Total_Loss'].sum() * 100).round(1)
    )
    .sort_values('Total_Loss', ascending=False)
)
print(type_summary[['Incidents', 'Total_Loss', 'Recovered', 'Net_Loss', 'Recovery_Rate', 'Share_Pct']].to_string())

# ── By Region ─────────────────────────────────────────────────────────────────
print(f"\n📍 LEAKAGE BY REGION")
region_summary = (
    df.groupby('region')
    .agg(Incidents=('amount_lost', 'count'), Total_Loss=('amount_lost', 'sum'),
         Recovered=('recovery_amount', 'sum'))
    .assign(Net_Loss=lambda x: x['Total_Loss'] - x['Recovered'],
            Recovery_Rate=lambda x: (x['Recovered'] / x['Total_Loss'] * 100).round(1))
    .sort_values('Total_Loss', ascending=False)
)
print(region_summary.to_string())

# ── Detection Method Analysis ─────────────────────────────────────────────────
print(f"\n🔎 DETECTION METHODS EFFECTIVENESS")
detection = (
    df.groupby('detected_by')
    .agg(Incidents=('amount_lost', 'count'), Total_Flagged=('amount_lost', 'sum'),
         Recovered=('recovery_amount', 'sum'))
    .assign(Avg_Recovery=lambda x: (x['Recovered'] / x['Total_Flagged'] * 100).round(1))
    .sort_values('Incidents', ascending=False)
)
print(detection.to_string())

# ── Monthly Leakage Trend ─────────────────────────────────────────────────────
print(f"\n📅 MONTHLY LEAKAGE TREND")
df['month'] = pd.to_datetime(df['date']).dt.to_period('M').astype(str)
monthly = df.groupby('month').agg(
    Incidents=('amount_lost', 'count'), Loss=('amount_lost', 'sum'), Recovered=('recovery_amount', 'sum')
).assign(Net_Loss=lambda x: x['Loss'] - x['Recovered'])
print(monthly.to_string())

# ── Written Off Analysis ──────────────────────────────────────────────────────
written_off = df[df['status'] == 'Written Off']
print(f"\n💀 WRITTEN OFF AMOUNTS")
print(f"  Total Written Off: ₹{written_off['amount_lost'].sum():,.0f}")
print(f"  Incidents Written Off: {len(written_off)}")
print(f"\n  Top Leakage Type Written Off:")
print(written_off.groupby('leakage_type')['amount_lost'].sum().sort_values(ascending=False).to_string())

# ── Export ────────────────────────────────────────────────────────────────────
type_summary.to_csv(os.path.join(BASE, '../report/leakage_by_type.csv'))
region_summary.to_csv(os.path.join(BASE, '../report/leakage_by_region.csv'))
monthly.to_csv(os.path.join(BASE, '../report/monthly_leakage.csv'))
print(f"\n✅ Reports exported to /report/ folder")
print("=" * 60)
