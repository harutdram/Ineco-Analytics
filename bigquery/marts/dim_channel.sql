-- Dimension: dim_channel
-- Channel/Source dimension with marketing categorizations
-- Grain: 1 row per unique source_clean + channel_group combination

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.dim_channel` AS
SELECT
  ROW_NUMBER() OVER (ORDER BY channel_group, source_clean) AS channel_key,
  source_clean,
  channel_group,
  -- High-level channel type
  CASE 
    WHEN channel_group IN ('Google Ads', 'Meta Ads', 'NN Ads', 'MS Network', 'Native Ads', 
                           'Intent Ads', 'Prodigi Ads', 'Adfox Video', 'LinkedIn') THEN 'Paid'
    WHEN channel_group IN ('Google Organic', 'Bing Organic', 'Yahoo', 'Yandex') THEN 'Organic Search'
    WHEN channel_group IN ('Email', 'SMS', 'Viber', 'Telegram') THEN 'CRM'
    WHEN channel_group = 'Direct' THEN 'Direct'
    WHEN channel_group = 'Referral' THEN 'Referral'
    ELSE 'Other'
  END AS channel_type,
  -- Paid flag
  CASE 
    WHEN channel_group IN ('Google Ads', 'Meta Ads', 'NN Ads', 'MS Network', 'Native Ads', 
                           'Intent Ads', 'Prodigi Ads', 'Adfox Video', 'LinkedIn') THEN TRUE
    ELSE FALSE
  END AS is_paid,
  -- Channel category for grouping
  CASE
    WHEN source_clean = 'Google' THEN 'Google'
    WHEN source_clean = 'Meta' THEN 'Meta'
    WHEN source_clean IN ('NN Ads', 'MS Network', 'Native Ads', 'Intent Ads', 'Prodigi Ads') THEN 'Local Ad Networks'
    WHEN source_clean IN ('Email', 'SMS', 'Viber', 'Telegram') THEN 'Direct Messaging'
    WHEN source_clean IN ('Yandex', 'Bing', 'Yahoo') THEN 'Other Search'
    ELSE 'Other'
  END AS channel_category
FROM (
  SELECT DISTINCT source_clean, channel_group
  FROM `x-victor-477214-g0.ineco_staging.stg_events`
);
