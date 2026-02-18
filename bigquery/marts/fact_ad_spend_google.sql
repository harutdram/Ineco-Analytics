-- Google Ads Spend Mart Table
-- Transforms raw Google Ads data into standardized ad spend format
-- Source: BigQuery Data Transfer from Google Ads

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_ad_spend_google` AS
SELECT
  _DATA_DATE as date,
  'Google Ads' as channel_group,
  campaign_name as campaign,
  ad_group_name as ad_group,
  CAST(impressions AS FLOAT64) as impressions,
  CAST(clicks AS FLOAT64) as clicks,
  CAST(cost_micros AS FLOAT64) / 1000000 as spend_usd,
  (CAST(cost_micros AS FLOAT64) / 1000000) * 400 as spend_amd,  -- USD to AMD conversion
  SAFE_DIVIDE(CAST(clicks AS FLOAT64), CAST(impressions AS FLOAT64)) * 100 as ctr,
  SAFE_DIVIDE(CAST(cost_micros AS FLOAT64) / 1000000, CAST(clicks AS FLOAT64)) as cpc,
  SAFE_DIVIDE(CAST(cost_micros AS FLOAT64) / 1000000, CAST(impressions AS FLOAT64)) * 1000 as cpm,
  CAST(conversions AS FLOAT64) as conversions,
  SAFE_DIVIDE(CAST(cost_micros AS FLOAT64) / 1000000, NULLIF(CAST(conversions AS FLOAT64), 0)) as cost_per_conversion
FROM `x-victor-477214-g0.ineco_raw.p_ads_CampaignStats_8656917454`
WHERE _DATA_DATE IS NOT NULL;
