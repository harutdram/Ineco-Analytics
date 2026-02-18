---
name: load-bank-data
description: Load Ineco bank conversion data from CSV/Excel files into BigQuery. Use when the user wants to load bank data, import conversions, upload Excel/CSV data, or update bank_conversions table.
---

# Load Bank Conversion Data

## Quick Start

Load a CSV or Excel file:

```bash
cd /Users/harut/Desktop/Ineco
python scripts/load_bank_data.py path/to/data_ineco.csv
# or
python scripts/load_bank_data.py path/to/data_ineco.xlsx
```

## Expected File Format

The file should have these columns (order doesn't matter):

| Column | Type | Description |
|--------|------|-------------|
| event_date | Date | Transaction date |
| client_code | String | Unique customer ID |
| product_category | String | Loan, Card, Deposit |
| acquired_source | String | Traffic source |
| acquired_medium | String | Medium (cpc, organic) |
| acquired_campaign | String | Campaign name |
| is_existing_customer | Boolean | Existing customer flag |
| loan_amount | Number | Loan amount (AMD) |
| deposit_amount | Number | Deposit amount (AMD) |

## What Happens

1. File is parsed (CSV or Excel)
2. Data is validated
3. Loaded to `ineco_raw.bank_conversions` (with deduplication)
4. Staging table `stg_bank_conversions` is refreshed
5. Mart table `fact_bank_conversions` is updated

## After Loading

Verify the data:
```bash
python scripts/data_quality_tests.py
```

Check row counts in BigQuery:
```sql
SELECT COUNT(*) FROM `x-victor-477214-g0.ineco_raw.bank_conversions`
SELECT COUNT(*) FROM `x-victor-477214-g0.ineco_marts.fact_bank_conversions`
```
