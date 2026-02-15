---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
---

# Data Dictionary

> Column-level definitions for all BigQuery tables

---

## Star Schema Overview

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴───────┐    ┌─────────────┐
│ dim_channel │────│ fact_sessions │────│ dim_product │
└─────────────┘    │     AND       │    └─────────────┘
                   │fact_conversions│
                   └───────────────┘
```

---

## Dimension Tables

### dim_date
Calendar dimension for time-based analysis.

| Column | Type | Description |
|--------|------|-------------|
| `date_key` | DATE | Primary key (same as date) |
| `date` | DATE | Calendar date |
| `year` | INTEGER | Year (e.g., 2026) |
| `quarter` | INTEGER | Quarter (1-4) |
| `month` | INTEGER | Month (1-12) |
| `month_name` | STRING | Month name (January, February, etc.) |
| `week_of_year` | INTEGER | ISO week number (1-53) |
| `day_of_week` | INTEGER | Day of week (1=Sunday, 7=Saturday) |
| `day_name` | STRING | Day name (Monday, Tuesday, etc.) |
| `day_of_month` | INTEGER | Day of month (1-31) |
| `week_start` | DATE | Monday of the week |
| `month_start` | DATE | First day of month |
| `quarter_start` | DATE | First day of quarter |
| `is_weekend` | BOOLEAN | TRUE if Saturday or Sunday |
| `is_holiday` | BOOLEAN | TRUE if Armenian public holiday |

---

### dim_channel
Channel/source dimension for traffic analysis.

| Column | Type | Description |
|--------|------|-------------|
| `channel_key` | INTEGER | Surrogate key |
| `source_clean` | STRING | Standardized source (e.g., Google, Meta, NN Ads) |
| `channel_group` | STRING | Marketing channel (e.g., Google Ads, Google Organic) |
| `channel_type` | STRING | High-level type: Paid, Organic Search, CRM, Direct, Referral, Other |
| `is_paid` | BOOLEAN | TRUE if paid advertising channel |
| `channel_category` | STRING | Grouping: Google, Meta, Local Ad Networks, Direct Messaging, Other Search |

**Source Clean Values (24):**
Direct, Google, Bing, Yahoo, Yandex, Meta, NN Ads, MS Network, Native Ads, Intent Ads, Prodigi Ads, Adfox, LinkedIn, Email, SMS, Viber, Telegram, Survey, Mastercard Promo, Internal, Armenian Sites, AI Tools, Data Not Available, Other

---

### dim_product
Product dimension for Ineco banking products.

| Column | Type | Description |
|--------|------|-------------|
| `product_key` | INTEGER | Primary key (1-14) |
| `product_name` | STRING | Product name (e.g., Consumer Loans, Cards) |
| `product_group` | STRING | Product group: Loans, Cards, Deposits, Services, Business, Marketing, General, Other |
| `description` | STRING | Product description |
| `has_funnel` | BOOLEAN | TRUE if product has conversion funnel tracking |
| `apply_event` | STRING | GA4 event for apply button click (NULL if no funnel) |
| `sub_id_event` | STRING | GA4 event for sub ID generation |
| `check_limit_event` | STRING | GA4 event for limit check (loans only) |

**Products with Funnels:**
- Consumer Loans (Sprint funnel)
- Car Loans (Sprint funnel)
- Mortgage (Sprint funnel)
- Cards (Registration funnel)
- Deposits (Registration funnel)

---

## Fact Tables

### fact_sessions
Session and user engagement metrics. Partitioned by date, clustered by channel_group and product_category.

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Event date (partition key) |
| `source_clean` | STRING | FK to dim_channel.source_clean |
| `channel_group` | STRING | Marketing channel |
| `device_category` | STRING | desktop, mobile, tablet |
| `product_category` | STRING | FK to dim_product.product_name |
| `user_type` | STRING | New or Returning |
| `users` | INTEGER | Unique users (COUNT DISTINCT user_pseudo_id) |
| `new_users` | INTEGER | First-time users (session_number = 1) |
| `sessions` | INTEGER | Total sessions |
| `bounced_sessions` | INTEGER | Sessions with 1 pageview and <10s engagement |
| `pageviews` | INTEGER | Total page views |
| `avg_session_duration_sec` | FLOAT | Average engagement time per session |
| `avg_pages_per_session` | FLOAT | Average pages viewed per session |

**Grain:** One row per date + source_clean + channel_group + device_category + product_category + user_type

---

### fact_conversions
Funnel progression and conversion metrics. Partitioned by date, clustered by channel_group and product_category.

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Event date (partition key) |
| `source_clean` | STRING | FK to dim_channel.source_clean |
| `channel_group` | STRING | Marketing channel |
| `device_category` | STRING | desktop, mobile, tablet |
| `product_category` | STRING | FK to dim_product.product_name |
| `total_users` | INTEGER | Unique users in this segment |
| `total_sessions` | INTEGER | Total sessions |
| **Loans Funnel** | | |
| `loans_pageview` | INTEGER | Users viewing loan pages |
| `loans_apply_click` | INTEGER | Users clicking sprint apply button |
| `loans_sub_id` | INTEGER | Users getting Sub ID in sprint |
| `loans_check_limit` | INTEGER | Users checking approved limits |
| `loans_phone_submit` | INTEGER | Users submitting phone |
| `loans_otp_submit` | INTEGER | Users submitting OTP |
| **Cards/Deposits Funnel** | | |
| `cards_deposits_pageview` | INTEGER | Users viewing cards/deposits pages |
| `cards_deposits_apply_click` | INTEGER | Users clicking registration apply |
| `cards_deposits_sub_id` | INTEGER | Users getting Sub ID |
| **Final Conversion** | | |
| `registrations` | INTEGER | Users completing registration |

**Grain:** One row per date + source_clean + channel_group + device_category + product_category

---

### fact_ad_spend
Advertising cost data from ad platforms. Partitioned by date, clustered by channel_group.

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Spend date (partition key) |
| `channel_group` | STRING | Marketing channel (Google Ads, Meta Ads, etc.) |
| `campaign` | STRING | Campaign name |
| `impressions` | FLOAT | Ad impressions |
| `clicks` | FLOAT | Ad clicks |
| `spend_usd` | FLOAT | Ad spend in USD |
| `spend_amd` | FLOAT | Ad spend in AMD |

**Status:** Empty — awaiting ad network API credentials

---

## Staging Tables

### stg_events (VIEW)
Cleaned GA4 events with standardized fields.

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `event_date` | DATE | Parsed from event_date | Event date |
| `event_timestamp` | TIMESTAMP | TIMESTAMP_MICROS() | Event timestamp |
| `event_name` | STRING | event_name | GA4 event name |
| `user_pseudo_id` | STRING | user_pseudo_id | GA4 client ID (cookie) |
| `user_id` | STRING | user_id | Authenticated user ID |
| `session_id` | INTEGER | event_params.ga_session_id | Session identifier |
| `session_number` | INTEGER | event_params.ga_session_number | Session sequence (1 = new user) |
| `page_location` | STRING | event_params.page_location | Full page URL |
| `page_title` | STRING | event_params.page_title | Page title |
| `page_referrer` | STRING | event_params.page_referrer | Referrer URL |
| `source` | STRING | traffic_source.source | Raw traffic source |
| `medium` | STRING | traffic_source.medium | Traffic medium |
| `campaign` | STRING | traffic_source.name | UTM campaign |
| `access_token_sub_id` | STRING | event_params.Access Token Sub ID | Sprint/Reg sub ID |
| `engagement_time_msec` | INTEGER | event_params.engagement_time_msec | Time engaged (ms) |
| `session_engaged` | INTEGER | event_params.session_engaged | 1 if engaged session |
| `device_category` | STRING | device.category | desktop, mobile, tablet |
| `device_brand` | STRING | device.mobile_brand_name | Device manufacturer |
| `device_os` | STRING | device.operating_system | OS name |
| `browser` | STRING | device.web_info.browser | Browser name |
| `country` | STRING | geo.country | Country |
| `city` | STRING | geo.city | City |
| `platform` | STRING | platform | Platform (web, ios, android) |
| `source_clean` | STRING | CASE logic | Standardized source (24 values) |
| `channel_group` | STRING | CASE logic | Marketing channel |
| `product_category` | STRING | CASE logic | Product based on page URL |

---

## Relationships

```
dim_date.date ←──────────── fact_sessions.date
                            fact_conversions.date
                            fact_ad_spend.date

dim_channel.source_clean ←─ fact_sessions.source_clean
                            fact_conversions.source_clean

dim_channel.channel_group ← fact_sessions.channel_group
                            fact_conversions.channel_group
                            fact_ad_spend.channel_group

dim_product.product_name ←─ fact_sessions.product_category
                            fact_conversions.product_category
```
