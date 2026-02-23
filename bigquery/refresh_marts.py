#!/usr/bin/env python3
"""
Star Schema Mart Refresh Script
Uses incremental loading (MERGE) for fact tables to reduce BigQuery costs
Includes campaign and geographic breakdowns
"""

from google.cloud import bigquery
import os
import logging
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText

# Configure logging
LOG_DIR = os.environ.get('LOG_DIR', '/tmp')
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'{LOG_DIR}/mart_refresh_{datetime.now().strftime("%Y%m%d")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# BigQuery setup
PROJECT_ID = 'x-victor-477214-g0'
LOCATION = 'EU'

# Incremental loading: how many days back to process
LOOKBACK_DAYS = 7

# Alert configuration
ALERT_EMAIL = os.environ.get('ALERT_EMAIL', '')
SMTP_SERVER = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.environ.get('SMTP_PORT', '587'))

# ============================================================
# DATA QUALITY TESTS
# ============================================================
QUALITY_CHECKS = {
    'fact_sessions': [
        {
            'name': 'No data for yesterday',
            'sql': """
                SELECT CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_sessions`
                WHERE date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
            """,
            'severity': 'critical'
        },
        {
            'name': 'NULL sessions detected',
            'sql': """
                SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_sessions`
                WHERE sessions IS NULL
            """,
            'severity': 'critical'
        },
        {
            'name': 'Negative users detected',
            'sql': """
                SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_sessions`
                WHERE users < 0
            """,
            'severity': 'critical'
        },
        {
            'name': 'Row count dropped significantly',
            'sql': """
                SELECT CASE WHEN COUNT(*) < 50000 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_sessions`
            """,
            'severity': 'warning'
        }
    ],
    'fact_conversions': [
        {
            'name': 'No conversion data for yesterday',
            'sql': """
                SELECT CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_conversions`
                WHERE date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
            """,
            'severity': 'critical'
        },
        {
            'name': 'NULL registrations detected',
            'sql': """
                SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_conversions`
                WHERE registrations IS NULL
            """,
            'severity': 'critical'
        }
    ],
    'dim_channel': [
        {
            'name': 'Unknown channel_type detected',
            'sql': """
                SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.dim_channel`
                WHERE channel_type IS NULL OR channel_type = ''
            """,
            'severity': 'warning'
        }
    ]
}

# ============================================================
# REFRESH QUERIES - Star Schema with Campaign + Geo
# ============================================================

DIM_REFRESH_QUERIES = {
    'dim_channel': """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.dim_channel` AS
        SELECT
          ROW_NUMBER() OVER (ORDER BY channel_group, source_clean) AS channel_key,
          source_clean,
          channel_group,
          CASE 
            WHEN channel_group IN ('Google Ads', 'Meta Ads', 'NN Ads', 'MS Network', 'Native Ads', 
                                   'Intent Ads', 'Prodigi Ads', 'Adfox Video', 'LinkedIn') THEN 'Paid'
            WHEN channel_group IN ('Google Organic', 'Bing Organic', 'Yahoo', 'Yandex') THEN 'Organic Search'
            WHEN channel_group IN ('Email', 'SMS', 'Viber', 'Telegram') THEN 'CRM'
            WHEN channel_group = 'Direct' THEN 'Direct'
            WHEN channel_group = 'Referral' THEN 'Referral'
            ELSE 'Other'
          END AS channel_type,
          CASE 
            WHEN channel_group IN ('Google Ads', 'Meta Ads', 'NN Ads', 'MS Network', 'Native Ads', 
                                   'Intent Ads', 'Prodigi Ads', 'Adfox Video', 'LinkedIn') THEN TRUE
            ELSE FALSE
          END AS is_paid,
          CASE
            WHEN source_clean = 'Google' THEN 'Google'
            WHEN source_clean = 'Meta' THEN 'Meta'
            WHEN source_clean IN ('NN Ads', 'MS Network', 'Native Ads', 'Intent Ads', 'Prodigi Ads') THEN 'Local Ad Networks'
            WHEN source_clean IN ('Email', 'SMS', 'Viber', 'Telegram') THEN 'Direct Messaging'
            WHEN source_clean IN ('Yandex', 'Bing', 'Yahoo') THEN 'Other Search'
            ELSE 'Other'
          END AS channel_category
        FROM (
          SELECT DISTINCT source_clean, channel_group
          FROM `{project}.ineco_staging.stg_events`
        )
    """
}

