---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
---

# Ineco Analytics - Data Architecture

> Documentation for BigQuery data warehouse and Superset dashboards

---

## Current Architecture (Star Schema)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     INECO DATA ARCHITECTURE (Star Schema)                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   RAW (Bronze)          STAGING (Silver)         MARTS (Gold)               │
│   ─────────────         ──────────────           ─────────────              │
│   • events_*            • stg_events             DIMENSIONS:                │
│   • ad_spend            • stg_bank_conversions   • dim_date                 │
│   • bank_conversions                             • dim_channel              │
│                                                  • dim_product              │
│   Untouched             Cleaned &                FACTS:                     │
│   source data           transformed              • fact_sessions            │
│                                                  • fact_conversions         │
│                                                  • fact_ad_spend            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Star Schema Design

| Table Type | Table Name | Rows | Description |
|------------|------------|------|-------------|
| **Dimension** | `dim_date` | 1,095 | Calendar with holidays, week numbers |
| **Dimension** | `dim_channel` | 33 | Source/channel mappings with paid/organic flags |
| **Dimension** | `dim_product` | 14 | Product definitions with funnel events |
| **Fact** | `fact_sessions` | ~29K | Session/user metrics (partitioned by date) |
| **Fact** | `fact_conversions` | ~20K | Funnel progression (partitioned by date) |
| **Fact** | `fact_ad_spend` | 0 | Ad costs (awaiting API integration) |

### Why Star Schema?

| Benefit | Description |
|---------|-------------|
| **Single Source of Truth** | Each metric defined once in fact tables |
| **Flexibility** | JOIN dimensions for any slice-and-dice |
| **Performance** | Partitioned by date, clustered by channel/product |
| **Maintainability** | 6 tables vs 17 (easier to understand and debug) |
| **Industry Standard** | Kimball methodology (recognized best practice) |

---

## Layers

| Layer | Dataset | Location | Purpose |
|-------|---------|----------|---------|
| **Raw** | `ineco_raw` | EU | Unmodified data from source systems (GA4, ad platforms) |
| **Staging** | `ineco_staging` | EU | Cleaned, deduplicated, standardized. Single source of truth. |
| **Marts** | `ineco_marts` | EU | Star schema (facts + dimensions) for Superset dashboards |

---

## Infrastructure

| Component | Details |
|-----------|---------|
| **GCP Project** | `x-victor-477214-g0` |
| **BigQuery Location** | EU (multi-region) |
| **VM** | `superset-ineco` (us-central1-a, e2-standard-2) |
| **Superset** | Docker Compose on VM, port 8088 |
| **HTTPS** | Not yet configured (pending domain from Ineco IT) |

---

## Data Flow

```
GA4 Events (streaming export)        Ad Platforms (via API, future)
     │                                      │
     ▼                                      ▼
┌──────────┐                        ┌──────────────┐
│ events_* │                        │  ad_spend    │
│ (raw)    │                        │  (raw)       │
└────┬─────┘                        └──────┬───────┘
     │                                      │
     ▼                                      │
┌────────────────────────┐                  │
│      stg_events        │                  │
│   (view: cleaned)      │                  │
│   - source_clean       │                  │
│   - channel_group      │                  │
│   - product_category   │                  │
└────────────┬───────────┘                  │
             │                              │
             ▼                              ▼
┌─────────────────────────────────────────────────┐
│                 STAR SCHEMA                      │
│  ┌───────────────┐  ┌───────────────────────┐   │
│  │  DIMENSIONS   │  │        FACTS          │   │
│  ├───────────────┤  ├───────────────────────┤   │
│  │ dim_date      │  │ fact_sessions         │   │
│  │ dim_channel   │  │ fact_conversions      │   │
│  │ dim_product   │  │ fact_ad_spend ←───────┼───┘
│  └───────────────┘  └───────────────────────┘   │
└─────────────────────┬───────────────────────────┘
                      │
                      ▼
          ┌────────────────────────┐
          │      SUPERSET           │
          │   Dashboards & Charts   │
          └────────────────────────┘
```

---

## Refresh Schedule

| Component | Schedule | Method |
|-----------|----------|--------|
| Raw data (GA4) | Continuous | BigQuery streaming export |
| Fact tables | Daily 6:00 AM UTC | `refresh_marts.py` via cron |
| Dimension tables | Weekly (or on-demand) | Manual refresh if new channels/products |
| Superset | On page load | Queries fact/dimension tables |

---

## BigQuery Cost Model

Pricing: $5/TB scanned (on-demand)

| Component | Daily GB | Daily Cost | Monthly Cost |
|-----------|----------|------------|--------------|
| Fact refresh (2 tables) | ~20 GB | ~$0.10 | ~$3 |
| Dimension refresh | ~1 GB | ~$0.005 | ~$0.15 |
| Superset queries | ~1-2 GB | ~$0.01 | ~$0.30 |
| **Total** | ~23 GB | ~$0.12 | **~$3-4** |

**Note:** Star schema reduces costs ~60% vs. previous 17-table architecture by eliminating redundant aggregations.

BigQuery free tier: 1 TB/month. Current usage (~70 GB/month) is well under.

---

## Known Limitations

- **No HTTPS** — Superset accessible over HTTP only; pending domain + SSL setup
- **No incremental refresh** — Full table rebuild daily; MERGE logic planned for future
- **Apply Click tracking gap** — ~82% of users bypass the Apply Click event; see METRIC_CONTRACTS.md
- **Ad spend empty** — `fact_ad_spend` awaiting ad network API credentials
