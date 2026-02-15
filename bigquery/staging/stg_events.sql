-- Staging View: stg_events
-- Cleans and transforms GA4 events with channel grouping and product classification
-- Updated: 2026-02-14

CREATE OR REPLACE VIEW `x-victor-477214-g0.ineco_staging.stg_events` AS
WITH base AS (
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
  WHERE _TABLE_SUFFIX >= '20251201'
)
SELECT
  *,

  -- SOURCE CLEAN (standardized source names)
  -- Groups raw traffic sources into clean categories
  CASE
    -- Direct traffic
    WHEN source = '(direct)' THEN 'Direct'
    
    -- Search engines
    WHEN source = 'google' THEN 'Google'
    WHEN source = 'bing' THEN 'Bing'
    WHEN source LIKE '%yahoo%' THEN 'Yahoo'
    WHEN source LIKE '%yandex%' OR source LIKE 'ya.%' THEN 'Yandex'
    
    -- Ad networks
    WHEN source LIKE 'NN%' OR source LIKE 'nn%' THEN 'NN Ads'
    WHEN source IN ('fb', 'ig', 'facebook', 'instagram', 'FB')
         OR source LIKE '%Meta%' OR source LIKE '%meta%'
         OR source LIKE '%facebook%' OR source LIKE '%instagram%'
         OR source LIKE 'fb_%' OR source LIKE 'fb-%' 
         OR source LIKE '%fbads%' OR source LIKE '%FBads%' THEN 'Meta'
    WHEN source LIKE '%MS_%' OR source LIKE '%MS-%' 
         OR source LIKE 'ms_%' OR source LIKE 'ms-%'
         OR source = 'ms_network' OR source = 'MS' OR source = 'ms'
         OR source LIKE '%mediasystem%' OR source LIKE '%MediaSystem%' THEN 'MS Network'
    WHEN source LIKE '%Native%' OR source LIKE '%native%' THEN 'Native Ads'
    WHEN source LIKE '%intent%' OR source LIKE '%Intent%' THEN 'Intent Ads'
    WHEN source LIKE '%prodigi%' OR source LIKE '%Prodigi%' THEN 'Prodigi Ads'
    WHEN source = 'adfox' THEN 'Adfox'
    WHEN source LIKE '%linkedin%' OR source LIKE '%lnkd%' OR source = 'LinkedIn_ads' THEN 'LinkedIn'
    
    -- Messaging channels
    WHEN source IN ('email', 'sfmc', 'Mailing', 'mailing') 
         OR source LIKE '%mail.%' OR source LIKE '%.mail.%'
         OR medium = 'email' THEN 'Email'
    WHEN source = 'SMS' OR source LIKE '%sms%' THEN 'SMS'
    WHEN LOWER(source) LIKE '%viber%' THEN 'Viber'
    WHEN source LIKE '%telegram%' OR source = 'Telegram' THEN 'Telegram'
    
    -- Surveys
    WHEN source LIKE '%survey%' THEN 'Survey'
    
    -- Promotions
    WHEN source LIKE '%Mastercard%' OR source LIKE '%mastercard%' THEN 'Mastercard Promo'
    
    -- Internal traffic
    WHEN source LIKE '%inecobank%' OR source = 'landing' OR source = 'inecobank' THEN 'Internal'
    
    -- Armenian referrals
    WHEN source LIKE '%.am' OR source LIKE '%.am:%' THEN 'Armenian Sites'
    
    -- AI referrals
    WHEN source LIKE 'chatgpt%' OR source LIKE 'claude%' OR source LIKE 'gemini%' 
         OR source LIKE 'copilot%' OR source LIKE 'perplexity%' THEN 'AI Tools'
    
    -- Data not available
    WHEN source = '(not set)' OR source IS NULL THEN 'Data Not Available'
    
    -- Catch-all for uncategorized sources
    ELSE 'Other'
  END AS source_clean,

  -- CHANNEL GROUPING (marketing channel with paid/organic split)
  -- More detailed than source_clean, splits by medium
  CASE
    WHEN source = '(direct)' THEN 'Direct'
    
    -- Google (split by paid/organic)
    WHEN source = 'google' AND medium = 'cpc' THEN 'Google Ads'
    WHEN source = 'google' AND medium = 'organic' THEN 'Google Organic'
    
    -- Meta (Facebook/Instagram ads)
    WHEN source LIKE '%Meta%' OR source IN ('facebook', 'fb', 'instagram', 'ig', 'FB')
         OR source LIKE '%instagram%' OR source LIKE '%facebook%'
         OR source LIKE 'fb_%' OR source LIKE '%fbads%' THEN 'Meta Ads'
    
    -- Ad networks
    WHEN source LIKE 'NN%' OR source LIKE 'nn%' THEN 'NN Ads'
    WHEN source LIKE '%MS_%' OR source LIKE '%MS-%' OR source LIKE 'ms_%'
         OR source LIKE 'ms-%' OR source = 'ms_network' OR source = 'MS'
         OR source LIKE '%mediasystem%' OR source LIKE '%MediaSystem%' THEN 'MS Network'
    WHEN source LIKE '%Native%' OR source LIKE '%native%' THEN 'Native Ads'
    WHEN source LIKE '%intent%' OR source LIKE '%Intent%' THEN 'Intent Ads'
    WHEN source LIKE '%prodigi%' OR source LIKE '%Prodigi%' THEN 'Prodigi Ads'
    WHEN source = 'adfox' THEN 'Adfox Video'
    WHEN source LIKE '%linkedin%' OR source LIKE '%lnkd%' OR source = 'LinkedIn_ads' THEN 'LinkedIn'
    
    -- Messaging channels
    WHEN source IN ('email', 'sfmc', 'Mailing', 'mailing') 
         OR source LIKE '%mail.%' OR medium = 'email' THEN 'Email'
    WHEN source = 'SMS' OR source LIKE '%sms%' THEN 'SMS'
    WHEN LOWER(source) LIKE '%viber%' THEN 'Viber'
    WHEN source LIKE '%telegram%' OR source = 'Telegram' THEN 'Telegram'
    
    -- Search engines
    WHEN source LIKE '%yandex%' OR source LIKE 'ya.%' THEN 'Yandex'
    WHEN source = 'bing' AND medium = 'organic' THEN 'Bing Organic'
    WHEN source LIKE '%yahoo%' THEN 'Yahoo'
    
    -- Survey traffic
    WHEN source LIKE '%survey%' THEN 'Survey'
    
    -- Referral traffic
    WHEN medium = 'referral' THEN 'Referral'
    
    -- Catch-all
    ELSE 'Other'
  END AS channel_group,

  -- PRODUCT CATEGORY (based on page URL)
  -- Classifies pages by Ineco product/service
  CASE
    -- Support/Info pages (check first to avoid overlap)
    WHEN page_location LIKE '%/contact-us%' OR page_location LIKE '%/contact%'
         OR page_location LIKE '%/faq%' OR page_location LIKE '%/about-inecobank%'
         OR page_location LIKE '%/useful-information%' OR page_location LIKE '%/career%'
         OR page_location LIKE '%/press-center%' OR page_location LIKE '%/shareholders%'
         OR page_location LIKE '%/corporate-governance%' OR page_location LIKE '%/reports%' THEN 'Support & Info'
    
    -- Loan products
    WHEN page_location LIKE '%consumer-loans%' OR page_location LIKE '%1-click%'
         OR page_location LIKE '%sprint%' OR page_location LIKE '%refinance%'
         OR page_location LIKE '%refinans%' THEN 'Consumer Loans'
    WHEN page_location LIKE '%car-loan%' OR page_location LIKE '%avtovark%' THEN 'Car Loans'
    WHEN page_location LIKE '%mortgage%' THEN 'Mortgage'
    
    -- Deposit products
    WHEN page_location LIKE '%deposit%' THEN 'Deposits'
    
    -- Card products
    WHEN page_location LIKE '%card%' OR page_location LIKE '%visa%'
         OR page_location LIKE '%mastercard%' OR page_location LIKE '%Mastercard%' THEN 'Cards'
    
    -- Digital banking
    WHEN page_location LIKE '%inecomobile%' OR page_location LIKE '%inecoonline%' THEN 'Digital Banking'
    
    -- Account services
    WHEN page_location LIKE '%account%' THEN 'Accounts'
    
    -- Business banking
    WHEN page_location LIKE '%/Business%' OR page_location LIKE '%/business%' THEN 'Business'
    
    -- Salary project
    WHEN page_location LIKE '%salary%' THEN 'Salary Project'
    
    -- Seasonal campaigns
    WHEN page_location LIKE '%christmas%' OR page_location LIKE '%black-friday%'
         OR page_location LIKE '%cyber-monday%' OR page_location LIKE '%pascali%'
         OR page_location LIKE '%new-year%' THEN 'Campaigns'
    
    -- Homepage
    WHEN page_location LIKE '%inecobank.am/hy%' OR page_location LIKE '%inecobank.am/en%'
         OR page_location LIKE '%inecobank.am/ru%'
         OR REGEXP_CONTAINS(page_location, r'inecobank\.am/?$') THEN 'Homepage'
    
    -- User account pages
    WHEN page_location LIKE '%user-info%' OR page_location LIKE '%personal-info%'
         OR page_location LIKE '%provision%' OR page_location LIKE '%sign-in%' THEN 'User Account'
    
    -- Catch-all
    ELSE 'Other'
  END AS product_category

FROM base;