FACT_INCREMENTAL_QUERIES = {
    'fact_sessions': {
        'delete_recent': """
            DELETE FROM `{project}.ineco_marts.fact_sessions`
            WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {lookback} DAY)
        """,
        'insert_recent': """
            INSERT INTO `{project}.ineco_marts.fact_sessions`
            WITH session_data AS (
              SELECT
                event_date as date,
                source_clean,
                channel_group,
                COALESCE(campaign, '(not set)') as campaign,
                device_category,
                product_category,
                country,
                city,
                user_pseudo_id,
                session_id,
                CASE WHEN session_number = 1 THEN 'New' ELSE 'Returning' END as user_type,
                COUNT(CASE WHEN event_name = 'page_view' THEN 1 END) as pageviews,
                SUM(COALESCE(engagement_time_msec, 0)) / 1000.0 as engagement_sec,
                MAX(session_engaged) as session_engaged
              FROM `{project}.ineco_staging.stg_events`
              WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL {lookback} DAY)
              GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
            )
            SELECT
              date,
              source_clean,
              channel_group,
              campaign,
              device_category,
              product_category,
              country,
              city,
              user_type,
              COUNT(DISTINCT user_pseudo_id) as users,
              COUNT(DISTINCT CASE WHEN user_type = 'New' THEN user_pseudo_id END) as new_users,
              COUNT(*) as sessions,
              SUM(CASE WHEN pageviews = 1 AND engagement_sec < 10 THEN 1 ELSE 0 END) as bounced_sessions,
              SUM(pageviews) as pageviews,
              AVG(engagement_sec) as avg_session_duration_sec,
              AVG(pageviews) as avg_pages_per_session
            FROM session_data
            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
        """
    },
    'fact_conversions': {
        'delete_recent': """
            DELETE FROM `{project}.ineco_marts.fact_conversions`
            WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {lookback} DAY)
        """,
        'insert_recent': """
            INSERT INTO `{project}.ineco_marts.fact_conversions`
            SELECT
              event_date as date,
              source_clean,
              channel_group,
              COALESCE(campaign, '(not set)') as campaign,
              device_category,
              product_category,
              country,
              city,
              COUNT(DISTINCT user_pseudo_id) as total_users,
              COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING))) as total_sessions,
              COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as loans_pageview,
              COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) as loans_apply_click,
              COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) as loans_sub_id,
              COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) as loans_check_limit,
              COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_sprint' THEN user_pseudo_id END) as loans_phone_submit,
              COUNT(DISTINCT CASE WHEN event_name = 'otp_submited_sprint' THEN user_pseudo_id END) as loans_otp_submit,
              COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category IN ('Cards', 'Deposits') THEN user_pseudo_id END) as cards_deposits_pageview,
              COUNT(DISTINCT CASE WHEN event_name IN ('reg_apply_button_click', 'cards_apply_button', 'apply_button_click') THEN user_pseudo_id END) as cards_deposits_apply_click,
              COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID' THEN user_pseudo_id END) as cards_deposits_sub_id,
              COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_reg' THEN user_pseudo_id END) as cards_deposits_phone_submit,
              COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) as registrations
            FROM `{project}.ineco_staging.stg_events`
            WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL {lookback} DAY)
            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
        """
    }
}

