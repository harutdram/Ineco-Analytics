#!/usr/bin/env python3
"""
Load Bank Conversion Data from CSV to BigQuery

Handles:
- Duplicate detection
- Incremental loading (MERGE)
- Data validation
- Automatic mart refresh

Usage:
    python3 load_bank_data.py /path/to/bank_conversions.csv
"""

import os
import sys
import pandas as pd
from datetime import datetime
from google.cloud import bigquery

# Configuration
PROJECT_ID = 'x-victor-477214-g0'
CREDENTIALS_PATH = '/Users/harut/Desktop/Ineco/credentials/bigquery-service-account.json'

# Table names
RAW_TABLE = f'{PROJECT_ID}.ineco_raw.bank_conversions'
STAGING_TABLE = f'{PROJECT_ID}.ineco_staging.stg_bank_conversions'
MART_TABLE = f'{PROJECT_ID}.ineco_marts.fact_bank_conversions'


def safe_int(x):
    """Convert to int, handling errors"""
    try:
        return int(x)
    except:
        return 0


def load_csv(file_path: str) -> pd.DataFrame:
    """Load and validate CSV file"""
    print(f"📂 Loading file: {file_path}")
    
    # Try different encodings
    for encoding in ['utf-8', 'cp1251', 'latin1']:
        try:
            df = pd.read_csv(file_path, encoding=encoding)
            break
        except:
            continue
    else:
        # Try Excel
        df = pd.read_excel(file_path)
    
    print(f"   Rows: {len(df):,}")
    print(f"   Columns: {len(df.columns)}")
    
    # Validate required columns
    required = ['Event _date', 'Client_code', 'LOAN_COUNT', 'CARD_COUNT']
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")
    
    return df


def transform_data(df: pd.DataFrame) -> pd.DataFrame:
    """Transform to match BigQuery schema"""
    print("🔄 Transforming data...")
    
    df_clean = pd.DataFrame({
        'event_time_raw': df.get('Event Time', '').astype(str),
        'event_date': pd.to_datetime(df['Event _date']).dt.date,
        'event_name': df.get('Event Name', '').astype(str),
        'token_id': df.get('Event Param Value (String)', '').astype(str),
        'acquired_source': df.get('Acquired Source', '').astype(str),
        'acquired_medium': df.get('Acquired Medium', '').astype(str),
        'acquired_campaign': df.get('Acquired Campaign', '').astype(str),
        'client_code': df['Client_code'].astype(str),
        'soc_card': df.get('Soc_card', '').astype(str),
        'count_soc_card': df.get('count_soc_card', 0).apply(safe_int),
        'had_product': df.get('HAD_PRODUCT', '').astype(str),
        'is_first_interaction': df.get('1-st/2-nd', 0).apply(safe_int),
        'loan_count': df['LOAN_COUNT'].fillna(0).apply(safe_int),
        'loan_amount': pd.to_numeric(df.get('LOAN_AMOUNT', 0), errors='coerce').fillna(0),
        'deposit_count': df.get('DEPOSIT_COUNT', 0).fillna(0).apply(safe_int),
        'deposit_amount': pd.to_numeric(df.get('DEPOSIT_AMOUNT', 0), errors='coerce').fillna(0),
        'card_count': df.get('CARD_COUNT', 0).fillna(0).apply(safe_int),
        'uploaded_at': datetime.now()
    })
    
    return df_clean


def get_existing_count(client: bigquery.Client) -> int:
    """Get current row count in raw table"""
    query = f"SELECT COUNT(*) as cnt FROM `{RAW_TABLE}`"
    try:
        return list(client.query(query).result())[0].cnt
    except:
        return 0


def load_to_bigquery(df: pd.DataFrame, client: bigquery.Client):
    """Load data to BigQuery with deduplication"""
    
    # Check for existing data
    existing_count = get_existing_count(client)
    print(f"📊 Existing rows in raw table: {existing_count:,}")
    
    # Create temp table for new data
    temp_table = f'{PROJECT_ID}.ineco_raw._temp_bank_load'
    
    print(f"⬆️  Uploading {len(df):,} rows to temp table...")
    job_config = bigquery.LoadJobConfig(write_disposition="WRITE_TRUNCATE")
    client.load_table_from_dataframe(df, temp_table, job_config=job_config).result()
    
    # Merge into raw table (deduplicate)
    print("🔀 Merging with deduplication...")
    merge_sql = f"""
    MERGE `{RAW_TABLE}` target
    USING `{temp_table}` source
    ON target.token_id = source.token_id 
       AND target.client_code = source.client_code
       AND target.event_date = source.event_date
    WHEN MATCHED THEN
        UPDATE SET
            loan_count = source.loan_count,
            loan_amount = source.loan_amount,
            deposit_count = source.deposit_count,
            deposit_amount = source.deposit_amount,
            card_count = source.card_count,
            uploaded_at = source.uploaded_at
    WHEN NOT MATCHED THEN
        INSERT ROW
    """
    client.query(merge_sql).result()
    
    # Get new count
    new_count = get_existing_count(client)
    added = new_count - existing_count
    updated = len(df) - added
    
    print(f"✅ Results:")
    print(f"   New rows added: {added:,}")
    print(f"   Existing rows updated: {updated:,}")
    print(f"   Total rows now: {new_count:,}")
    
    # Clean up temp table
    client.delete_table(temp_table, not_found_ok=True)
    
    return added, updated


