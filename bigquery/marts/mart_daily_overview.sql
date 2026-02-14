-- Mart: Daily Overview
-- Executive KPIs aggregated by day
-- Created: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_daily_overview` AS
SELECT
  event_date,
  
  -- User metrics
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
  
  -- Session metrics
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
  COUNTIF(event_name = 'page_view') AS pageviews,
  
  -- Engagement (avg session duration in seconds)
  ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_engagement_sec,
  
  -- Funnel events
  COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
  COUNTIF(event_name = 'sprint_apply_button_click') AS sprint_applications,
  COUNTIF(event_name = 'Get Sub ID sprint') AS applications_created,
  COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
  COUNTIF(event_name = 'register_funnel') AS registrations_started,
  COUNTIF(event_name = 'registration_success') AS registrations_completed,
  
  -- Other conversions
  COUNTIF(event_name = 'cards_apply_button') AS card_applications,
  COUNTIF(event_name = 'sign_in_click') AS sign_in_clicks

FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY event_date
ORDER BY event_date DESC;
