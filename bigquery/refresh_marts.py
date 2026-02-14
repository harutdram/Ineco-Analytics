#!/usr/bin/env python3
"""
Daily refresh script for Ineco BigQuery mart tables.
Run via cron at 6:00 AM UTC daily.
"""

from google.cloud import bigquery
import os
from datetime import datetime

# Set credentials path
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/home/harut/superset/credentials/bigquery-service-account.json'

PROJECT = 'x-victor-477214-g0'
client = bigquery.Client(project=PROJECT, location='EU')

def run_query(name, sql):
    """Execute a query and report status."""
    print(f"[{datetime.now()}] Refreshing {name}...")
    try:
        job = client.query(sql)
        job.result()
        print(f"[{datetime.now()}] ✓ {name} completed")
        return True
    except Exception as e:
        print(f"[{datetime.now()}] ✗ {name} failed: {e}")
        return False

# SQL for each mart table
REFRESH_QUERIES = {
    "mart_daily_overview": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_daily_overview` AS
        SELECT
          event_date,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_engagement_sec,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name = 'sprint_apply_button_click') AS sprint_applications,
          COUNTIF(event_name = 'Get Sub ID sprint') AS applications_created,
          COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
          COUNTIF(event_name = 'register_funnel') AS registrations_started,
          COUNTIF(event_name = 'registration_success') AS registrations_completed,
          COUNTIF(event_name = 'cards_apply_button') AS card_applications,
          COUNTIF(event_name = 'sign_in_click') AS sign_in_clicks
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY event_date
        ORDER BY event_date DESC
    """,
    
    "mart_acquisition": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_acquisition` AS
        SELECT
          event_date, channel_group, source, medium, campaign,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name = 'sprint_apply_button_click') AS applications,
          COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
          COUNTIF(event_name = 'registration_success') AS registrations,
          SAFE_DIVIDE(COUNTIF(event_name = 'sprint_apply_button_click'),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1, 2, 3, 4, 5
        ORDER BY event_date DESC, users DESC
    """,
    
    "mart_funnel": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_funnel` AS
        SELECT
          event_date, channel_group, source, campaign,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS step_1_visitors,
          COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) AS step_2_check_limit,
          COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) AS step_3_apply_click,
          COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) AS step_4_app_created,
          COUNT(DISTINCT CASE WHEN event_name IN ('phone_submited_reg', 'phone_submited_sprint') THEN user_pseudo_id END) AS step_5_phone_submitted,
          COUNT(DISTINCT CASE WHEN event_name = 'register_funnel' THEN user_pseudo_id END) AS step_6_register_start,
          COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) AS step_7_register_complete,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END)) AS rate_visit_to_apply,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END)) AS rate_apply_to_register
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1, 2, 3, 4
        ORDER BY event_date DESC, step_1_visitors DESC
    """,
    
    "mart_product_performance": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_product_performance` AS
        SELECT
          event_date, product_category,
          COUNTIF(event_name = 'page_view') AS pageviews,
          COUNT(DISTINCT user_pseudo_id) AS unique_viewers,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click', 'cards_apply_button', 'apply_button_click')) AS apply_clicks,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click', 'cards_apply_button', 'apply_button_click')),
            COUNT(DISTINCT user_pseudo_id)) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        WHERE product_category != 'other'
        GROUP BY 1, 2
        ORDER BY event_date DESC, pageviews DESC
    """,
    
    "mart_campaign_performance": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_campaign_performance` AS
        SELECT
          event_date, channel_group, source, medium, campaign,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_engagement_sec,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name = 'sprint_apply_button_click') AS applications,
          COUNTIF(event_name = 'registration_success') AS registrations,
          SAFE_DIVIDE(COUNTIF(event_name = 'sprint_apply_button_click'),
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        WHERE campaign IS NOT NULL AND campaign != '(direct)' AND campaign != '(organic)'
        GROUP BY 1, 2, 3, 4, 5
        HAVING sessions > 10
        ORDER BY event_date DESC, users DESC
    """,
    
    # ============ GROWTH MARKETING TABLES ============
    
    "mart_gm_channel_daily": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_channel_daily` AS
        WITH ga_data AS (
          SELECT
            event_date, channel_group,
            COUNT(DISTINCT user_pseudo_id) AS users,
            COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
            COUNTIF(event_name = 'page_view') AS pageviews,
            ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_session_duration_sec,
            COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
            COUNTIF(event_name = 'sprint_apply_button_click') AS applications,
            COUNTIF(event_name = 'Get Sub ID sprint') AS applications_started,
            COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
            COUNTIF(event_name = 'register_funnel') AS registrations_started,
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
          SAFE_DIVIDE(g.check_limit_clicks, g.sessions) AS rate_session_to_check_limit,
          SAFE_DIVIDE(g.applications, g.sessions) AS rate_session_to_apply,
          SAFE_DIVIDE(g.applications, g.check_limit_clicks) AS rate_check_to_apply,
          SAFE_DIVIDE(g.registrations_completed, g.applications) AS rate_apply_to_register,
          SAFE_DIVIDE(g.registrations_completed, g.sessions) AS rate_session_to_register,
          COALESCE(s.impressions, 0) AS impressions, COALESCE(s.paid_clicks, 0) AS paid_clicks, COALESCE(s.spend, 0) AS spend,
          SAFE_DIVIDE(s.spend, g.sessions) AS cost_per_session,
          SAFE_DIVIDE(s.spend, g.applications) AS cost_per_application,
          SAFE_DIVIDE(s.spend, g.registrations_completed) AS cost_per_registration,
          SAFE_DIVIDE(s.spend, s.paid_clicks) AS cpc
        FROM ga_data g
        LEFT JOIN spend_data s ON g.event_date = s.event_date AND LOWER(g.channel_group) = LOWER(s.channel_group)
        ORDER BY g.event_date DESC, g.users DESC
    """,
    
    "mart_gm_campaign_daily": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_campaign_daily` AS
        WITH ga_data AS (
          SELECT event_date, channel_group, source, medium, campaign,
            COUNT(DISTINCT user_pseudo_id) AS users,
            COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
            COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
            COUNTIF(event_name = 'page_view') AS pageviews,
            COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
            COUNTIF(event_name = 'sprint_apply_button_click') AS applications,
            COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
            COUNTIF(event_name = 'registration_success') AS registrations_completed
          FROM `x-victor-477214-g0.ineco_staging.stg_events`
          WHERE campaign IS NOT NULL
          GROUP BY 1, 2, 3, 4, 5
        ),
        spend_data AS (
          SELECT date AS event_date, campaign_name,
            SUM(impressions) AS impressions, SUM(clicks) AS paid_clicks, SUM(cost) AS spend
          FROM `x-victor-477214-g0.ineco_raw.ad_spend`
          GROUP BY 1, 2
        )
        SELECT g.*,
          SAFE_DIVIDE(g.applications, g.sessions) AS cvr_session_to_apply,
          SAFE_DIVIDE(g.registrations_completed, g.applications) AS cvr_apply_to_register,
          SAFE_DIVIDE(g.registrations_completed, g.sessions) AS cvr_overall,
          COALESCE(s.impressions, 0) AS impressions, COALESCE(s.paid_clicks, 0) AS paid_clicks, COALESCE(s.spend, 0) AS spend,
          SAFE_DIVIDE(s.spend, g.applications) AS cpa_application,
          SAFE_DIVIDE(s.spend, g.registrations_completed) AS cpa_registration,
          SAFE_DIVIDE(s.spend, s.paid_clicks) AS cpc
        FROM ga_data g
        LEFT JOIN spend_data s ON g.event_date = s.event_date AND g.campaign = s.campaign_name
        WHERE g.sessions >= 5
        ORDER BY g.event_date DESC, g.users DESC
    """,
    
    "mart_gm_funnel": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_funnel` AS
        SELECT event_date, channel_group, source,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS step1_visitors,
          COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category != 'other' THEN user_pseudo_id END) AS step2_product_viewers,
          COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) AS step3_check_limit,
          COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) AS step4_apply_click,
          COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) AS step5_app_started,
          COUNT(DISTINCT CASE WHEN event_name IN ('phone_submited_reg', 'phone_submited_sprint') THEN user_pseudo_id END) AS step6_phone_submitted,
          COUNT(DISTINCT CASE WHEN event_name = 'register_funnel' THEN user_pseudo_id END) AS step7_reg_started,
          COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) AS step8_reg_completed,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END)) AS rate_1_to_3,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END)) AS rate_3_to_4,
          SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END),
            COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END)) AS rate_4_to_8
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        GROUP BY 1, 2, 3
        ORDER BY event_date DESC, step1_visitors DESC
    """,
    
    "mart_gm_product": """
        CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_product` AS
        SELECT event_date, channel_group, product_category,
          COUNT(DISTINCT user_pseudo_id) AS users,
          COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
          COUNTIF(event_name = 'page_view') AS pageviews,
          COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
          COUNTIF(event_name IN ('sprint_apply_button_click', 'cards_apply_button', 'apply_button_click')) AS applications,
          COUNTIF(event_name = 'registration_success') AS registrations,
          SAFE_DIVIDE(COUNTIF(event_name IN ('sprint_apply_button_click', 'cards_apply_button', 'apply_button_click')),
            COUNT(DISTINCT user_pseudo_id)) AS conversion_rate
        FROM `x-victor-477214-g0.ineco_staging.stg_events`
        WHERE product_category != 'other'
        GROUP BY 1, 2, 3
        ORDER BY event_date DESC, users DESC
    """
}

if __name__ == "__main__":
    print(f"[{datetime.now()}] Starting daily mart refresh...")
    
    success = 0
    failed = 0
    
    for name, sql in REFRESH_QUERIES.items():
        if run_query(name, sql):
            success += 1
        else:
            failed += 1
    
    print(f"[{datetime.now()}] Completed: {success} succeeded, {failed} failed")
