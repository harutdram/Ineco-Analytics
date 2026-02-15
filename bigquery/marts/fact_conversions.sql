-- Fact: fact_conversions
-- Funnel progression and conversion metrics
-- Grain: date + source_clean + channel_group + device_category + product_category
-- Partitioned by date, clustered by channel_group and product_category
--
-- FUNNEL DEFINITIONS:
-- Loans (Sprint): PageView → sprint_apply_button_click → Get Sub ID sprint → check_limit_click → phone_submited_sprint → otp_submited_sprint → registration_success
-- Cards/Deposits: PageView → Reg_apply_button_click → Get Sub ID → registration_success

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_conversions`
PARTITION BY date
CLUSTER BY channel_group, product_category
AS
SELECT
  event_date as date,
  source_clean,
  channel_group,
  device_category,
  product_category,
  
  -- Session/User base
  COUNT(DISTINCT user_pseudo_id) as total_users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(session_id AS STRING))) as total_sessions,
  
  -- LOANS FUNNEL (Sprint flow)
  -- Step 1: Page view on loan pages
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as loans_pageview,
  -- Step 2: Click apply button (вход в спринт)
  COUNT(DISTINCT CASE WHEN event_name = 'sprint_apply_button_click' THEN user_pseudo_id END) as loans_apply_click,
  -- Step 3: Get Sub ID (идентификация в спринте)
  COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END) as loans_sub_id,
  -- Step 4: Check limit (проверка одобренных лимитов)
  COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) as loans_check_limit,
  -- Step 5: Phone submitted
  COUNT(DISTINCT CASE WHEN event_name = 'phone_submited_sprint' THEN user_pseudo_id END) as loans_phone_submit,
  -- Step 6: OTP submitted
  COUNT(DISTINCT CASE WHEN event_name = 'otp_submited_sprint' THEN user_pseudo_id END) as loans_otp_submit,
  
  -- CARDS/DEPOSITS FUNNEL (Registration flow)
  -- Step 1: Page view on cards/deposits pages
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' AND product_category IN ('Cards', 'Deposits') THEN user_pseudo_id END) as cards_deposits_pageview,
  -- Step 2: Click registration apply button
  COUNT(DISTINCT CASE WHEN event_name = 'Reg_apply_button_click' THEN user_pseudo_id END) as cards_deposits_apply_click,
  -- Step 3: Get Sub ID
  COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID' THEN user_pseudo_id END) as cards_deposits_sub_id,
  
  -- FINAL CONVERSION (both funnels)
  COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) as registrations

FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY 1, 2, 3, 4, 5;
