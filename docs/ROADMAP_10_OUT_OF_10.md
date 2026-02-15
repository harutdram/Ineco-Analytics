---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
---

# Data Architecture Roadmap: 10/10

> Path from current state to best-in-class analytics

---

## Current Score: 8.5/10 ✅

**Completed:**
- ✅ Star Schema (3 facts + 3 dimensions)
- ✅ Medallion architecture (Raw → Staging → Marts)
- ✅ Partitioned fact tables (cost optimization)
- ✅ Comprehensive documentation (11 files)
- ✅ Automated daily refresh

**Remaining:**
- ⏳ Incremental loading (MERGE vs full rebuild)
- ⏳ Automated data quality tests
- ⏳ CI/CD pipeline
- ⏳ Ad spend integration

---

## Current Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    INECO STAR SCHEMA (8.5/10)                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────────────────┐  │
│  │   RAW    │ →  │ STAGING  │ →  │    STAR SCHEMA               │  │
│  │ (Bronze) │    │ (Silver) │    │  ┌───────────────────────┐   │  │
│  └──────────┘    └──────────┘    │  │     DIMENSIONS        │   │  │
│       ↓              ↓           │  │  • dim_date (1,095)   │   │  │
│   events_*      stg_events       │  │  • dim_channel (33)   │   │  │
│   ad_spend      (view)           │  │  • dim_product (14)   │   │  │
│                                  │  └───────────────────────┘   │  │
│                                  │  ┌───────────────────────┐   │  │
│                                  │  │       FACTS           │   │  │
│                                  │  │  • fact_sessions      │   │  │
│                                  │  │  • fact_conversions   │   │  │
│                                  │  │  • fact_ad_spend      │   │  │
│                                  │  └───────────────────────┘   │  │
│                                  └──────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              DOCUMENTATION LAYER ✅                          │    │
│  │     (DATA_DICTIONARY, LINEAGE, GLOSSARY, RUNBOOK)           │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## The 10/10 Checklist

| # | Component | Status | Notes |
|---|-----------|--------|-------|
| 1 | **Star Schema** | ✅ Done | 3 facts + 3 dims (was 17 flat tables) |
| 2 | **Incremental Loading** | ⏳ Partial | Tables partitioned; MERGE logic TBD |
| 3 | **Data Quality Tests** | ⏳ Documented | Tests defined; automation TBD |
| 4 | **Data Freshness Alerts** | ⏳ Basic | Cron logs; Cloud Monitoring TBD |
| 5 | **Semantic Layer** | ✅ Docs | METRIC_CONTRACTS.md (not tooling) |
| 6 | **Documentation** | ✅ Done | 11 comprehensive documents |
| 7 | **Version Control** | ⏳ Local | GitHub push pending |
| 8 | **CI/CD Pipeline** | ❌ None | GitHub Actions TBD |
| 9 | **Row-Level Security** | ❌ None | Superset role TBD |
| 10 | **Ad Spend Integration** | ⏳ Structure | fact_ad_spend ready; APIs pending |

---

## What's Already Done (v3.0)

### Star Schema Tables

| Type | Table | Rows | Description |
|------|-------|------|-------------|
| **DIM** | dim_date | 1,095 | Calendar 2025-2027, Armenian holidays |
| **DIM** | dim_channel | 33 | 24 sources × channel groups |
| **DIM** | dim_product | 14 | Products with funnel definitions |
| **FACT** | fact_sessions | 28,899 | Sessions, users, engagement |
| **FACT** | fact_conversions | 19,855 | Funnel steps by channel/product |
| **FACT** | fact_ad_spend | 0 | Ready for ad network data |

### Superset Setup

- 6 datasets registered
- 20 charts created
- 4 dashboards configured

---

## Remaining Work to 10/10

### Priority 1: Incremental Loading (Cost Savings)

**Current:** Full table rebuild daily (~20 GB scanned)

**Target:**
```sql
MERGE INTO fact_sessions target
USING (
  SELECT * FROM aggregated_new_data
  WHERE date >= CURRENT_DATE() - 7
) source
ON target.date = source.date 
   AND target.channel_group = source.channel_group
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...
```

**Benefit:** ~80% cost reduction

---

### Priority 2: Automated Data Quality Tests

Add to `refresh_marts.py`:

```python
def run_quality_checks():
    checks = [
        ("NULL sessions", "SELECT COUNT(*) FROM fact_sessions WHERE sessions IS NULL"),
        ("Negative users", "SELECT COUNT(*) FROM fact_sessions WHERE users < 0"),
        ("Row count drop", "SELECT CASE WHEN COUNT(*) < 10000 THEN 1 ELSE 0 END FROM fact_sessions"),
    ]
    for name, sql in checks:
        result = client.query(sql).result()
        if list(result)[0][0] > 0:
            send_alert(f"Data quality check failed: {name}")
```

---

### Priority 3: GitHub + CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy to BigQuery
on:
  push:
    branches: [main]
    paths: ['bigquery/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/auth@v1
      - run: python bigquery/refresh_marts.py
```

---

### Priority 4: Ad Spend Integration

Waiting on:
- Google Ads API credentials (Developer Token)
- Meta Marketing API access token
- LinkedIn Campaign Manager API

Once available, populate `fact_ad_spend` daily.

---

## How This Compares to Big Tech

| Company | Approach | Our Status |
|---------|----------|------------|
| **Airbnb** | ~10 core fact tables, dbt | ✅ We have 3 facts |
| **Spotify** | Event-sourced, ~5 entities | ✅ Similar scale |
| **Uber** | Real-time + batch, partitioned | ✅ Partitioned |
| **Netflix** | Wide denormalized tables | N/A (we use star) |

**Our architecture is now comparable to early-stage data teams at major tech companies.**

---

## Timeline to 10/10

| Task | Effort | Impact |
|------|--------|--------|
| Incremental loading | 2-3 hours | Cost -80% |
| Quality tests | 1-2 hours | Reliability |
| GitHub push | 30 min | Version control |
| CI/CD pipeline | 2-3 hours | Automation |
| Ad spend APIs | External dependency | ROI metrics |

**Estimated:** 1 day of work + waiting for ad network credentials

---

## References

- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
