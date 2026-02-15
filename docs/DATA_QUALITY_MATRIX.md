---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Monthly
---

# Ineco Analytics - Data Quality Matrix

> Tests, thresholds, owners, and alerting for data quality

---

## Test Inventory

### Staging Layer (stg_events)

| Test ID | Test Name | Rule | Threshold | Alert | Owner | Automated |
|---------|-----------|------|-----------|-------|-------|-----------|
| STG-01 | Row count not zero | `COUNT(*) WHERE event_date = CURRENT_DATE()` | > 0 | If 0 for 2 consecutive days | Analytics | No (manual) |
| STG-02 | event_name not null | `COUNT(*) WHERE event_name IS NULL` | = 0 | If > 0 | Analytics | No (manual) |
| STG-03 | user_pseudo_id not null | `COUNT(*) WHERE user_pseudo_id IS NULL` | = 0 | If > 0 | Analytics | No (manual) |
| STG-04 | session_id not null | `COUNT(*) WHERE session_id IS NULL` | = 0 | If > 0 | Analytics | No (manual) |
| STG-05 | Valid channel_group | `channel_group IN (allowed list)` | 100% | If unknown values > 1% of events | Analytics | No (manual) |

**Allowed channel_group values:** See BUSINESS_GLOSSARY.md for the complete list. Key values: Direct, Google Organic, Google Ads, Meta Ads, NN Ads, MS Network, Native Ads, Intent Ads, Prodigi Ads, Email, SMS, Viber, Yandex, LinkedIn, Telegram, Other. Additional passthrough values may exist for unmapped sources.

---

### Mart Layer

| Test ID | Table | Test Name | Rule | Threshold | Alert | Automated |
|---------|-------|-----------|------|-----------|-------|-----------|
| MART-01 | mart_daily_overview | Row count drop | Compare row count to prior 7-day avg | Drop < 30% | If drop >= 30% | No (manual) |
| MART-02 | mart_daily_overview | Max date freshness | `MAX(event_date)` | = yesterday or today | If older than 2 days | No (manual) |
| MART-03 | mart_gm_channel_daily | Sessions sanity | `SUM(sessions)` for latest date | > 0 | If 0 for all channels | No (manual) |
| MART-04 | mart_product_funnel | Registrations sanity | `SUM(step7_registered)` | Dynamic: within 50% of 30-day rolling avg | If outside band | No (manual) |
| MART-05 | mart_engagement | Bounce rate range | `AVG(bounce_rate)` | 0–100 | If outside 0–100 | No (manual) |
| MART-06 | All marts | Refresh completeness | `mart_status.json` | 17 success | If any failed | Yes (exit code) |
| MART-07 | All marts | No duplicate rows | `COUNT(*) = COUNT(DISTINCT key_columns)` | Exact match | If duplicates found | No (manual) |

**Note on MART-04:** The static threshold (400-800) was replaced with a dynamic band (50% of rolling average) to account for natural growth/decline over time.

---

### Ad Spend Layer

| Test ID | Table | Test Name | Rule | Threshold | Alert | Automated |
|---------|-------|-----------|------|-----------|-------|-----------|
| AD-01 | ad_spend | Row count | `COUNT(*) WHERE date = CURRENT_DATE()-1` | > 0 when Airbyte active | If missing for active platform | No (future) |
| AD-02 | ad_spend | Negative cost | `COUNT(*) WHERE cost < 0` | = 0 | If any negative | No (future) |

---

## Refresh Script Validation

Integrated into `refresh_marts.py`:

| Check | Action on Failure |
|-------|-------------------|
| Any mart CREATE fails | Log error, continue other marts, set exit code 1 |
| Exit code 1 | Cron captures; triggers alert if Cloud Monitoring configured |
| Status written to mart_status.json | `failed` count tracked; parseable by monitoring |

---

## Alert Configuration

### Current (implemented)

| Alert | Method | Status |
|-------|--------|--------|
| Mart refresh failure | Exit code + log file | **Active** |
| Status JSON | `mart_status.json` with pass/fail per mart | **Active** |

### Recommended (not yet implemented)

| Alert | Method | Status |
|-------|--------|--------|
| GCP Uptime check on Superset URL | Cloud Monitoring | **Not implemented** |
| Log-based alert: "FAILED" in refresh log | Cloud Monitoring | **Not implemented** |
| Slack/email notification on failure | Cloud Function trigger | **Not implemented** |

---

## Data Freshness SLA

| Dataset | Expected Freshness | Check Method |
|---------|-------------------|--------------|
| ineco_raw.events_* | Same day (GA4 streaming export) | `MAX(event_date)` |
| ineco_staging.stg_events | Same day (view on raw) | Depends on raw |
| ineco_marts.* | T+1 (refreshed daily at 6 AM) | `MAX(date) = yesterday` |
| ineco_raw.ad_spend | T+1 (when Airbyte active) | `MAX(date)` |

---

## Test Implementation

### Manual SQL (run periodically or after changes)

```sql
-- STG-01: Row count for today
SELECT COUNT(*) as cnt
FROM `x-victor-477214-g0.ineco_staging.stg_events`
WHERE event_date = CURRENT_DATE();

-- STG-04: session_id nulls
SELECT COUNTIF(session_id IS NULL) as null_sessions
FROM `x-victor-477214-g0.ineco_staging.stg_events`;

-- MART-02: Max date freshness
SELECT MAX(event_date) as max_date
FROM `x-victor-477214-g0.ineco_marts.mart_daily_overview`;

-- MART-04: Registration sanity (dynamic)
SELECT SUM(step7_registered) as total_reg
FROM `x-victor-477214-g0.ineco_marts.mart_product_funnel`;

-- MART-07: Duplicate check (example for mart_daily_overview)
SELECT event_date, COUNT(*) as cnt
FROM `x-victor-477214-g0.ineco_marts.mart_daily_overview`
GROUP BY 1 HAVING cnt > 1;
```

### Future: Automated

- **Option A:** Add `validate_marts()` function to `refresh_marts.py` (run after refresh)
- **Option B:** Introduce dbt project with schema tests
- **Priority:** See ROADMAP for implementation timeline

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-02-14 | v2: Added Automated column; dynamic MART-04 threshold; MART-07 duplicates; AD-01/AD-02; separated current vs recommended alerts; aligned channel list with BUSINESS_GLOSSARY | Analytics Team |
| 2026-02-14 | v1: Initial version | Analytics Team |
