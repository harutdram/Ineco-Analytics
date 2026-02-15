-- Fact: fact_ad_spend
-- Ad spend and cost data from advertising platforms
-- Grain: date + channel_group + campaign
-- Partitioned by date, clustered by channel_group
--
-- NOTE: This table is populated from ad network APIs (Google Ads, Meta, etc.)
-- Currently empty - awaiting API credentials

CREATE TABLE IF NOT EXISTS `x-victor-477214-g0.ineco_marts.fact_ad_spend` (
  date DATE,
  channel_group STRING,
  campaign STRING,
  impressions FLOAT64,
  clicks FLOAT64,
  spend_usd FLOAT64,
  spend_amd FLOAT64
)
PARTITION BY date
CLUSTER BY channel_group;

-- To populate this table, use:
-- INSERT INTO `x-victor-477214-g0.ineco_marts.fact_ad_spend`
-- SELECT ... FROM ad_network_data
