-- Mart Table: mart_gm_campaign_daily
-- Growth Marketing campaign performance by day
-- Updated: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_campaign_daily` AS
SELECT
  event_date,
  channel_group,
  source,
  campaign,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CASE WHEN event_name = 'first_visit' THEN user_pseudo_id END) AS new_users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
  COUNTIF(event_name = 'page_view') AS pageviews,
  COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')) AS apply_clicks,
  COUNTIF(event_name IN ('Get Sub ID sprint', 'Get Sub ID')) AS sub_ids,
  COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
  COUNTIF(event_name IN ('phone_submited_reg', 'phone_submited_sprint')) AS phone_submissions,
  COUNTIF(event_name = 'registration_success') AS registrations_completed,
  -- Conversion rates
  SAFE_DIVIDE(
    COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click')),
    COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))
  ) AS rate_session_to_apply,
  SAFE_DIVIDE(
    COUNTIF(event_name = 'registration_success'),
    COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING)))
  ) AS rate_session_to_register
FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY 1, 2, 3, 4
ORDER BY event_date DESC, users DESC;
