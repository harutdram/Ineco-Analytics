# Google Ads → BigQuery Data Transfer Setup

## Overview

This guide sets up automatic daily sync of Google Ads data directly to BigQuery using Google's native Data Transfer Service.

```
┌──────────────┐      ┌─────────────────────┐      ┌──────────────┐
│  Google Ads  │ ───→ │  Data Transfer      │ ───→ │   BigQuery   │
│   Account    │      │  Service (free)     │      │  ineco_raw   │
└──────────────┘      └─────────────────────┘      └──────────────┘
                              │
                         Daily sync
                         (automatic)
```

## Prerequisites

- [ ] Google Ads account (Customer ID)
- [ ] BigQuery admin access in `x-victor-477214-g0` project
- [ ] Google Ads admin access (to authorize connection)

---

## Step 1: Enable the Data Transfer API

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: `x-victor-477214-g0`
3. Navigate to: **APIs & Services → Library**
4. Search for: **"BigQuery Data Transfer API"**
5. Click **Enable**

---

## Step 2: Create the Transfer

1. Go to [BigQuery Console](https://console.cloud.google.com/bigquery)
2. In left sidebar, click **"Data transfers"**
3. Click **"+ CREATE TRANSFER"**

### Transfer Configuration:

| Field | Value |
|-------|-------|
| **Source** | Google Ads |
| **Display name** | `ineco-google-ads-daily` |
| **Schedule** | Daily, 06:00 AM (or preferred time) |
| **Destination dataset** | `ineco_raw` |
| **Customer ID** | *[Ineco's Google Ads Customer ID]* |

### Customer ID Format:
- Found in Google Ads UI (top right corner)
- Format: `123-456-7890` (enter without dashes: `1234567890`)

4. Click **"Save"**
5. **Authorize** when prompted (requires Google Ads admin login)

---

## Step 3: Run Initial Backfill

After creating the transfer:

1. Click on the transfer name
2. Click **"Run transfer now"**
3. Select date range for historical data (e.g., last 90 days)
4. Click **"Run"**

First sync takes 10-30 minutes depending on data volume.

---

## Step 4: Verify Data

After transfer completes, run in BigQuery:

```sql
-- Check tables created
SELECT table_name, row_count
FROM `x-victor-477214-g0.ineco_raw.INFORMATION_SCHEMA.TABLES`
WHERE table_name LIKE 'ads_%'
ORDER BY table_name;
```

### Expected Tables:

| Table | Description |
|-------|-------------|
| `ads_Campaign_*` | Campaign-level metrics |
| `ads_AdGroup_*` | Ad group metrics |
| `ads_Ad_*` | Individual ad performance |
| `ads_CampaignStats_*` | Daily campaign statistics |
| `ads_GeoStats_*` | Geographic performance |
| `ads_Keyword_*` | Keyword performance |

---

## Step 5: Create Mart Table

Once data is flowing, we'll create a mart table to standardize the format.

Create file `bigquery/marts/fact_ad_spend_google.sql`:

```sql
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_ad_spend_google` AS
SELECT
  _DATA_DATE as date,
  'Google Ads' as channel_group,
  campaign_name as campaign,
  ad_group_name as ad_group,
  CAST(impressions AS FLOAT64) as impressions,
  CAST(clicks AS FLOAT64) as clicks,
  CAST(cost_micros AS FLOAT64) / 1000000 as spend_usd,
  (CAST(cost_micros AS FLOAT64) / 1000000) * 400 as spend_amd,  -- USD to AMD
  SAFE_DIVIDE(clicks, impressions) * 100 as ctr,
  SAFE_DIVIDE(cost_micros / 1000000, clicks) as cpc,
  SAFE_DIVIDE(cost_micros / 1000000, impressions) * 1000 as cpm,
  conversions,
  SAFE_DIVIDE(cost_micros / 1000000, conversions) as cost_per_conversion
FROM `x-victor-477214-g0.ineco_raw.ads_CampaignStats_*`
WHERE _DATA_DATE >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY);
```

---

## Step 6: Merge with Existing Ad Spend

Update the main `fact_ad_spend` to include Google Ads:

```sql
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.fact_ad_spend` AS

-- Facebook Ads (from Airbyte)
SELECT
  date,
  channel_group,
  campaign,
  NULL as ad_group,
  impressions,
  clicks,
  spend_usd,
  spend_amd,
  ctr,
  cpc,
  cpm
FROM `x-victor-477214-g0.ineco_marts.fact_ad_spend_facebook`

UNION ALL

-- Google Ads (from Data Transfer)
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
  cpm
FROM `x-victor-477214-g0.ineco_marts.fact_ad_spend_google`;
```

---

## Monitoring

### Check Transfer Status:
1. Go to BigQuery → Data transfers
2. Click on `ineco-google-ads-daily`
3. View "Run history" tab

### Common Issues:

| Issue | Solution |
|-------|----------|
| "Permission denied" | Re-authorize with Google Ads admin account |
| "Customer ID not found" | Verify Customer ID (no dashes) |
| "No data" | Check if Google Ads has campaign data for the date range |
| Transfer failed | Check run history for error details |

---

## Schedule Summary

| Data Source | Sync Method | Frequency | Time |
|-------------|-------------|-----------|------|
| GA4 | Native Export | Real-time | Continuous |
| Google Ads | Data Transfer | Daily | 06:00 AM |
| Facebook | Airbyte | Every 6 hours | Auto |
| Bank Data | Manual script | On-demand | When file received |

---

## Data Flow After Setup

```
                    ┌─────────────────────────────────────┐
                    │           BigQuery                   │
                    │                                      │
 Google Ads ───────→│  ineco_raw.ads_*                    │
 (Data Transfer)    │         ↓                           │
                    │  ineco_marts.fact_ad_spend_google   │
                    │         ↓                           │
                    │  ineco_marts.fact_ad_spend ←────────│← Facebook
                    │         ↓                           │   (Airbyte)
                    │      Superset                       │
                    │    (ROAS Dashboard)                 │
                    └─────────────────────────────────────┘
```

---

## Status: COMPLETED ✅

**Setup completed on Feb 18, 2026:**
- ✅ Data Transfer configured and authorized
- ✅ 20+ tables created in `ineco_raw`
- ✅ Customer account data syncing (1 row)
- ⏳ Campaign data will appear when campaigns are launched

**Tables ready:**
- `p_ads_CampaignStats_8656917454`
- `p_ads_Campaign_8656917454`
- `p_ads_Customer_8656917454`
- And 17+ more...

## When Campaigns Launch

Data will flow automatically every 24 hours. To create the mart tables:

```bash
cd /Users/harut/Desktop/Ineco
bq query --use_legacy_sql=false < bigquery/marts/fact_ad_spend_google.sql
bq query --use_legacy_sql=false < bigquery/marts/fact_ad_spend_unified.sql
```

---

## Questions?

Contact: [Your contact info]

Once the transfer is running, we'll add Google Ads metrics to the Superset dashboards automatically.
