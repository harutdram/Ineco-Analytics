-- Facebook Ads → fact_ad_spend transformation
-- Source: Airbyte synced tables in ineco_raw
-- Run this after Facebook campaigns start generating data

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_ad_spend` AS

SELECT
  DATE(date_start) as date,
  'Paid Social' as channel_group,  -- Facebook/Instagram = Paid Social
  campaign_name as campaign,
  
  -- Core metrics
  CAST(impressions AS FLOAT64) as impressions,
  CAST(clicks AS FLOAT64) as clicks,
  CAST(spend AS FLOAT64) as spend_usd,
  CAST(spend AS FLOAT64) * 400 as spend_amd,  -- Approximate USD to AMD conversion
  
  -- Additional metrics (for future use)
  CAST(reach AS FLOAT64) as reach,
  SAFE_DIVIDE(CAST(clicks AS FLOAT64), CAST(impressions AS FLOAT64)) * 100 as ctr,
  SAFE_DIVIDE(CAST(spend AS FLOAT64), CAST(clicks AS FLOAT64)) as cpc,
  SAFE_DIVIDE(CAST(spend AS FLOAT64), CAST(impressions AS FLOAT64)) * 1000 as cpm

FROM `x-victor-477214-g0.ineco_raw.ads_insights`
WHERE date_start IS NOT NULL;