FULL_REBUILD_QUERIES = {
    'fact_sessions': """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.fact_sessions`
        PARTITION BY date
        CLUSTER BY channel_group, product_category
        AS
        WITH session_data AS (
          SELECT
            event_date as date,
            source_clean,
            channel_group,
            COALESCE(campaign, '(not set)') as campaign,
            device_category,
            product_category,
            country,
            city,
            user_pseudo_id,
            session_id,
            CASE WHEN session_number = 1 THEN 'New' ELSE 'Returning' END as user_type,
            COUNT(CASE WHEN event_name = 'page_view' THEN 1 END) as pageviews,
            SUM(COALESCE(engagement_time_msec, 0)) / 1000.0 as engagement_sec,
            MAX(session_engaged) as session_engaged
          FROM `{project}.ineco_staging.stg_events`
          GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
        )
        SELECT
          date,
          source_clean,
          channel_group,
          campaign,
          device_category,
          product_category,
          country,
          city,
          user_type,
          COUNT(DISTINCT user_pseudo_id) as users,
          COUNT(DISTINCT CASE WHEN user_type = 'New' THEN user_pseudo_id END) as new_users,
          COUNT(*) as sessions,
          SUM(CASE WHEN pageviews = 1 AND engagement_sec < 10 THEN 1 ELSE 0 END) as bounced_sessions,
          SUM(pageviews) as pageviews,
          AVG(engagement_sec) as avg_session_duration_sec,
          AVG(pageviews) as avg_pages_per_session
        FROM session_data
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
    """,
    'fact_conversions': """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.fact_conversions`
        PARTITION BY date
        CLUSTER BY channel_group, product_category
        AS
        SELECT
          event_date as date,
          source_clean,
          channel_group,
          COALESCE(campaign, '(not set)') as campaign,
          device_category,
          product_category,
          country,
          city,
          COUNT(DISTINCT user_pseudo_id) as total_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING))) as total_sessions,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as loans_pageview,
          COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) as loans_apply_click,
          COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) as loans_sub_id,
          COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) as loans_check_limit,
          COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_sprint' THEN user_pseudo_id END) as loans_phone_submit,
          COUNT(DISTINCT CASE WHEN event_name = 'otp_submited_sprint' THEN user_pseudo_id END) as loans_otp_submit,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category IN ('Cards', 'Deposits') THEN user_pseudo_id END) as cards_deposits_pageview,
          COUNT(DISTINCT CASE WHEN event_name IN ('reg_apply_button_click', 'cards_apply_button', 'apply_button_click') THEN user_pseudo_id END) as cards_deposits_apply_click,
          COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID' THEN user_pseudo_id END) as cards_deposits_sub_id,
          COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_reg' THEN user_pseudo_id END) as cards_deposits_phone_submit,
          COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) as registrations
        FROM `{project}.ineco_staging.stg_events`
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
    """
}


def send_alert(subject: str, body: str):
    """Send email alert for data quality issues."""
    if not ALERT_EMAIL:
        logger.warning(f"Alert not sent (no email configured): {subject}")
        return
    try:
        msg = MIMEText(body)
        msg['Subject'] = f"[Ineco Analytics] {subject}"
        msg['From'] = ALERT_EMAIL
        msg['To'] = ALERT_EMAIL
        logger.info(f"Would send alert: {subject}")
    except Exception as e:
        logger.error(f"Failed to send alert: {e}")


def run_quality_checks(client: bigquery.Client) -> dict:
    """Run all data quality checks and return results."""
    results = {
        'passed': 0, 'failed': 0, 'warnings': 0,
        'critical_failures': [], 'warnings_list': []
    }
    
    logger.info("=" * 60)
    logger.info("Running Data Quality Checks")
    logger.info("=" * 60)
    
    for table, checks in QUALITY_CHECKS.items():
        for check in checks:
            try:
                sql = check['sql'].format(project=PROJECT_ID)
                result = list(client.query(sql).result())[0]
                failed = result.failed == 1
                
                if failed:
                    if check['severity'] == 'critical':
                        results['failed'] += 1
                        results['critical_failures'].append(f"{table}: {check['name']}")
                        logger.error(f"  ✗ CRITICAL: {table}.{check['name']}")
                    else:
                        results['warnings'] += 1
                        results['warnings_list'].append(f"{table}: {check['name']}")
                        logger.warning(f"  ⚠ WARNING: {table}.{check['name']}")
                else:
                    results['passed'] += 1
                    logger.info(f"  ✓ PASSED: {table}.{check['name']}")
            except Exception as e:
                logger.error(f"  ✗ ERROR: {table}.{check['name']}: {e}")
                results['failed'] += 1
    
    return results


