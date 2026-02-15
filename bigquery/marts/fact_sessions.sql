-- fact_sessions: Core session and engagement metrics
-- Partitioned by date, clustered by channel_group and product_category
-- Includes campaign-level and geographic breakdowns

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_sessions`
PARTITION BY date
CLUSTER BY channel_group, product_category
AS
WITH session_data AS (
  SELECT
    event_date as date,
    source_clean,
    channel_group,
    COALESCE(campaign, '(not set)') as campaign,
    device_category,
    product_category,
    country,
    city,
    user_pseudo_id,
    session_id,
    CASE WHEN session_number = 1 THEN 'New' ELSE 'Returning' END as user_type,
    COUNT(CASE WHEN event_name = 'page_view' THEN 1 END) as pageviews,
    SUM(COALESCE(engagement_time_msec, 0)) / 1000.0 as engagement_sec,
    MAX(session_engaged) as session_engaged
  FROM `x-victor-477214-g0.ineco_staging.stg_events`
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
)
SELECT
  date,
  source_clean,
  channel_group,
  campaign,
  device_category,
  product_category,
  country,
  city,
  user_type,
  COUNT(DISTINCT user_pseudo_id) as users,
  COUNT(DISTINCT CASE WHEN user_type = 'New' THEN user_pseudo_id END) as new_users,
  COUNT(*) as sessions,
  SUM(CASE WHEN pageviews = 1 AND engagement_sec < 10 THEN 1 ELSE 0 END) as bounced_sessions,
  SUM(pageviews) as pageviews,
  AVG(engagement_sec) as avg_session_duration_sec,
  AVG(pageviews) as avg_pages_per_session
FROM session_data
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;
