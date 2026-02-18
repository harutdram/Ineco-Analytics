-- Unified Ad Spend Mart Table
-- Combines all ad spend sources: Google Ads, Facebook Ads, etc.
-- Run this after refreshing individual source tables

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_ad_spend` AS

-- Google Ads (from BigQuery Data Transfer)
SELECT
  date,
  channel_group,
  campaign,
  ad_group,
  impressions,
  clicks,
  spend_usd,
  spend_amd,
  ctr,
  cpc,
  cpm,
  conversions,
  cost_per_conversion
FROM `x-victor-477214-g0.ineco_marts.fact_ad_spend_google`
WHERE date IS NOT NULL

UNION ALL

-- Facebook Ads (from Airbyte)
SELECT
  DATE(date_start) as date,
  'Meta Ads' as channel_group,
  campaign_name as campaign,
  adset_name as ad_group,
  CAST(impressions AS FLOAT64) as impressions,
  CAST(clicks AS FLOAT64) as clicks,
  CAST(spend AS FLOAT64) as spend_usd,
  CAST(spend AS FLOAT64) * 400 as spend_amd,
  SAFE_DIVIDE(CAST(clicks AS FLOAT64), CAST(impressions AS FLOAT64)) * 100 as ctr,
  SAFE_DIVIDE(CAST(spend AS FLOAT64), CAST(clicks AS FLOAT64)) as cpc,
  SAFE_DIVIDE(CAST(spend AS FLOAT64), CAST(impressions AS FLOAT64)) * 1000 as cpm,
  0 as conversions,  -- Facebook conversions tracked separately
  0 as cost_per_conversion
FROM `x-victor-477214-g0.ineco_raw.ads_insights`
WHERE date_start IS NOT NULL;
