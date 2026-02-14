-- Mart Table: mart_gm_funnel
-- Growth Marketing 8-step funnel analysis by source
-- Funnel: Visitors → Product Viewers → Apply Click → Sub ID → Check Limit → Phone Submit → Reg Start → Reg Complete
-- Updated: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_gm_funnel` AS
SELECT
  event_date,
  channel_group,
  source,
  
  -- 8-step funnel
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END) AS step1_visitors,
  COUNT(DISTINCT CASE WHEN event_name = 'page_view' 
        AND product_category NOT IN ('Other', 'Homepage', 'Support & Info') THEN user_pseudo_id END) AS step2_product_viewers,
  COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END) AS step3_apply_click,
  COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END) AS step4_sub_id,
  COUNT(DISTINCT CASE WHEN event_name = 'check_limit_click' THEN user_pseudo_id END) AS step5_check_limit,
  COUNT(DISTINCT CASE WHEN event_name IN ('phone_submited_reg', 'phone_submited_sprint') THEN user_pseudo_id END) AS step6_phone_submitted,
  COUNT(DISTINCT CASE WHEN event_name = 'register_funnel' THEN user_pseudo_id END) AS step7_reg_started,
  COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END) AS step8_reg_completed,
  
  -- Conversion rates
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END),
    COUNT(DISTINCT CASE WHEN event_name = 'page_view' THEN user_pseudo_id END)
  ) AS rate_visitor_to_apply,
  
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID sprint', 'Get Sub ID') THEN user_pseudo_id END),
    COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END)
  ) AS rate_apply_to_sub_id,
  
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END),
    COUNT(DISTINCT CASE WHEN event_name IN ('sprint_apply_button_click', 'reg_apply_button_click') THEN user_pseudo_id END)
  ) AS rate_apply_to_register

FROM `x-victor-477214-g0.ineco_staging.stg_events`
GROUP BY 1, 2, 3
ORDER BY event_date DESC, step1_visitors DESC;
