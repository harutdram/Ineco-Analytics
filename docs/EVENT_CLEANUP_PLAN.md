# Ineco GA4 Event Cleanup Plan

## Executive Summary

Two main funnels identified:
1. **Consumer Loans (Sprint)** - 185K users, via sprintonline.am
2. **Cards/Deposits (Registration)** - 26K users, via reg.inecobank.am

---

## Current State Analysis

### Funnel 1: Consumer Loans (Sprint Flow)
**Product Category:** `Consumer Loans`
**Platform:** sprintonline.am

| Step | Current Event | Volume | Status |
|------|---------------|--------|--------|
| 1 | `sign_in_click` | 185,201 | ✅ Working |
| 2 | `sprint_apply_button_click` | 21,110 | ✅ Working |
| 3 | `Get Sub ID sprint` | 88,636 | ⚠️ Needs rename |
| 4a | `login via inecomob sprint` | 15,255 | ⚠️ Needs rename |
| 4b | `phone_submited_sprint` | 2,497 | ⚠️ Typo |
| 5 | `sprint_login_mobile_start` | 16 | 🆕 New (Feb 18) |
| 6 | `sprint_login_mobile_success` | 17 | 🆕 New (Feb 19) |
| 7 | `spint_ssn_sumpited` | 4 | 🆕 New + Typo |
| 8 | `check_limit_click` | 43,645 | ✅ Working |
| 9 | `sprint_check_limit_comleted` | 79 | 🆕 New + Typo |

### Funnel 2: Cards/Deposits (Registration Flow)
**Product Categories:** `Cards`, `Deposits`, `Homepage`
**Platform:** reg.inecobank.am

| Step | Current Event | Volume | Status |
|------|---------------|--------|--------|
| 1 | `reg_apply_button_click` | 9,909 | ✅ Working |
| 2 | `Get Sub ID` | 26,161 | ⚠️ Needs rename |
| 3 | `phone_submited_reg` | 26,157 | ⚠️ Typo |
| 4 | `ssn_submitted` | 2,361 | 🆕 New (Feb 17) |
| 5 | `otp_email_verified` | 773 | 🆕 New (Feb 17) |
| 6 | `kyc_start` | 1,279 | 🆕 New (Feb 17) |
| 7 | `kyc_qr_shown` | 27 | 🆕 New (Feb 17) |
| 8 | `kyc_qr_scanned` | 16 | 🆕 New (Feb 17) |
| 9 | `registration_success` | 784 | ✅ Working |

---

## Step-by-Step Implementation Plan

### Phase 1: Create Event Mapping Table
**Goal:** Standardize all event names in BigQuery
**Timeline:** Now

```sql
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_staging.event_mapping` AS
SELECT * FROM UNNEST([
  -- Sprint Flow (Loans)
  STRUCT('Get Sub ID sprint' as original_event, 'sprint_otp_requested' as clean_event, 'Sprint' as flow, 3 as funnel_step, 'Consumer Loans' as category),
  STRUCT('phone_submited_sprint', 'sprint_phone_submitted', 'Sprint', 4, 'Consumer Loans'),
  STRUCT('login via inecomob sprint', 'sprint_login_via_mobile', 'Sprint', 4, 'Consumer Loans'),
  STRUCT('spint_ssn_sumpited', 'sprint_ssn_submitted', 'Sprint', 7, 'Consumer Loans'),
  STRUCT('sprint_check_limit_comleted', 'sprint_check_limit_completed', 'Sprint', 9, 'Consumer Loans'),
  
  -- Registration Flow (Cards/Deposits)
  STRUCT('Get Sub ID', 'reg_otp_requested', 'Registration', 2, 'Cards/Deposits'),
  STRUCT('phone_submited_reg', 'reg_phone_submitted', 'Registration', 3, 'Cards/Deposits'),
  STRUCT('ssn_submitted', 'reg_ssn_submitted', 'Registration', 4, 'Cards/Deposits'),
  STRUCT('otp_email_verified', 'reg_email_verified', 'Registration', 5, 'Cards/Deposits'),
  STRUCT('registration_success', 'reg_completed', 'Registration', 9, 'Cards/Deposits'),
  
  -- Apply buttons (standardize)
  STRUCT('sprint_apply_button_click', 'sprint_apply_click', 'Sprint', 2, 'Consumer Loans'),
  STRUCT('reg_apply_button_click', 'reg_apply_click', 'Registration', 1, 'Cards/Deposits'),
  STRUCT('cards_apply_button', 'cards_apply_click', 'Registration', 1, 'Cards'),
  STRUCT('apply_button_click', 'apply_click', 'General', 1, 'Multiple')
]);
```

### Phase 2: Update Staging Table
**Goal:** Add clean event names to stg_events
**Timeline:** After Phase 1

```sql
-- Add clean_event_name column to staging
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_staging.stg_events_v2` AS
SELECT 
  e.*,
  COALESCE(m.clean_event, e.event_name) as event_name_clean,
  COALESCE(m.flow, 'Other') as flow_type,
  m.funnel_step
FROM `x-victor-477214-g0.ineco_staging.stg_events` e
LEFT JOIN `x-victor-477214-g0.ineco_staging.event_mapping` m
  ON e.event_name = m.original_event;
```

