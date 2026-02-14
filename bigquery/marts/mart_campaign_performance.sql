-- Mart: Campaign Performance
-- Detailed campaign-level metrics for marketing optimization
-- Created: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_campaign_performance` AS
SELECT
  event_date,
  channel_group,
  source,
  medium,
  campaign,
  
  -- Traffic
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
  COUNTIF(event_name = 'page_view') AS pageviews,
  
  -- Engagement
  ROUND(AVG(CASE WHEN engagement_time_msec > 0 THEN engagement_time_msec END) / 1000, 2) AS avg_engagement_sec,
  
  -- Conversions
  COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
  COUNTIF(event_name = 'sprint_apply_button_click') AS applications,
  COUNTIF(event_name = 'registration_success') AS registrations,
  
  -- Rates
  SAFE_DIVIDE(
    COUNTIF(event_name = 'sprint_apply_button_click'),
    COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))
  ) AS conversion_rate

FROM `x-victor-477214-g0.ineco_staging.stg_events`
WHERE campaign IS NOT NULL AND campaign != '(direct)' AND campaign != '(organic)'
GROUP BY 1, 2, 3, 4, 5
HAVING sessions > 10
ORDER BY event_date DESC, users DESC;
