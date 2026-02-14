-- Mart: Acquisition
-- Traffic source performance by day
-- Created: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_acquisition` AS
SELECT
  event_date,
  channel_group,
  source,
  medium,
  campaign,
  
  -- User metrics
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
  
  -- Session metrics
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
  
  -- Conversions
  COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
  COUNTIF(event_name = 'sprint_apply_button_click') AS applications,
  COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
  COUNTIF(event_name = 'registration_success') AS registrations,
  
  -- Conversion rate
  SAFE_DIVIDE(
    COUNTIF(event_name = 'sprint_apply_button_click'),
    COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))
  ) AS conversion_rate

FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY 1, 2, 3, 4, 5
ORDER BY event_date DESC, users DESC;
