---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
status: Canonical
approved_by: (pending formal sign-off)
---

# Ineco Analytics - Metric Contracts

> Authoritative definitions for all key metrics. Single source of truth for reporting.
> Any dashboard metric MUST use these formulas. Deviations require updating this document first.

---

## Primary Metrics

### Sessions

| Attribute | Definition |
|-----------|------------|
| **Formula** | `COUNT(DISTINCT session_id)` |
| **Source** | stg_events |
| **Edge cases** | Session ends after 30 min inactivity (GA4 default). Includes bounced sessions. session_id is unique within a user, but globally unique in practice for counting. |
| **Exclusions** | None. All sessions count. |
| **Example** | 1 user, 3 visits in one day = 3 sessions |

---

### Users

| Attribute | Definition |
|-----------|------------|
| **Formula** | `COUNT(DISTINCT user_pseudo_id)` |
| **Source** | stg_events |
| **Edge cases** | user_pseudo_id is a random anonymous ID (not a hash). Same person on different devices = 2 users. |
| **Exclusions** | None |
| **Note** | Use user_id when available for logged-in cross-device analysis. |

---

### New Users

| Attribute | Definition |
|-----------|------------|
| **Formula** | `COUNT(DISTINCT CASE WHEN session_number = 1 THEN user_pseudo_id END)` |
| **Source** | stg_events |
| **Edge cases** | session_number = 1 means first session for that user_pseudo_id. Clearing cookies resets this. |

---

### Page Views

| Attribute | Definition |
|-----------|------------|
| **Formula** | `COUNT(CASE WHEN event_name = 'page_view' THEN 1 END)` |
| **Source** | stg_events |
| **Edge cases** | Counts every page_view event, not distinct users. |

---

### Registrations (Completed)

| Attribute | Definition |
|-----------|------------|
| **Formula** | `COUNT(DISTINCT CASE WHEN event_name = 'registration_success' THEN user_pseudo_id END)` |
| **Source** | stg_events |
| **Event** | registration_success |
| **Edge cases** | A user can register for multiple products; we count unique users. |
| **Exclusions** | Exclude test/internal traffic if filters applied. |

---

### Sub ID

| Attribute | Definition |
|-----------|------------|
| **Formula (Loans)** | `COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID sprint' THEN user_pseudo_id END)` |
| **Formula (Cards/Deposits)** | `COUNT(DISTINCT CASE WHEN event_name = 'Get Sub ID' THEN user_pseudo_id END)` |
| **Formula (Combined)** | `COUNT(DISTINCT CASE WHEN event_name IN ('Get Sub ID', 'Get Sub ID sprint') THEN user_pseudo_id END)` |
| **Source** | stg_events |
| **Edge cases** | Cards and Deposits share the same `Get Sub ID` event — cannot distinguish between them at this event level. |

---

### Conversion Rate (Session-to-Registration)

| Attribute | Definition |
|-----------|------------|
| **Formula** | `(SUM(registrations) / NULLIF(SUM(sessions), 0)) * 100` |
| **Unit** | Percent (%) |
| **Scope** | Pre-aggregated mart columns in numerator and denominator |
| **Edge cases** | If sessions = 0, result is NULL. Display as "0%" or "N/A" in UI. |

---

### Bounce Rate

| Attribute | Definition |
|-----------|------------|
| **Formula (session-level)** | `SAFE_DIVIDE(COUNTIF(is_engaged = 0 OR is_engaged IS NULL), COUNT(*)) * 100` |
| **Formula (from mart)** | `AVG(bounce_rate)` (pre-computed per row in mart_engagement) |
| **Source** | stg_events → mart_engagement |
| **Unit** | Percent (%) |
| **Edge cases** | GA4 defines engaged: session_engaged = 1 if engagement >10 sec OR conversion event. Bounce = NOT engaged. |

---

### Cost Per Registration (CPR / CPA)

| Attribute | Definition |
|-----------|------------|
| **Formula** | `SUM(spend) / NULLIF(SUM(registrations), 0)` |
| **Source** | ad_spend JOIN with mart by date + channel |
| **Unit** | Currency (AMD or USD) |
| **Edge cases** | If registrations = 0, result is NULL. Show as "—" in UI. |
| **Attribution** | Last-click by default; spend attributed to channel on same date. |

---

### Cost Per Session (CPS)

| Attribute | Definition |
|-----------|------------|
| **Formula** | `SUM(spend) / NULLIF(SUM(sessions), 0)` |
| **Source** | ad_spend JOIN with mart by date + channel |
| **Edge cases** | Organic channels have spend = 0; CPS is 0 or N/A for them. |

---

### Week-over-Week Change (WoW)

| Attribute | Definition |
|-----------|------------|
| **Formula** | `((current_week - previous_week) / NULLIF(previous_week, 0)) * 100` |
| **Unit** | Percent change |
| **Edge cases** | If previous_week = 0 and current > 0, result is infinite. Show as "New" or "+∞" in UI. |

---

## Derived / Composite Metrics

| Metric | Formula | Notes |
|--------|---------|-------|
| **Pages per Session** | `SUM(pageviews) / NULLIF(SUM(sessions), 0)` | Average |
| **Avg Session Duration** | `AVG(engagement_time_msec) / 1000` | Seconds. Computed at session level in mart_engagement. |
| **Session-to-Apply Rate** | `SUM(apply_clicks) / NULLIF(SUM(sessions), 0) * 100` | % |
| **Apply-to-Sub-ID Rate** | `SUM(sub_ids) / NULLIF(SUM(apply_clicks), 0) * 100` | %. Note: apply_clicks are ~82% underreported. Use with caution. |
| **Sub-ID-to-Registration Rate** | `SUM(registrations) / NULLIF(SUM(sub_ids), 0) * 100` | % (reliable) |

---

## Data Quality Rules for Metrics

1. **Never divide by zero** — Use `NULLIF(denominator, 0)` in SQL, `SAFE_DIVIDE()` in BigQuery.
2. **Distinct users for conversion counts** — Use `COUNT(DISTINCT user_pseudo_id)`, not `COUNT(*)`.
3. **Sessions** — Use `COUNT(DISTINCT session_id)` consistently.
4. **Currency consistency** — All spend in single currency. Convert if multi-currency.
5. **NULL handling in UI** — NULL metrics display as "—" or "N/A", never as 0 (which implies measured zero).

---

## Known Data Gaps

| Gap | Impact | Mitigation |
|-----|--------|------------|
| Apply Click underreporting (~82%) | Funnel steps 1→2 look unreliable | Skip Apply Click in funnel analysis; start from Sub ID |
| Cards vs Deposits share Get Sub ID | Cannot distinguish at application start | Use product_category from page_view for segmentation |
| Ad spend data is sample only | Cost metrics are placeholders | Pending API credentials for real ad platform data |

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-02-14 | v2: Fixed Bounce Rate to real SQL; fixed CPS label; added New Users, Pageviews; added Known Data Gaps; aligned Sessions formula | Analytics Team |
| 2026-02-14 | v1: Initial version | Analytics Team |
