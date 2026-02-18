---
name: refresh-marts
description: Refresh BigQuery mart tables for Ineco analytics. Use when the user asks to refresh data, update marts, sync BigQuery, or run the data pipeline.
---

# Refresh BigQuery Marts

## Quick Start

Run the mart refresh script:

```bash
cd /Users/harut/Desktop/Ineco
python bigquery/refresh_marts.py
```

For full rebuild (slower, reprocesses all data):
```bash
python bigquery/refresh_marts.py --full
```

## What Gets Refreshed

| Table | Type | Method |
|-------|------|--------|
| `dim_channel` | Dimension | Full replace |
| `dim_date` | Dimension | Full replace |
| `fact_sessions` | Fact | Incremental (last 7 days) |
| `fact_conversions` | Fact | Incremental (last 7 days) |
| `fact_ad_spend_google` | Fact | Full replace |
| `fact_ad_spend` | Fact | Full replace |

## On the VM (Production)

```bash
ssh harut@34.66.133.243
cd /home/harut/superset
python bigquery/refresh_marts.py
```

## Verify Success

After refresh, check row counts:
```bash
python scripts/data_quality_tests.py
```

## Troubleshooting

If refresh fails:
1. Check credentials: `ls credentials/bigquery-service-account.json`
2. Check BigQuery permissions
3. Review logs in `/tmp/mart_refresh_*.log`
