-- fact_conversions: Funnel progression and conversion metrics
-- Partitioned by date, clustered by channel_group and product_category
-- Includes campaign-level and geographic breakdowns

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_conversions`
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
  
  -- LOANS FUNNEL (Consumer Loans / Sprint)
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as loans_pageview,
  COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) as loans_apply_click,
  COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) as loans_sub_id,
  COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) as loans_check_limit,
  COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_sprint' THEN user_pseudo_id END) as loans_phone_submit,
  COUNT(DISTINCT CASE WHEN event_name = 'otp_submited_sprint' THEN user_pseudo_id END) as loans_otp_submit,
  
  -- CARDS/DEPOSITS FUNNEL
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category IN ('Cards', 'Deposits') THEN user_pseudo_id END) as cards_deposits_pageview,
  COUNT(DISTINCT CASE WHEN event_name IN ('reg_apply_button_click', 'cards_apply_button', 'apply_button_click') THEN user_pseudo_id END) as cards_deposits_apply_click,
  COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID' THEN user_pseudo_id END) as cards_deposits_sub_id,
  COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_reg' THEN user_pseudo_id END) as cards_deposits_phone_submit,
  
  -- FINAL CONVERSION
  COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) as registrations

FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;
