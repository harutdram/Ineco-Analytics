---
name: data-quality
description: Run data quality tests on Ineco BigQuery tables. Use when the user asks to check data quality, verify data, validate tables, or troubleshoot data issues.
---

# Data Quality Tests

## Quick Start

Run all data quality checks:

```bash
cd /Users/harut/Desktop/Ineco
python scripts/data_quality_tests.py
```

## What Gets Checked

| Test | Description |
|------|-------------|
| Row counts | Tables have expected minimum rows |
| Null values | Critical columns have no nulls |
| Data freshness | Data is recent (within 2 days) |
| Value ranges | No negative values where inappropriate |
| Consistency | Channel groups match across tables |
| Duplicates | No duplicate records |

## Quick BigQuery Checks

Check table row counts:
```python
from google.cloud import bigquery
client = bigquery.Client(project='x-victor-477214-g0')

tables = ['fact_sessions', 'fact_conversions', 'fact_bank_conversions', 'fact_ad_spend']
for t in tables:
    sql = f"SELECT COUNT(*) as cnt FROM `x-victor-477214-g0.ineco_marts.{t}`"
    result = list(client.query(sql).result())[0]
    print(f"{t}: {result.cnt:,} rows")
```

Check data freshness:
```sql
SELECT table_name, MAX(date) as latest_date
FROM (
  SELECT 'fact_sessions' as table_name, MAX(date) as date FROM `ineco_marts.fact_sessions`
  UNION ALL
  SELECT 'fact_conversions', MAX(date) FROM `ineco_marts.fact_conversions`
)
GROUP BY 1
```

## Exit Codes

- `0` = All tests passed
- `1` = One or more tests failed
