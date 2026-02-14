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

  -- CHANNEL GROUPING (clean)
  CASE
    -- Direct
    WHEN source = '(direct)' THEN 'Direct'

    -- Google
    WHEN source = 'google' AND medium = 'cpc' THEN 'Google Ads'
    WHEN source = 'google' AND medium = 'organic' THEN 'Google Organic'

    -- Meta (Facebook, Instagram)
    WHEN source LIKE '%Meta%'
         OR source IN ('facebook', 'fb', 'instagram', 'ig')
         OR source LIKE '%instagram%'
         OR source LIKE 'm.facebook%' THEN 'Meta Ads'

    -- NN Ads Network (all variations)
    WHEN source LIKE 'NN%'
         OR source LIKE 'nn%' THEN 'NN Ads'

    -- MS Network (Microsoft/Bing)
    WHEN source LIKE '%MS_%'
         OR source LIKE '%MS-%'
         OR source LIKE 'ms_%'
         OR source LIKE 'ms-%'
         OR source = 'ms_network'
         OR source LIKE '%msv%'
         OR source LIKE '%msvisa%' THEN 'MS Network'

    -- Native Ads
    WHEN source LIKE '%Native%'
         OR source LIKE '%native%' THEN 'Native Ads'

    -- Intent Ads
    WHEN source LIKE '%intent%'
         OR source LIKE '%Intent%' THEN 'Intent Ads'

    -- Email (including Salesforce Marketing Cloud)
    WHEN source = 'email'
         OR source = 'sfmc'
         OR medium = 'email' THEN 'Email'

    -- SMS
    WHEN source = 'SMS'
         OR source LIKE '%sms%' THEN 'SMS'

    -- Viber
    WHEN LOWER(source) LIKE '%viber%' THEN 'Viber'

    -- Yandex
    WHEN source = 'yandex'
         OR source LIKE '%yandex%' THEN 'Yandex'

    -- Bing Organic
    WHEN source = 'bing' AND medium = 'organic' THEN 'Bing Organic'

    -- Referral
    WHEN medium = 'referral' THEN 'Referral'

    -- Adfox (video ads)
    WHEN source = 'adfox' THEN 'Adfox Video'

    ELSE 'Other'
  END AS channel_group,

  -- PRODUCT CATEGORY (FIXED - better pattern matching)
  CASE
    -- Support/Info FIRST (before other categories that might overlap)
    WHEN page_location LIKE '%/contact-us%'
         OR page_location LIKE '%/contact%'
         OR page_location LIKE '%/faq%'
         OR page_location LIKE '%/about-inecobank%'
         OR page_location LIKE '%/useful-information%'
         OR page_location LIKE '%/career%'
         OR page_location LIKE '%/press-center%'
         OR page_location LIKE '%/shareholders%'
         OR page_location LIKE '%/corporate-governance%'
         OR page_location LIKE '%/reports%' THEN 'Support & Info'

    -- Consumer Loans (1-click, sprint, refinance)
    WHEN page_location LIKE '%consumer-loans%'
         OR page_location LIKE '%1-click%'
         OR page_location LIKE '%sprint%'
         OR page_location LIKE '%refinance%'
         OR page_location LIKE '%refinans%' THEN 'Consumer Loans'

    -- Car Loans
    WHEN page_location LIKE '%car-loan%'
         OR page_location LIKE '%avtovark%' THEN 'Car Loans'

    -- Mortgage
    WHEN page_location LIKE '%mortgage%' THEN 'Mortgage'

    -- Deposits
    WHEN page_location LIKE '%deposit%' THEN 'Deposits'

    -- Cards
    WHEN page_location LIKE '%card%'
         OR page_location LIKE '%visa%'
         OR page_location LIKE '%mastercard%'
         OR page_location LIKE '%Mastercard%' THEN 'Cards'

    -- Digital Banking
    WHEN page_location LIKE '%inecomobile%'
         OR page_location LIKE '%inecoonline%' THEN 'Digital Banking'

    -- Accounts
    WHEN page_location LIKE '%account%' THEN 'Accounts'

    -- Business Banking
    WHEN page_location LIKE '%/Business%'
         OR page_location LIKE '%/business%' THEN 'Business'

    -- Salary Project
    WHEN page_location LIKE '%salary%' THEN 'Salary Project'

    -- Campaigns/Promos
    WHEN page_location LIKE '%christmas%'
         OR page_location LIKE '%black-friday%'
         OR page_location LIKE '%cyber-monday%'
         OR page_location LIKE '%pascali%'
         OR page_location LIKE '%new-year%' THEN 'Campaigns'

    -- Homepage
    WHEN page_location LIKE '%inecobank.am/hy%'
         OR page_location LIKE '%inecobank.am/en%'
         OR page_location LIKE '%inecobank.am/ru%'
         OR REGEXP_CONTAINS(page_location, r'inecobank\.am/?$') THEN 'Homepage'

    -- User Account
    WHEN page_location LIKE '%user-info%'
         OR page_location LIKE '%personal-info%'
         OR page_location LIKE '%provision%'
         OR page_location LIKE '%sign-in%' THEN 'User Account'

    ELSE 'Other'
  END AS product_category

FROM base;
