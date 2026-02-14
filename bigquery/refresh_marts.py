#!/usr/bin/env python3
"""
BigQuery Mart Refresh Script with Alerting
Runs daily via cron to refresh all mart tables
Logs failures and sends alerts
"""
from google.cloud import bigquery
import os
import json
from datetime import datetime
import logging

# Configuration
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/home/harut/superset/credentials/bigquery-service-account.json'
PROJECT = 'x-victor-477214-g0'
LOG_FILE = '/home/harut/superset/logs/mart_refresh.log'
STATUS_FILE = '/home/harut/superset/logs/mart_status.json'

# Ensure log directory exists
os.makedirs('/home/harut/superset/logs', exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

client = bigquery.Client(project=PROJECT, location='EU')

def run_query(name, sql):
    logger.info(f'Refreshing {name}...')
    try:
        job = client.query(sql)
        job.result()
        logger.info(f'SUCCESS: {name} completed')
        return {'name': name, 'status': 'success', 'time': datetime.now().isoformat()}
    except Exception as e:
        logger.error(f'FAILED: {name} - {str(e)}')
        return {'name': name, 'status': 'failed', 'error': str(e), 'time': datetime.now().isoformat()}

REFRESH_QUERIES = {
    'mart_daily_overview': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_daily_overview` AS
        SELECT event_date,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_engagement_sec,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
          COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids_created,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
          COUNTIF(event_name = 'registration_success') AS registrations_completed
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY event_date ORDER BY event_date DESC
    """,

    'mart_acquisition': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_acquisition` AS
        SELECT event_date, channel_group, source, medium, campaign,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
          COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name = 'registration_success') AS registrations,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1,2,3,4,5 ORDER BY event_date DESC, users DESC
    """,

    'mart_funnel': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_funnel` AS
        SELECT event_date, channel_group, source, campaign,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS step_1_visitors,
          COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END) AS step_2_apply_click,
          COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END) AS step_3_sub_id,
          COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) AS step_4_check_limit,
          COUNT(DISTINCT CASE WHEN event_name IN ('phone_submited_reg', 'phone_submited_sprint') THEN user_pseudo_id END) AS step_5_phone_submitted,
          COUNT(DISTINCT CASE WHEN event_name = 'register_funnel' THEN user_pseudo_id END) AS step_6_register_start,
          COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) AS step_7_register_complete,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END)) AS rate_visit_to_apply,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END)) AS rate_apply_to_sub_id,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END)) AS rate_sub_id_to_register
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1,2,3,4 ORDER BY event_date DESC, step_1_visitors DESC
    """,

    'mart_product_performance': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_product_performance` AS
        SELECT event_date, product_category,
          COUNTIF(event_name = 'page_view') AS pageviews,
          COUNT(DISTINCT user_pseudo_id) AS unique_viewers,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click', 'cards_apply_button', 'apply_button_click')) AS apply_clicks,
          COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click', 'cards_apply_button', 'apply_button_click')),
            COUNT(DISTINCT user_pseudo_id)) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        WHERE product_category != 'Other'
        GROUP BY 1, 2 ORDER BY event_date DESC, pageviews DESC
    """,

    'mart_campaign_performance': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_campaign_performance` AS
        SELECT event_date, channel_group, source, medium, campaign,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_engagement_sec,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
          COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids,
          COUNTIF(event_name = 'registration_success') AS registrations,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1,2,3,4,5 ORDER BY event_date DESC, users DESC
    """,

    'mart_gm_channel_daily': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_channel_daily` AS
        WITH ga_data AS (
          SELECT event_date, channel_group,
            COUNT(DISTINCT user_pseudo_id) AS users,
            COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
            COUNTIF(event_name = 'page_view') AS pageviews,
            ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_session_duration_sec,
            COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
            COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids,
            COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
            COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
            COUNTIF(event_name = 'registration_success') AS registrations_completed
          FROM `x-victor-477214-g0.ineco_staging.stg_events`
          GROUP BY 1, 2
        ),
        spend_data AS (
          SELECT date AS event_date, channel AS channel_group,
            SUM(impressions) AS impressions, SUM(clicks) AS paid_clicks, SUM(cost) AS spend
          FROM `x-victor-477214-g0.ineco_raw.ad_spend`
          GROUP BY 1, 2
        )
        SELECT g.*,
          SAFE_DIVIDE(g.apply_clicks, g.sessions) AS rate_session_to_apply,
          SAFE_DIVIDE(g.sub_ids, g.apply_clicks) AS rate_apply_to_sub_id,
          SAFE_DIVIDE(g.registrations_completed, g.sessions) AS rate_session_to_register,
          COALESCE(s.impressions, 0) AS impressions, COALESCE(s.paid_clicks, 0) AS paid_clicks, COALESCE(s.spend, 0) AS spend,
          SAFE_DIVIDE(s.spend, g.sessions) AS cost_per_session,
          SAFE_DIVIDE(s.spend, g.apply_clicks) AS cost_per_apply,
          SAFE_DIVIDE(s.spend, g.registrations_completed) AS cost_per_registration
        FROM ga_data g
        LEFT JOIN spend_data s ON g.event_date = s.event_date AND g.channel_group = s.channel_group
        ORDER BY g.event_date DESC, g.users DESC
    """,

    'mart_gm_campaign_daily': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_campaign_daily` AS
        SELECT event_date, channel_group, source, campaign,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
          COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
          COUNTIF(event_name = 'registration_success') AS registrations_completed,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS rate_session_to_apply,
          SAFE_DIVIDE(COUNTIF(event_name = 'registration_success'),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS rate_session_to_register
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1,2,3,4 ORDER BY event_date DESC, users DESC
    """,

    'mart_gm_funnel': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_funnel` AS
        SELECT event_date, channel_group, source,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS step1_visitors,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category NOT IN ('Other', 'Homepage', 'Support & Info') THEN user_pseudo_id END) AS step2_product_viewers,
          COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END) AS step3_apply_click,
          COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END) AS step4_sub_id,
          COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) AS step5_check_limit,
          COUNT(DISTINCT CASE WHEN event_name IN ('phone_submited_reg', 'phone_submited_sprint') THEN user_pseudo_id END) AS step6_phone_submitted,
          COUNT(DISTINCT CASE WHEN event_name = 'register_funnel' THEN user_pseudo_id END) AS step7_reg_started,
          COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) AS step8_reg_completed,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END)) AS rate_visitor_to_apply,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END)) AS rate_apply_to_sub_id,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END)) AS rate_apply_to_register
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1,2,3 ORDER BY event_date DESC, step1_visitors DESC
    """,

    'mart_gm_product': """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_product` AS
        SELECT event_date, channel_group, product_category,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
          COUNTIF(event_name = 'registration_success') AS registrations_completed,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS rate_session_to_apply,
          SAFE_DIVIDE(COUNTIF(event_name = 'registration_success'),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS rate_session_to_register
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        WHERE product_category IS NOT NULL
        GROUP BY 1,2,3 ORDER BY event_date DESC, users DESC
    """
}

def main():
    logger.info('='*50)
    logger.info('Starting mart refresh')
    
    results = []
    failures = []
    
    for name, sql in REFRESH_QUERIES.items():
        result = run_query(name, sql)
        results.append(result)
        if result['status'] == 'failed':
            failures.append(result)
    
    # Save status
    status = {
        'last_run': datetime.now().isoformat(),
        'total': len(results),
        'success': len(results) - len(failures),
        'failed': len(failures),
        'results': results
    }
    
    with open(STATUS_FILE, 'w') as f:
        json.dump(status, f, indent=2)
    
    # Summary
    logger.info('='*50)
    logger.info(f'Completed: {status["success"]}/{status["total"]} tables refreshed')
    
    if failures:
        logger.error(f'FAILURES: {[f["name"] for f in failures]}')
        # Exit with error code for cron monitoring
        exit(1)
    else:
        logger.info('All tables refreshed successfully')
        exit(0)

if __name__ == '__main__':
    main()
