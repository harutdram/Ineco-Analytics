---
owner: Analytics Team
last_updated: 2026-02-14
---

# Documentation Changelog

> Version history for Ineco analytics documentation

---

## 2026-02-14 — v3.0 (Star Schema Migration)

**Major architectural change:**
- Migrated from 17 flat mart tables to Star Schema (6 tables)
- Created 3 dimension tables: dim_date, dim_channel, dim_product
- Created 3 fact tables: fact_sessions, fact_conversions, fact_ad_spend
- Deleted all 17 legacy mart_* tables

**Benefits:**
- Single source of truth for each metric
- Flexible querying via JOINs
- ~60% reduction in BigQuery costs
- Industry-standard Kimball methodology

**Updated documentation:**
- ARCHITECTURE.md: New star schema diagram, updated cost model
- DATA_DICTIONARY.md: Full schemas for all 6 tables
- LINEAGE.md: Updated dependency graph for star schema
- Local SQL files created in bigquery/marts/

**Superset rebuilt:**
- 6 new datasets (dim_date, dim_channel, dim_product, fact_sessions, fact_conversions, fact_ad_spend)
- 20 new charts using star schema
- 4 dashboards updated with new charts

---

## 2026-02-14 — v2.1 (92+ fixes)

**Fixed — cross-document inconsistencies:**
- LINEAGE.md: Corrected diagram — ad_spend does NOT flow through stg_events; joins at mart layer
- ARCHITECTURE.md: Corrected data flow diagram; added infrastructure table, BQ location, known limitations
- DATA_DICTIONARY.md: Added 6 missing stg_events columns; added mart_product_funnel, mart_engagement, mart_weekly_comparison schemas; added Ineco Russian terms to funnel definitions
- BUSINESS_GLOSSARY.md: Added all source_clean channels (AI Tools, Armenian Sites, etc.); added Ineco's own definitions in Russian; added CPS metric
- METRIC_CONTRACTS.md: Fixed Bounce Rate to real SQL; fixed CPS label (was "CPR"); added New Users, Pageviews; added Known Data Gaps section; aligned Sessions formula to COUNT(DISTINCT session_id)
- DATA_QUALITY_MATRIX.md: Added "Automated" column; dynamic MART-04 threshold; added MART-07 duplicates, AD-01/AD-02; separated current vs recommended alerts; aligned channel list reference
- SECURITY_AND_GOVERNANCE.md: Fixed retention (BQ export has no auto-expiry); fixed user_pseudo_id (random, not hash); added network security section; added HTTPS gap; added action items table with owners
- RUNBOOK.md: Added cron verification; health check curl; BQ time travel rollback; backup restore steps; doc update reminders in procedures; escalation contacts placeholder
- README.md: Removed hardcoded IP; added infrastructure reference table; added contributing guidelines

---

## 2026-02-14 — v2.0 (90+ upgrade)

**Added:**
- METRIC_CONTRACTS.md — Canonical metric definitions with formulas and edge cases
- RUNBOOK.md — Operations and incident playbook
- DATA_QUALITY_MATRIX.md — Tests, thresholds, owners, alerts
- LINEAGE.md — Source→transform→target dependency graph
- SECURITY_AND_GOVERNANCE.md — Access, PII, retention for bank context

**Updated:**
- All documents: added front-matter (owner, last_updated, review_cadence)
- README.md: full doc index, audience guide, role-based getting started

---

## 2026-02-14 — v1.0 (Initial)

**Added:**
- ARCHITECTURE.md
- DATA_DICTIONARY.md
- BUSINESS_GLOSSARY.md
- ROADMAP_10_OUT_OF_10.md
- README.md