def table_exists(client: bigquery.Client, table_name: str) -> bool:
    try:
        client.get_table(f"{PROJECT_ID}.ineco_marts.{table_name}")
        return True
    except Exception:
        return False


def get_table_row_count(client: bigquery.Client, table_name: str) -> int:
    try:
        sql = f"SELECT COUNT(*) as cnt FROM `{PROJECT_ID}.ineco_marts.{table_name}`"
        return list(client.query(sql).result())[0].cnt
    except Exception:
        return 0


def refresh_marts(full_rebuild: bool = False):
    creds_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', 
                                '/home/harut/superset/credentials/bigquery-service-account.json')
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = creds_path
    
    client = bigquery.Client(project=PROJECT_ID, location=LOCATION)
    
    logger.info("=" * 60)
    logger.info(f"Starting Mart Refresh - {datetime.now()}")
    logger.info(f"Mode: {'FULL REBUILD' if full_rebuild else f'INCREMENTAL (last {LOOKBACK_DAYS} days)'}")
    logger.info("=" * 60)
    
    success_count = 0
    error_count = 0
    bytes_processed = 0
    
    # Refresh dimensions
    logger.info("\n--- Dimension Tables ---")
    for dim_name, query in DIM_REFRESH_QUERIES.items():
        try:
            logger.info(f"Refreshing {dim_name}...")
            sql = query.format(project=PROJECT_ID)
            job = client.query(sql)
            job.result()
            row_count = get_table_row_count(client, dim_name)
            bytes_processed += job.total_bytes_processed or 0
            logger.info(f"  ✓ {dim_name}: {row_count:,} rows")
            success_count += 1
        except Exception as e:
            logger.error(f"  ✗ {dim_name}: {str(e)}")
            error_count += 1
    
    # Refresh facts
    logger.info("\n--- Fact Tables ---")
    for fact_name in FACT_INCREMENTAL_QUERIES.keys():
        try:
            exists = table_exists(client, fact_name)
            
            if not exists or full_rebuild:
                logger.info(f"Rebuilding {fact_name} (full)...")
                sql = FULL_REBUILD_QUERIES[fact_name].format(project=PROJECT_ID)
                job = client.query(sql)
                job.result()
                bytes_processed += job.total_bytes_processed or 0
            else:
                logger.info(f"Refreshing {fact_name} (incremental, last {LOOKBACK_DAYS} days)...")
                
                delete_sql = FACT_INCREMENTAL_QUERIES[fact_name]['delete_recent'].format(
                    project=PROJECT_ID, lookback=LOOKBACK_DAYS)
                delete_job = client.query(delete_sql)
                delete_job.result()
                deleted_rows = delete_job.num_dml_affected_rows or 0
                
                insert_sql = FACT_INCREMENTAL_QUERIES[fact_name]['insert_recent'].format(
                    project=PROJECT_ID, lookback=LOOKBACK_DAYS)
                insert_job = client.query(insert_sql)
                insert_job.result()
                inserted_rows = insert_job.num_dml_affected_rows or 0
                bytes_processed += insert_job.total_bytes_processed or 0
                
                logger.info(f"  Deleted {deleted_rows:,} old rows, inserted {inserted_rows:,} new rows")
            
            row_count = get_table_row_count(client, fact_name)
            logger.info(f"  ✓ {fact_name}: {row_count:,} total rows")
            success_count += 1
        except Exception as e:
            logger.error(f"  ✗ {fact_name}: {str(e)}")
            error_count += 1
    
    # Refresh Ad Spend (Google Ads + Facebook)
    logger.info("\n--- Ad Spend Tables ---")
    try:
        # Google Ads mart
        logger.info("Refreshing fact_ad_spend_google...")
        google_ads_sql = """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.fact_ad_spend_google` AS
        SELECT
          _DATA_DATE as date,
          'Google Ads' as channel_group,
          campaign_name as campaign,
          ad_group_name as ad_group,
          CAST(impressions AS FLOAT64) as impressions,
          CAST(clicks AS FLOAT64) as clicks,
          CAST(cost_micros AS FLOAT64) / 1000000 as spend_usd,
          (CAST(cost_micros AS FLOAT64) / 1000000) * 400 as spend_amd,
          SAFE_DIVIDE(CAST(clicks AS FLOAT64), CAST(impressions AS FLOAT64)) * 100 as ctr,
          SAFE_DIVIDE(CAST(cost_micros AS FLOAT64) / 1000000, CAST(clicks AS FLOAT64)) as cpc,
          SAFE_DIVIDE(CAST(cost_micros AS FLOAT64) / 1000000, CAST(impressions AS FLOAT64)) * 1000 as cpm,
          CAST(conversions AS FLOAT64) as conversions,
          SAFE_DIVIDE(CAST(cost_micros AS FLOAT64) / 1000000, NULLIF(CAST(conversions AS FLOAT64), 0)) as cost_per_conversion
        FROM `{project}.ineco_raw.p_ads_CampaignStats_8656917454`
        WHERE _DATA_DATE IS NOT NULL
        """.format(project=PROJECT_ID)
        job = client.query(google_ads_sql)
        job.result()
        google_rows = get_table_row_count(client, 'fact_ad_spend_google')
        logger.info(f"  ✓ fact_ad_spend_google: {google_rows:,} rows")
        
        # Unified ad spend
        logger.info("Refreshing fact_ad_spend (unified)...")
        unified_sql = """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.fact_ad_spend` AS
        SELECT date, channel_group, campaign, ad_group, impressions, clicks,
               spend_usd, spend_amd, ctr, cpc, cpm, conversions, cost_per_conversion
        FROM `{project}.ineco_marts.fact_ad_spend_google`
        WHERE date IS NOT NULL
        UNION ALL
        SELECT 
          DATE(date_start) as date,
          'Meta Ads' as channel_group,
          campaign_name as campaign,
          adset_name as ad_group,
          CAST(impressions AS FLOAT64),
          CAST(clicks AS FLOAT64),
          CAST(spend AS FLOAT64),
          CAST(spend AS FLOAT64) * 400,
          SAFE_DIVIDE(CAST(clicks AS FLOAT64), CAST(impressions AS FLOAT64)) * 100,
          SAFE_DIVIDE(CAST(spend AS FLOAT64), CAST(clicks AS FLOAT64)),
          SAFE_DIVIDE(CAST(spend AS FLOAT64), CAST(impressions AS FLOAT64)) * 1000,
          0, 0
        FROM `{project}.ineco_raw.ads_insights`
        WHERE date_start IS NOT NULL
        """.format(project=PROJECT_ID)
        job = client.query(unified_sql)
        job.result()
        unified_rows = get_table_row_count(client, 'fact_ad_spend')
        logger.info(f"  ✓ fact_ad_spend: {unified_rows:,} rows")
        success_count += 2
    except Exception as e:
        logger.warning(f"  ⚠ Ad spend tables: {str(e)} (may be no data yet)")

    # Refresh Funnel Tables
    logger.info("\n--- Funnel Tables ---")
    try:
        # Loans Funnel (8 steps matching CSV)
        logger.info("Refreshing funnel_loans...")
        loans_sql = """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.funnel_loans`
        PARTITION BY date CLUSTER BY channel_group AS
        SELECT
          event_date as date, channel_group, COALESCE(campaign, '(not set)') as campaign, device_category,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as step1_pageview,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_apply_click' THEN user_pseudo_id END) as step2_apply_click,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_sub_id_captured' THEN user_pseudo_id END) as step3_sub_id_captured,
          COUNT(DISTINCT CASE WHEN event_name_clean IN ('sprint_phone_submitted', 'sprint_login_via_mobile') THEN user_pseudo_id END) as step4_phone_login,
          COUNT(DISTINCT CASE WHEN event_name IN ('sprint_login_success', 'sprint_login_mobile_success') THEN user_pseudo_id END) as step5_login_success,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_ssn_submitted' THEN user_pseudo_id END) as step6_ssn_submitted,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_check_limit_click' THEN user_pseudo_id END) as step7_check_limit_click,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_check_limit_completed' AND NOT is_test_event THEN user_pseudo_id END) as step8_completed
        FROM `{project}.ineco_staging.stg_events_clean`
        WHERE product_category = 'Consumer Loans' OR flow_type = 'Sprint'
        GROUP BY 1, 2, 3, 4
        """.format(project=PROJECT_ID)
        job = client.query(loans_sql)
        job.result()
        logger.info(f"  ✓ funnel_loans: {get_table_row_count(client, 'funnel_loans'):,} rows")

        # Registration Funnel (10 steps matching CSV)
        logger.info("Refreshing funnel_registration...")
        reg_sql = """
        CREATE OR REPLACE TABLE `{project}.ineco_marts.funnel_registration`
        PARTITION BY date CLUSTER BY channel_group, product_category AS
        SELECT
          event_date as date, channel_group, COALESCE(campaign, '(not set)') as campaign, product_category, device_category,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category IN ('Cards', 'Deposits') THEN user_pseudo_id END) as step1_pageview,
          COUNT(DISTINCT CASE WHEN event_name_clean IN ('reg_apply_click', 'cards_apply_click') THEN user_pseudo_id END) as step2_apply_click,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_sub_id_captured' THEN user_pseudo_id END) as step3_sub_id_captured,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_phone_submitted' THEN user_pseudo_id END) as step4_phone_submitted,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_ssn_submitted' THEN user_pseudo_id END) as step5_ssn_submitted,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_email_verified' THEN user_pseudo_id END) as step6_email_verified,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'kyc_started' THEN user_pseudo_id END) as step7_kyc_started,
          COUNT(DISTINCT CASE WHEN event_name = 'kyc_qr_shown' THEN user_pseudo_id END) as step8_kyc_qr_shown,
          COUNT(DISTINCT CASE WHEN event_name = 'kyc_qr_scanned' THEN user_pseudo_id END) as step9_kyc_qr_scanned,
          COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_completed' THEN user_pseudo_id END) as step10_completed
        FROM `{project}.ineco_staging.stg_events_clean`
        WHERE product_category IN ('Cards', 'Deposits', 'Homepage') OR flow_type = 'Registration'
        GROUP BY 1, 2, 3, 4, 5
        """.format(project=PROJECT_ID)
        job = client.query(reg_sql)
        job.result()
        logger.info(f"  ✓ funnel_registration: {get_table_row_count(client, 'funnel_registration'):,} rows")
        success_count += 2
    except Exception as e:
        logger.warning(f"  ⚠ Funnel tables: {str(e)}")

    # Quality checks
    qc_results = run_quality_checks(client)
    
    # Summary
    gb_processed = bytes_processed / (1024**3)
    estimated_cost = gb_processed * 5 / 1000
    
    logger.info("\n" + "=" * 60)
    logger.info("REFRESH SUMMARY")
    logger.info("=" * 60)
    logger.info(f"Tables refreshed: {success_count} succeeded, {error_count} failed")
    logger.info(f"Data processed: {gb_processed:.2f} GB (~${estimated_cost:.4f})")
    logger.info(f"Quality checks: {qc_results['passed']} passed, {qc_results['failed']} failed, {qc_results['warnings']} warnings")
    
    if qc_results['critical_failures']:
        alert_body = f"Critical issues: {qc_results['critical_failures']}"
        send_alert("⚠️ Data Quality Check FAILED", alert_body)
        logger.error("CRITICAL: Data quality checks failed!")
    else:
        logger.info("All quality checks passed!")
    
    logger.info("=" * 60)
    return error_count == 0 and qc_results['failed'] == 0


if __name__ == '__main__':
    import sys
    full_rebuild = '--full' in sys.argv
    print(f"Running {'FULL REBUILD' if full_rebuild else 'INCREMENTAL'} refresh...")
    success = refresh_marts(full_rebuild=full_rebuild)
    exit(0 if success else 1)
