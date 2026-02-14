-- Staging View: stg_events
-- Cleans and transforms GA4 events with channel grouping and product classification
-- Created: 2026-02-14

CREATE OR REPLACE VIEW `x-victor-477214-g0.ineco_staging.stg_events` AS
SELECT
  -- Date and time
  PARSE_DATE('%Y%m%d', event_date) AS event_date,
  TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
  
  -- Event info
  event_name,
  
  -- User identifiers
  user_pseudo_id,
  user_id,
  
  -- Session info
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS session_number,
  
  -- Page info
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_title') AS page_title,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_referrer') AS page_referrer,
  
  -- Traffic source (original)
  traffic_source.source AS source,
  traffic_source.medium AS medium,
  traffic_source.name AS campaign,
  
  -- Channel grouping (custom for Ineco)
  CASE
    WHEN traffic_source.source = '(direct)' THEN 'Direct'
    WHEN traffic_source.source = 'google' AND traffic_source.medium = 'cpc' THEN 'Google Ads'
    WHEN traffic_source.source = 'google' AND traffic_source.medium = 'organic' THEN 'Google Organic'
    WHEN traffic_source.source LIKE '%Meta%' OR traffic_source.source IN ('facebook', 'fb', 'instagram') 
         OR traffic_source.source LIKE '%instagram%' THEN 'Meta Ads'
    WHEN traffic_source.source = 'NN_Ads' THEN 'NN Ads'
    WHEN traffic_source.source LIKE '%Native%' THEN 'Native Ads'
    WHEN traffic_source.source LIKE '%MS_%' OR traffic_source.source = 'ms_network' 
         OR traffic_source.source LIKE '%MS_network%' THEN 'MS Network'
    WHEN LOWER(traffic_source.source) LIKE '%viber%' THEN 'Viber'
    WHEN traffic_source.source = 'yandex' OR traffic_source.source LIKE '%yandex%' THEN 'Yandex'
    WHEN traffic_source.source = 'email' THEN 'Email'
    WHEN traffic_source.source = 'bing' AND traffic_source.medium = 'organic' THEN 'Bing Organic'
    WHEN traffic_source.medium = 'referral' THEN 'Referral'
    WHEN traffic_source.source = 'intent_ads' THEN 'Intent Ads'
    ELSE 'Other'
  END AS channel_group,
  
  -- Product category (from page URL)
  CASE
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%consumer-loans%' 
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%1-click%' 
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%sprint%'
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%refinance%' THEN 'consumer_loans'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%car-loan%' 
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%avtovark%' THEN 'car_loans'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%mortgage%' THEN 'mortgage'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%deposit%' THEN 'deposits'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%card%' 
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%visa%' 
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%mastercard%' THEN 'cards'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%inecomobile%' 
         OR (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%inecoonline%' THEN 'digital_banking'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%account%' THEN 'accounts'
    WHEN (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') 
         LIKE '%Business%' THEN 'business'
    ELSE 'other'
  END AS product_category,
  
  -- Conversion tracking
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'Access Token Sub ID') AS access_token_sub_id,
  
  -- Engagement metrics
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS engagement_time_msec,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'session_engaged') AS session_engaged,
  
  -- Device info
  device.category AS device_category,
  device.mobile_brand_name AS device_brand,
  device.operating_system AS device_os,
  device.web_info.browser AS browser,
  
  -- Geo info
  geo.country AS country,
  geo.city AS city,
  
  -- Platform
  platform

FROM `x-victor-477214-g0.analytics_280405726.events_*`
WHERE _TABLE_SUFFIX >= '20251201';