def refresh_staging(client: bigquery.Client):
    """Refresh staging table with clean data"""
    print("🔄 Refreshing staging table...")
    
    sql = f"""
    CREATE OR REPLACE TABLE `{STAGING_TABLE}` AS
    SELECT DISTINCT *
    FROM `{RAW_TABLE}`
    WHERE token_id IS NOT NULL
      AND client_code IS NOT NULL
    """
    client.query(sql).result()
    
    count = list(client.query(f"SELECT COUNT(*) as cnt FROM `{STAGING_TABLE}`").result())[0].cnt
    print(f"   Staging rows: {count:,}")


def refresh_mart(client: bigquery.Client):
    """Refresh mart table with channel mapping"""
    print("🔄 Refreshing mart table...")
    
    sql = f"""
    CREATE OR REPLACE TABLE `{MART_TABLE}` AS
    SELECT
        event_date as date,
        CASE 
            WHEN LOWER(acquired_source) LIKE '%meta%' OR LOWER(acquired_source) LIKE 'facebook%' THEN 'Meta Ads'
            WHEN LOWER(acquired_source) = 'google' AND LOWER(acquired_medium) = 'cpc' THEN 'Google Ads'
            WHEN LOWER(acquired_source) LIKE '%nn_ads%' OR LOWER(acquired_source) LIKE '%nn ads%' THEN 'NN Ads'
            WHEN LOWER(acquired_source) = 'sfmc' OR LOWER(acquired_medium) = 'email' THEN 'Email'
            WHEN LOWER(acquired_source) = 'sms' OR LOWER(acquired_medium) LIKE '%sms%' THEN 'SMS'
            WHEN LOWER(acquired_source) LIKE '%viber%' THEN 'Viber'
            WHEN LOWER(acquired_source) LIKE '%telegram%' THEN 'Telegram'
            WHEN LOWER(acquired_medium) = 'referral' THEN 'Referral'
            WHEN LOWER(acquired_source) = 'landing' THEN 'Direct'
            WHEN LOWER(acquired_source) LIKE '%yandex%' THEN 'Yandex'
            WHEN LOWER(acquired_source) LIKE '%native%' THEN 'Native Ads'
            WHEN LOWER(acquired_source) LIKE '%intent%' THEN 'Intent Ads'
            WHEN LOWER(acquired_source) LIKE '%prodigi%' THEN 'Prodigi Ads'
            WHEN LOWER(acquired_source) LIKE '%ms_network%' THEN 'MS Network'
            ELSE 'Other'
        END as channel_group,
        CASE 
            WHEN loan_count > 0 THEN 'Loans'
            WHEN card_count > 0 THEN 'Cards'
            WHEN deposit_count > 0 THEN 'Deposits'
            ELSE 'Other'
        END as product_category,
        acquired_source,
        acquired_medium,
        acquired_campaign,
        had_product as is_existing_customer,
        is_first_interaction,
        loan_count,
        loan_amount,
        deposit_count,
        deposit_amount,
        card_count,
        loan_amount + deposit_amount as total_revenue_amd
    FROM `{STAGING_TABLE}`
    """
    client.query(sql).result()
    
    count = list(client.query(f"SELECT COUNT(*) as cnt FROM `{MART_TABLE}`").result())[0].cnt
    print(f"   Mart rows: {count:,}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 load_bank_data.py <csv_file_path>")
        print("Example: python3 load_bank_data.py /path/to/bank_conversions.csv")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        sys.exit(1)
    
    # Setup BigQuery client
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
    client = bigquery.Client(project=PROJECT_ID, location='EU')
    
    print("=" * 60)
    print("BANK CONVERSION DATA LOADER")
    print("=" * 60)
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Load and transform
    df = load_csv(file_path)
    df_clean = transform_data(df)
    
    # Load to BigQuery
    added, updated = load_to_bigquery(df_clean, client)
    
    # Refresh downstream tables
    refresh_staging(client)
    refresh_mart(client)
    
    print()
    print("=" * 60)
    print("✅ COMPLETE!")
    print("=" * 60)
    
    # Summary
    query = f"""
    SELECT 
        SUM(loan_count) as loans,
        SUM(card_count) as cards,
        SUM(deposit_count) as deposits,
        ROUND(SUM(loan_amount + deposit_amount)) as total_revenue
    FROM `{MART_TABLE}`
    """
    stats = list(client.query(query).result())[0]
    print(f"\n📊 Current Totals:")
    print(f"   Loans: {stats.loans}")
    print(f"   Cards: {stats.cards}")
    print(f"   Deposits: {stats.deposits}")
    print(f"   Total Revenue: {stats.total_revenue:,.0f} AMD")


if __name__ == '__main__':
    main()
