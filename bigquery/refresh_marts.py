#!/usr/bin/env python3
"""
Star Schema Mart Refresh Script
Refreshes fact tables daily with data quality checks
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

# Alert configuration (update with your email settings)
ALERT_EMAIL = os.environ.get('ALERT_EMAIL', '')  # Set in environment
SMTP_SERVER = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.environ.get('SMTP_PORT', '587'))

# ============================================================
# DATA QUALITY TESTS
# ============================================================
QUALITY_CHECKS = {
    'fact_sessions': [
        {
            'name': 'No data for today',
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
                SELECT CASE WHEN COUNT(*) < 20000 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_sessions`
            """,
            'severity': 'warning'
        },
        {
            'name': 'Sessions exceed users (data integrity)',
            'sql': """
                SELECT CASE WHEN SUM(CASE WHEN sessions < users THEN 1 ELSE 0 END) > 100 THEN 1 ELSE 0 END as failed
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
        },
        {
            'name': 'Registrations exceed sessions (impossible)',
            'sql': """
                SELECT CASE WHEN SUM(CASE WHEN registrations > total_sessions THEN 1 ELSE 0 END) > 10 THEN 1 ELSE 0 END as failed
                FROM `{project}.ineco_marts.fact_conversions`
            """,
            'severity': 'warning'
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
# REFRESH QUERIES - Star Schema
# ============================================================
REFRESH_QUERIES = {
    # Dimensions (refresh to pick up new channels)
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
    """,
    
    # Fact tables (refresh daily)
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
            device_category,
            product_category,
            user_pseudo_id,
            session_id,
            CASE WHEN session_number = 1 THEN 'New' ELSE 'Returning' END as user_type,
            COUNT(CASE WHEN event_name = 'page_view' THEN 1 END) as pageviews,
            SUM(COALESCE(engagement_time_msec, 0)) / 1000.0 as engagement_sec,
            MAX(session_engaged) as session_engaged
          FROM `{project}.ineco_staging.stg_events`
          GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
        )
        SELECT
          date,
          source_clean,
          channel_group,
          device_category,
          product_category,
          user_type,
          COUNT(DISTINCT user_pseudo_id) as users,
          COUNT(DISTINCT CASE WHEN user_type = 'New' THEN user_pseudo_id END) as new_users,
          COUNT(*) as sessions,
          SUM(CASE WHEN pageviews = 1 AND engagement_sec < 10 THEN 1 ELSE 0 END) as bounced_sessions,
          SUM(pageviews) as pageviews,
          AVG(engagement_sec) as avg_session_duration_sec,
          AVG(pageviews) as avg_pages_per_session
        FROM session_data
        GROUP BY 1, 2, 3, 4, 5, 6
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
          device_category,
          product_category,
          COUNT(DISTINCT user_pseudo_id) as total_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING))) as total_sessions,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as loans_pageview,
          COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) as loans_apply_click,
          COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) as loans_sub_id,
          COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) as loans_check_limit,
          COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_sprint' THEN user_pseudo_id END) as loans_phone_submit,
          COUNT(DISTINCT CASE WHEN event_name = 'otp_submited_sprint' THEN user_pseudo_id END) as loans_otp_submit,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category IN ('Cards', 'Deposits') THEN user_pseudo_id END) as cards_deposits_pageview,
          COUNT(DISTINCT CASE WHEN event_name = 'Reg_apply_button_click' THEN user_pseudo_id END) as cards_deposits_apply_click,
          COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID' THEN user_pseudo_id END) as cards_deposits_sub_id,
          COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) as registrations
        FROM `{project}.ineco_staging.stg_events`
        GROUP BY 1, 2, 3, 4, 5
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
        
        # Note: For production, use proper SMTP credentials
        logger.info(f"Would send alert: {subject}")
        # with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        #     server.starttls()
        #     server.login(ALERT_EMAIL, os.environ.get('SMTP_PASSWORD', ''))
        #     server.send_message(msg)
    except Exception as e:
        logger.error(f"Failed to send alert: {e}")


def run_quality_checks(client: bigquery.Client) -> dict:
    """Run all data quality checks and return results."""
    results = {
        'passed': 0,
        'failed': 0,
        'warnings': 0,
        'critical_failures': [],
        'warnings_list': []
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
                logger.error(f"  ✗ ERROR running check {table}.{check['name']}: {e}")
                results['failed'] += 1
    
    return results


def refresh_marts():
    """Refresh all mart tables with quality checks."""
    creds_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', 
                                '/home/harut/superset/credentials/bigquery-service-account.json')
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = creds_path
    
    client = bigquery.Client(project=PROJECT_ID, location=LOCATION)
    
    logger.info("=" * 60)
    logger.info(f"Starting Star Schema Mart Refresh - {datetime.now()}")
    logger.info("=" * 60)
    
    success_count = 0
    error_count = 0
    
    # Refresh tables
    for mart_name, query in REFRESH_QUERIES.items():
        try:
            logger.info(f"Refreshing {mart_name}...")
            sql = query.format(project=PROJECT_ID)
            job = client.query(sql)
            job.result()  # Wait for completion
            
            # Get row count
            count_query = f"SELECT COUNT(*) as cnt FROM `{PROJECT_ID}.ineco_marts.{mart_name}`"
            row_count = list(client.query(count_query).result())[0].cnt
            
            logger.info(f"  ✓ {mart_name}: {row_count:,} rows")
            success_count += 1
            
        except Exception as e:
            logger.error(f"  ✗ {mart_name}: {str(e)}")
            error_count += 1
    
    # Run quality checks
    qc_results = run_quality_checks(client)
    
    # Summary
    logger.info("=" * 60)
    logger.info("REFRESH SUMMARY")
    logger.info("=" * 60)
    logger.info(f"Tables refreshed: {success_count} succeeded, {error_count} failed")
    logger.info(f"Quality checks: {qc_results['passed']} passed, {qc_results['failed']} failed, {qc_results['warnings']} warnings")
    
    # Send alerts for critical failures
    if qc_results['critical_failures']:
        alert_body = f"""
Data Quality Check FAILED

Critical issues detected:
{chr(10).join('- ' + f for f in qc_results['critical_failures'])}

Warnings:
{chr(10).join('- ' + w for w in qc_results['warnings_list']) if qc_results['warnings_list'] else '- None'}

Time: {datetime.now()}
        """
        send_alert("⚠️ Data Quality Check FAILED", alert_body)
        logger.error("CRITICAL: Data quality checks failed!")
    elif qc_results['warnings_list']:
        logger.warning(f"Warnings detected: {qc_results['warnings_list']}")
    else:
        logger.info("All quality checks passed!")
    
    logger.info("=" * 60)
    
    return error_count == 0 and qc_results['failed'] == 0


if __name__ == '__main__':
    success = refresh_marts()
    exit(0 if success else 1)
