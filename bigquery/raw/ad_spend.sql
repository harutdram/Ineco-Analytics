-- Raw Table: ad_spend
-- Ad spend data from advertising platforms (Google Ads, Meta, LinkedIn, Yandex, etc.)
-- Data source: Airbyte ETL from ad platform APIs
-- Created: 2026-02-14

CREATE TABLE IF NOT EXISTS `x-victor-477214-g0.ineco_raw.ad_spend` (
  date DATE,
  channel STRING,
  campaign_name STRING,
  impressions INT64,
  clicks INT64,
  cost FLOAT64,
  currency STRING
);

-- Future columns when real data arrives:
-- ad_group STRING,
-- ad_id STRING,
-- creative_id STRING,
-- device STRING,
-- location STRING,
-- conversions INT64,
-- conversion_value FLOAT64
