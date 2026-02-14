-- Mart Table: mart_gm_channel_daily
-- Growth Marketing channel performance by day with cost metrics
-- Updated: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_channel_daily` AS
WITH ga_data AS (
  SELECT
    event_date,
    channel_group,
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
  SELECT
    date AS event_date,
    channel AS channel_group,
    SUM(impressions) AS impressions,
    SUM(clicks) AS paid_clicks,
    SUM(cost) AS spend
  FROM `x-victor-477214-g0.ineco_raw.ad_spend`
  GROUP BY 1, 2
)
SELECT
  g.*,
  -- Conversion rates
  SAFE_DIVIDE(g.apply_clicks, g.sessions) AS rate_session_to_apply,
  SAFE_DIVIDE(g.sub_ids, g.apply_clicks) AS rate_apply_to_sub_id,
  SAFE_DIVIDE(g.registrations_completed, g.sessions) AS rate_session_to_register,
  -- Cost metrics
  COALESCE(s.impressions, 0) AS impressions,
  COALESCE(s.paid_clicks, 0) AS paid_clicks,
  COALESCE(s.spend, 0) AS spend,
  SAFE_DIVIDE(s.spend, g.sessions) AS cost_per_session,
  SAFE_DIVIDE(s.spend, g.apply_clicks) AS cost_per_apply,
  SAFE_DIVIDE(s.spend, g.registrations_completed) AS cost_per_registration
FROM ga_data g
LEFT JOIN spend_data s ON g.event_date = s.event_date AND g.channel_group = s.channel_group
ORDER BY g.event_date DESC, g.users DESC;
