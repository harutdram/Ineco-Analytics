# GA4 Events Analysis - Ineco Bank

## Overview

Analysis of Ineco's GA4 events document vs actual BigQuery data.
Goal: Standardize naming and create clean funnel tracking.

---

## Current Issues

### 1. Naming Inconsistencies

| Current (Messy) | Proposed (Clean) | Issue |
|-----------------|------------------|-------|
| `Get Sub ID sprint` | `sprint_otp_verified` | Spaces in event name |
| `Get Sub ID` | `reg_otp_verified` | Not descriptive |
| `spint_ssn_sumpited` | `sprint_ssn_submitted` | Typo |
| `sprint_check_limit_comleted` | `sprint_check_limit_completed` | Typo |
| `login via inecomob sprint` | `sprint_login_via_mobile` | Spaces, unclear |
| `phone_submited_sprint` | `sprint_phone_submitted` | Inconsistent prefix |
| `phone_submited_reg` | `reg_phone_submitted` | Typo (submited) |

### 2. Missing Standard Prefix Pattern

Events should follow: `{flow}_{action}_{object}`

- `sprint_*` = Loan flow (Sprint platform)
- `reg_*` = Registration flow (Cards/Deposits)
- `kyc_*` = KYC verification

---

## Proposed Event Naming Standard

### Cards & Deposits Flow (Registration)

| Step | Current Event | Proposed Event | Description |
|------|---------------|----------------|-------------|
| 1 | `page_view` | `page_view` | Landing page view |
| 2 | `reg_apply_button_click` | `reg_apply_click` | Apply button clicked |
| 3 | `page_view` (reg.inecobank.am) | `reg_page_view` | Registration page |
| 4 | - | `reg_phone_typing` | Phone number entered |
| 5 | `Get Sub ID` | `reg_otp_requested` | OTP sent |
| 6 | `phone_submited_reg` | `reg_phone_verified` | Phone verified |
| 7 | `ssn_submitted` | `reg_ssn_submitted` | SSN submitted |
| 8 | `otp_email_verified` | `reg_email_verified` | Email verified |
| 9 | `kyc_start` | `kyc_started` | KYC process started |
| 10 | `kyc_qr_shown` | `kyc_qr_shown` | QR code displayed |
| 11 | `kyc_qr_scanned` | `kyc_qr_scanned` | QR code scanned |
| 12 | `registration_success` | `reg_completed` | Registration complete |

### Loans Flow (Sprint)

| Step | Current Event | Proposed Event | Description |
|------|---------------|----------------|-------------|
| 1 | `page_view` | `page_view` | Landing page view |
| 2 | `sprint_apply_button_click` | `sprint_apply_click` | Apply button clicked |
| 3 | `page_view` (sprintonline.am) | `sprint_page_view` | Sprint login page |
| 4a | `sprint_login_mobile_start` | `sprint_login_mobile_start` | Login via InecoMobile |
| 4b | `phone_submited_sprint` | `sprint_phone_submitted` | Phone number entered |
| 5 | `Get Sub ID sprint` | `sprint_otp_requested` | OTP sent |
| 6 | `sprint_login_success` | `sprint_login_success` | Logged in |
| 7 | `spint_ssn_sumpited` | `sprint_ssn_submitted` | SSN submitted |
| 8 | `check_limit_click` | `sprint_check_limit_click` | Check limit clicked |
| 9 | `sprint_check_limit_comleted` | `sprint_check_limit_completed` | Limit check done |

---

## Events NOT in Document (Need Clarification)

These events exist in BigQuery but weren't in the document:

| Event | Count | Question |
|-------|-------|----------|
| `sign_in_click` | 186,468 | What is this? Login button? |
| `ineco_online` | 158,161 | Online banking redirect? |
| `click` | 45,105 | Generic click - needs parameters |
| `check_limit_click` | 43,947 | Part of loan flow? |
| `file_download` | 25,861 | What files? |
| `login via inecomob sprint` | 15,305 | Should be `sprint_login_via_mobile` |
| `phone_call` | 15,021 | Click-to-call tracking? |
| `click_ineco` | 11,668 | What's being clicked? |
| `register_funnel` | 8,256 | Duplicate of reg flow? |
| `view_search_results` | 4,193 | Site search? |

---

## Recommended Actions

### Immediate (Fix in GA4 GTM)

1. **Fix typos** in event names:
   - `spint_ssn_sumpited` → `sprint_ssn_submitted`
   - `sprint_check_limit_comleted` → `sprint_check_limit_completed`
   - `phone_submited_*` → `phone_submitted_*`

2. **Remove spaces** from event names:
   - `Get Sub ID sprint` → `sprint_otp_requested`
   - `Get Sub ID` → `reg_otp_requested`
   - `login via inecomob sprint` → `sprint_login_via_mobile`

### In BigQuery (Transformation Layer)

Create a mapping table to normalize events:

```sql
CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_staging.event_mapping` AS
SELECT * FROM UNNEST([
  STRUCT('Get Sub ID sprint' as original, 'sprint_otp_requested' as standardized, 'Loans' as category, 5 as funnel_step),
  STRUCT('Get Sub ID', 'reg_otp_requested', 'Cards/Deposits', 5),
  STRUCT('spint_ssn_sumpited', 'sprint_ssn_submitted', 'Loans', 7),
  STRUCT('sprint_check_limit_comleted', 'sprint_check_limit_completed', 'Loans', 9),
  STRUCT('phone_submited_sprint', 'sprint_phone_submitted', 'Loans', 4),
  STRUCT('phone_submited_reg', 'reg_phone_submitted', 'Cards/Deposits', 4),
  STRUCT('login via inecomob sprint', 'sprint_login_via_mobile', 'Loans', 4),
  STRUCT('reg_apply_button_click', 'reg_apply_click', 'Cards/Deposits', 2),
  STRUCT('sprint_apply_button_click', 'sprint_apply_click', 'Loans', 2)
]);
```

### Questions for Ineco

1. What is `sign_in_click` (186K events)? Is this different from apply buttons?
2. What is `ineco_online` (158K events)? Online banking?
3. Should `check_limit_click` be documented in the loan funnel?
4. Is `phone_call` tracking click-to-call?
5. What triggers `click_ineco` and `click`?

---

## Funnel Visualization

### Cards/Deposits Funnel
```
page_view (753K) 
    → reg_apply_click (9.9K) 
        → reg_otp_requested (26K) 
            → reg_phone_verified (26K) 
                → reg_ssn_submitted (2.4K) 
                    → reg_email_verified (773) 
                        → kyc_started (1.3K) 
                            → kyc_qr_scanned (16) 
                                → reg_completed (784)
```

### Loans (Sprint) Funnel
```
page_view (753K) 
    → sprint_apply_click (23.5K) 
        → sprint_otp_requested (89K) 
            → sprint_phone_submitted (2.5K) 
                → sprint_ssn_submitted (4) 
                    → sprint_check_limit_completed (79)
```

---

## Summary

| Metric | Current | After Cleanup |
|--------|---------|---------------|
| Unique event names | 48 | ~30 (standardized) |
| Events with typos | 4 | 0 |
| Events with spaces | 3 | 0 |
| Documented events | 18 | 30+ |
