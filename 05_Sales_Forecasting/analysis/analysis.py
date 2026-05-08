"""
Sales Forecasting & Trend Analysis
Business Analyst Portfolio Project | Finance & Sales Reporting
Author: Saswat Mishra | github.com/AryanmishraV
"""

import pandas as pd
import numpy as np
import os

BASE = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(BASE, '../data/monthly_revenue.csv'))
df['month'] = pd.to_datetime(df['month'])
df = df.sort_values('month').reset_index(drop=True)

print("=" * 60)
print("  SALES FORECASTING & TREND ANALYSIS")
print("=" * 60)

# ── Historical Summary ────────────────────────────────────────────────────────
print(f"\n📊 HISTORICAL PERFORMANCE SUMMARY (2022–2024)")
for year in [2022, 2023, 2024]:
    yd = df[df['year'] == year]
    print(f"  {year} | Revenue: ₹{yd['revenue'].sum():,.0f} | "
          f"Avg Monthly: ₹{yd['revenue'].mean():,.0f} | "
          f"Peak Month: {yd.loc[yd['revenue'].idxmax(), 'month'].strftime('%b')} | "
          f"Avg Win Rate: {yd['win_rate_pct'].mean():.1f}%")

# ── YoY Growth ────────────────────────────────────────────────────────────────
print(f"\n📈 YEAR-OVER-YEAR GROWTH")
yearly = df.groupby('year')['revenue'].sum()
yoy = yearly.pct_change() * 100
for year in [2023, 2024]:
    print(f"  {year} vs {year-1}: {yoy[year]:+.1f}%")

# ── Seasonality Analysis ──────────────────────────────────────────────────────
print(f"\n📅 SEASONALITY INDEX BY MONTH")
df['month_name'] = df['month'].dt.strftime('%b')
monthly_avg = df.groupby('month_num')['revenue'].mean()
overall_avg = df['revenue'].mean()
seasonality = (monthly_avg / overall_avg).round(3)
months_map = {1:'Jan',2:'Feb',3:'Mar',4:'Apr',5:'May',6:'Jun',7:'Jul',8:'Aug',9:'Sep',10:'Oct',11:'Nov',12:'Dec'}
for m, idx in seasonality.items():
    bar = '█' * int(idx * 10)
    flag = ' ← Peak' if idx == seasonality.max() else (' ← Trough' if idx == seasonality.min() else '')
    print(f"  {months_map[m]:3} | {idx:.3f} | {bar}{flag}")

# ── Moving Averages (Trend Smoothing) ────────────────────────────────────────
df['MA_3M']  = df['revenue'].rolling(3).mean()
df['MA_6M']  = df['revenue'].rolling(6).mean()
df['MA_12M'] = df['revenue'].rolling(12).mean()

print(f"\n📉 TREND ANALYSIS (Last 12 Months with Moving Averages)")
last_12 = df.tail(12)[['month', 'revenue', 'MA_3M', 'MA_6M']].copy()
last_12['month'] = last_12['month'].dt.strftime('%Y-%m')
last_12 = last_12.round(0)
print(last_12.to_string(index=False))

# ── Simple Linear Forecast (Next 6 Months) ───────────────────────────────────
print(f"\n🔮 6-MONTH REVENUE FORECAST (Linear Trend)")
df['t'] = range(len(df))
coeffs = np.polyfit(df['t'], df['revenue'], 1)
slope, intercept = coeffs

last_t = df['t'].max()
last_month = df['month'].max()

forecast_rows = []
for i in range(1, 7):
    t_new = last_t + i
    future_month = last_month + pd.DateOffset(months=i)
    seasonal_factor = seasonality.get(future_month.month, 1.0)
    base_forecast = slope * t_new + intercept
    adjusted_forecast = base_forecast * seasonal_factor
    forecast_rows.append({
        'Month': future_month.strftime('%Y-%m'),
        'Base_Forecast': round(base_forecast, 0),
        'Seasonal_Adj_Forecast': round(adjusted_forecast, 0),
        'Seasonal_Factor': round(seasonal_factor, 3),
        'Lower_Bound': round(adjusted_forecast * 0.93, 0),
        'Upper_Bound': round(adjusted_forecast * 1.07, 0)
    })

forecast_df = pd.DataFrame(forecast_rows)
print(forecast_df.to_string(index=False))
print(f"\n  6-Month Forecasted Revenue: ₹{forecast_df['Seasonal_Adj_Forecast'].sum():,.0f}")
print(f"  Trend Slope (Monthly Growth): ₹{slope:,.0f}/month")

# ── Win Rate & Sales Efficiency ───────────────────────────────────────────────
print(f"\n🎯 SALES EFFICIENCY METRICS")
print(f"  Avg Win Rate      : {df['win_rate_pct'].mean():.1f}%")
print(f"  Avg Deal Size     : ₹{df['avg_deal_size'].mean():,.0f}")
print(f"  Avg Sales Cycle   : {df['sales_cycle_days'].mean():.0f} days")
print(f"  Avg New Customers/Month: {df['new_customers'].mean():.0f}")

# ── Export ────────────────────────────────────────────────────────────────────
forecast_df.to_csv(os.path.join(BASE, '../report/6month_forecast.csv'), index=False)
df[['month', 'revenue', 'MA_3M', 'MA_6M', 'MA_12M']].to_csv(
    os.path.join(BASE, '../report/trend_analysis.csv'), index=False)
print(f"\n✅ Reports exported to /report/ folder")
print("=" * 60)