### Phase 3: Create Funnel Mart Tables
**Goal:** Clean funnel tables for Superset
**Timeline:** After Phase 2

```sql
-- Sprint Loan Funnel
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.funnel_loans` AS
SELECT
  event_date as date,
  channel_group,
  campaign,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'page_view' AND product_category = 'Consumer Loans' THEN user_pseudo_id END) as step1_pageview,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_apply_click' THEN user_pseudo_id END) as step2_apply_click,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_otp_requested' THEN user_pseudo_id END) as step3_otp,
  COUNT(DISTINCT CASE WHEN event_name_clean IN ('sprint_phone_submitted', 'sprint_login_via_mobile') THEN user_pseudo_id END) as step4_phone,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'check_limit_click' THEN user_pseudo_id END) as step5_check_limit,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'sprint_check_limit_completed' THEN user_pseudo_id END) as step6_completed
FROM `x-victor-477214-g0.ineco_staging.stg_events_v2`
WHERE product_category = 'Consumer Loans' OR flow_type = 'Sprint'
GROUP BY 1, 2, 3;

-- Registration Funnel (Cards/Deposits)
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.funnel_registration` AS
SELECT
  event_date as date,
  channel_group,
  campaign,
  product_category,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_apply_click' THEN user_pseudo_id END) as step1_apply_click,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_otp_requested' THEN user_pseudo_id END) as step2_otp,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_phone_submitted' THEN user_pseudo_id END) as step3_phone,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_ssn_submitted' THEN user_pseudo_id END) as step4_ssn,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_email_verified' THEN user_pseudo_id END) as step5_email,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'kyc_start' THEN user_pseudo_id END) as step6_kyc_start,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'kyc_qr_scanned' THEN user_pseudo_id END) as step7_kyc_complete,
  COUNT(DISTINCT CASE WHEN event_name_clean = 'reg_completed' THEN user_pseudo_id END) as step8_completed
FROM `x-victor-477214-g0.ineco_staging.stg_events_v2`
WHERE product_category IN ('Cards', 'Deposits') OR flow_type = 'Registration'
GROUP BY 1, 2, 3, 4;
```

### Phase 4: Update Superset Dashboards
**Goal:** Add funnel visualizations
**Timeline:** After Phase 3

1. Add `funnel_loans` dataset to Superset
2. Add `funnel_registration` dataset to Superset
3. Create funnel charts showing conversion rates
4. Add to Channel Performance dashboard

### Phase 5: Documentation
**Goal:** Document for Ineco team
**Timeline:** After Phase 4

1. Update data dictionary with clean event names
2. Create funnel visualization guide
3. Document any anomalies (e.g., `sprint_check_limit_comleted` only has 1 user with 79 events)

---

## Event Naming Convention (Standard)

### Format: `{flow}_{action}_{object}`

| Flow | Prefix | Example |
|------|--------|---------|
| Sprint (Loans) | `sprint_` | `sprint_apply_click` |
| Registration | `reg_` | `reg_phone_submitted` |
| KYC | `kyc_` | `kyc_qr_scanned` |
| General | none | `page_view` |

### Actions
- `_click` - Button/link click
- `_submitted` - Form submission
- `_verified` - Verification complete
- `_requested` - Request initiated
- `_completed` - Process finished
- `_start` - Process started

---

## Questions for Ineco

1. **`sign_in_click` (185K events)** - Is this the same as apply button? Or a separate login action?

2. **`ineco_online` (158K events)** - What does this track? Redirect to online banking?

3. **`click_ineco` (11K events)** - What specific element is being clicked?

4. **`check_limit_click` vs `sprint_check_limit_comleted`** - Why does check_limit have 43K events but completion only 79?

5. **Why does `sprint_check_limit_comleted` have 79 events from only 1 user?** - Is this test data?

---

## Data Quality Notes

### Anomalies Found

| Event | Issue | Impact |
|-------|-------|--------|
| `sprint_check_limit_comleted` | 79 events, 1 user | Looks like test data |
| `spint_ssn_sumpited` | 4 events, 2 users | Very low volume + typo |
| `test_visa_platinum`, `test_visa_p` | Test events | Should exclude |
| `exchange_page_view` | 2 events, 1 user | Probably test |

### Recommendation
Exclude test events in production dashboards:
```sql
WHERE event_name NOT LIKE 'test_%'
  AND event_name NOT LIKE 'exchange_%'
```
