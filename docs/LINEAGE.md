---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: When schema or marts change
---

# Ineco Analytics - Data Lineage

> Source → transform → target dependency graph (Star Schema)

---

## High-Level Lineage

```
RAW                              STAGING                         MARTS (Star Schema)
────                             ───────                         ────────────────────

events_*  ──────────────────────►  stg_events  ────────────────┬──► dim_date (static)
                                     (view)                     ├──► dim_channel
                                                                ├──► dim_product (static)
                                                                ├──► fact_sessions
                                                                └──► fact_conversions

ad_spend  ─────────────────────────────────────────────────────────► fact_ad_spend (direct)

bank_conversions ───────────────►  stg_bank_conversions          (future use)
```

---

## Star Schema Design

```
                    ┌─────────────┐
                    │  dim_date   │
                    │  (1,095)    │
                    └──────┬──────┘
                           │
┌─────────────┐    ┌───────┴───────┐    ┌─────────────┐
│ dim_channel │────│ fact_sessions │────│ dim_product │
│    (33)     │    │   (28,899)    │    │    (14)     │
└─────────────┘    └───────┬───────┘    └─────────────┘
       │                   │                   │
       │           ┌───────┴───────┐           │
       └───────────│fact_conversions├───────────┘
                   │   (19,855)    │
                   └───────┬───────┘
                           │
                   ┌───────┴───────┐
                   │ fact_ad_spend │ ◄── ad_spend (direct)
                   │     (0)       │
                   └───────────────┘
```

---

## Source-to-Mart Map

| Raw Source | Staging | Mart Tables | Join Pattern |
|------------|---------|-------------|--------------|
| events_* | stg_events | dim_channel, fact_sessions, fact_conversions | Direct read |
| (date spine) | — | dim_date | Generated (2025-2027) |
| (static) | — | dim_product | Manually defined |
| ad_spend | (no staging) | fact_ad_spend | Direct insert |
| bank_conversions | stg_bank_conversions | (future) | — |

**Important:** ad_spend does NOT flow through stg_events. It populates `fact_ad_spend` directly.

---

## Refresh Order & Dependencies

### Daily Refresh (fact tables)
All facts read from **stg_events**. No fact-to-fact dependencies.

```
1. fact_sessions      ← stg_events (aggregated by date/channel/device/product/user_type)
2. fact_conversions   ← stg_events (funnel events by date/channel/device/product)
```

### Weekly/On-Demand Refresh (dimension tables)
```
1. dim_channel        ← stg_events (DISTINCT source_clean, channel_group)
2. dim_date           ← Generated (only if extending date range)
3. dim_product        ← Static (only if adding new products)
```

### Ad Spend (when API integrated)
```
1. fact_ad_spend      ← Google Ads API, Meta API, etc.
```

**Parallelization:** All refreshes can run in parallel (no inter-table dependencies).

---

## Column Lineage (Key Metrics)

| Metric | Origin (raw) | Transform (staging) | Fact Table |
|--------|-------------|---------------------|------------|
| sessions | user_pseudo_id + session_id | COUNT DISTINCT | fact_sessions |
| users | user_pseudo_id | COUNT DISTINCT | fact_sessions |
| new_users | session_number = 1 | COUNT DISTINCT | fact_sessions |
| bounced_sessions | pageviews=1 AND engagement<10s | COUNT | fact_sessions |
| pageviews | event_name='page_view' | COUNT | fact_sessions |
| registrations | event_name='registration_success' | COUNT DISTINCT user | fact_conversions |
| loans_apply_click | event_name='sprint_apply_button_click' | COUNT DISTINCT user | fact_conversions |
| loans_sub_id | event_name='Get Sub ID sprint' | COUNT DISTINCT user | fact_conversions |
| loans_check_limit | event_name='check_limit_click' | COUNT DISTINCT user | fact_conversions |
| cards_deposits_apply_click | event_name='Reg_apply_button_click' | COUNT DISTINCT user | fact_conversions |
| cards_deposits_sub_id | event_name='Get Sub ID' | COUNT DISTINCT user | fact_conversions |

---

## Dimension Lineage

| Dimension | Source | Derived Columns |
|-----------|--------|-----------------|
| dim_date | GENERATE_DATE_ARRAY() | year, quarter, month, week, is_weekend, is_holiday |
| dim_channel | stg_events DISTINCT | channel_type, is_paid, channel_category |
| dim_product | Static definition | product_group, has_funnel, apply_event, sub_id_event |

---

## Impact Analysis

**If stg_events view changes:**
- fact_sessions, fact_conversions, dim_channel affected
- Re-run full refresh
- Verify Superset charts
- Update DATA_DICTIONARY.md and METRIC_CONTRACTS.md

**If new channel appears:**
- dim_channel auto-updates on refresh
- No manual intervention needed

**If new product added:**
- Update dim_product manually
- Add product_category logic to stg_events if needed
- Update DATA_DICTIONARY.md

**If ad_spend schema changes:**
- fact_ad_spend only
- Update load script
- Verify cost-related charts

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-02-14 | v3: Migrated to Star Schema (6 tables from 17) | Analytics Team |
| 2026-02-14 | v2: Fixed ad_spend lineage | Analytics Team |
| 2026-02-14 | v1: Initial version | Analytics Team |
