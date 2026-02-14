-- Mart: Funnel
-- Conversion funnel by channel and source
-- Created: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_funnel` AS
SELECT
  event_date,
  channel_group,
  source,
  campaign,
  
  -- Funnel steps (unique users at each step)
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS step_1_visitors,
  COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) AS step_2_check_limit,
  COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) AS step_3_apply_click,
  COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) AS step_4_app_created,
  COUNT(DISTINCT CASE WHEN event_name IN ('phone_submited_reg', 'phone_submited_sprint') THEN user_pseudo_id END) AS step_5_phone_submitted,
  COUNT(DISTINCT CASE WHEN event_name = 'register_funnel' THEN user_pseudo_id END) AS step_6_register_start,
  COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) AS step_7_register_complete,
  
  -- Conversion rates
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END),
    COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END)
  ) AS rate_visit_to_apply,
  
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END),
    COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END)
  ) AS rate_apply_to_register

FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY 1, 2, 3, 4
ORDER BY event_date DESC, step_1_visitors DESC;
