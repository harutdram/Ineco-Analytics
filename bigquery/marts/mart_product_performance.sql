-- Mart: Product Performance
-- Performance metrics by banking product category
-- Created: 2026-02-14

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.mart_product_performance` AS
SELECT
  event_date,
  product_category,
  
  -- Traffic
  COUNTIF(event_name = 'page_view') AS pageviews,
  COUNT(DISTINCT user_pseudo_id) AS unique_viewers,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS sessions,
  
  -- Conversions
  COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click', 'cards_apply_button', 'apply_button_click')) AS apply_clicks,
  COUNTIF(event_name = 'check_limit_click') AS check_limit_clicks,
  
  -- Conversion rate
  SAFE_DIVIDE(
    COUNTIF(event_name IN ('sprint_apply_button_click', 'reg_apply_button_click', 'cards_apply_button', 'apply_button_click')),
    COUNT(DISTINCT user_pseudo_id)
  ) AS conversion_rate

FROM `x-victor-477214-g0.ineco_staging.stg_events`
WHERE product_category != 'other'
GROUP BY 1, 2
ORDER BY event_date DESC, pageviews DESC;
