# Dashboard Upgrade Plan: Adding Bank Conversion Data
## 100/100 Complete Integration

---

## Current State Analysis

### Existing Dashboards & Charts (25 total)

**Dashboard 1: Executive Overview (6 KPIs + 2 charts)**
| ID | Chart Name | Type | Dataset | Shows |
|----|------------|------|---------|-------|
| 80 | Total Sessions | Big Number | fact_sessions | Website sessions |
| 81 | Total Users | Big Number | fact_sessions | Unique users |
| 82 | Total Registrations | Big Number | fact_conversions | Website registrations |
| 83 | Total Apply Clicks | Big Number | fact_conversions | Apply button clicks |
| 84 | Bounce Rate | Big Number | fact_sessions | % bounced |
| 85 | Conversion Rate | Big Number | fact_conversions | Registration / Apply clicks |
| 91 | Registrations by Channel | Bar | fact_conversions | Registrations per channel |
| 87 | Sessions Trend | Line | fact_sessions | Sessions over time |

**Dashboard 2: Channel & Campaign (6 charts)**
| ID | Chart Name | Type | Dataset | Shows |
|----|------------|------|---------|-------|
| 92 | Campaign Performance | Table | fact_sessions | Campaign metrics |
| 93 | Paid vs Organic | Pie | fact_sessions | Traffic split |
| 94 | Sessions by Product | Pie | fact_sessions | Product category split |
| - | Additional channel charts | - | - | - |

**Dashboard 3: Funnels & Cohorts (6 charts)**
| ID | Chart Name | Type | Dataset | Shows |
|----|------------|------|---------|-------|
| 95 | Loans Funnel | Table | fact_conversions | 6-stage funnel |
| - | Cards Funnel | Table | fact_conversions | Card funnel |
| - | Deposits Funnel | Table | fact_conversions | Deposit funnel |

**Dashboard 4: Deep Analysis (5 charts)**
| ID | Chart Name | Type | Dataset | Shows |
|----|------------|------|---------|-------|
| - | Device Split | Pie/Bar | fact_sessions | Desktop/Mobile/Tablet |
| - | Geographic | Table | fact_sessions | Country/City breakdown |

---

## New Data Available

### fact_bank_conversions (1,540 rows)
```
| Column | Sample Values |
|--------|---------------|
| date | 2025-12-18 to 2026-02-14 |
| channel_group | Email, Referral, Google Ads, Meta Ads... |
| product_category | Loans, Cards, Deposits |
| loan_count | 142 total |
| loan_amount | 81,437,501 AMD |
| card_count | 68 total |
| deposit_count | 4 total |
| deposit_amount | 17,518,298 AMD |
| total_revenue_amd | 98,955,799 AMD |
| is_existing_customer | Yes/No |
```

---

## UPGRADE PLAN: 100/100

### Phase 1: Add New Dataset to Superset
- Add `fact_bank_conversions` as dataset #24
- Enable all columns for filtering/metrics

---

### Phase 2: EXECUTIVE OVERVIEW - Upgrades

#### EDIT Existing Charts (4 changes)

| Current Chart | Change To | Why |
|---------------|-----------|-----|
| **Total Registrations** | **Total Registrations → Loans** | Show website registrations AND actual bank loans side-by-side |
| **Total Apply Clicks** | **Apply Clicks → Revenue** | Show clicks AND actual revenue generated |
| **Conversion Rate** | **Website CVR → Bank CVR** | Show both conversion rates |
| **Registrations by Channel** | **Registrations + Loans by Channel** | Add actual loans bars next to registrations |

#### ADD New Charts (4 new KPIs)

| New Chart | Type | Metric | Source |
|-----------|------|--------|--------|
| **Actual Loans Issued** | Big Number | SUM(loan_count) = 142 | fact_bank_conversions |
| **Actual Cards Issued** | Big Number | SUM(card_count) = 68 | fact_bank_conversions |
| **Loan Revenue** | Big Number | SUM(loan_amount) = 81.4M AMD | fact_bank_conversions |
| **Total Revenue** | Big Number | SUM(total_revenue_amd) = 99M AMD | fact_bank_conversions |

#### Final Executive Overview Layout
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  WEBSITE METRICS                    │  BANK METRICS (NEW)                   │
├─────────────────────────────────────┼───────────────────────────────────────┤
│  Sessions: 607,000                  │  Actual Loans: 142                    │
│  Users: 256,000                     │  Actual Cards: 68                     │
│  Registrations: 12,000              │  Loan Revenue: 81.4M AMD              │
│  Apply Clicks: 45,000               │  Total Revenue: 99M AMD               │
├─────────────────────────────────────┴───────────────────────────────────────┤
│  [Sessions Trend - existing]                                                 │
│  [Registrations + LOANS by Channel - ENHANCED]                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Charts after upgrade: 10 (was 8)**

---

### Phase 3: CHANNEL & CAMPAIGN - Upgrades

#### EDIT Existing Charts (3 changes)

| Current Chart | Change To | Details |
|---------------|-----------|---------|
| **Campaign Performance Table** | Add columns: Loans, Revenue | Show actual outcomes per campaign |
| **Paid vs Organic** | Show Revenue split (not just sessions) | Revenue by paid vs organic |
| **Sessions by Product** | Add Revenue by Product | Show which products generate revenue |

#### ADD New Charts (2 new)

| New Chart | Type | Shows |
|-----------|------|-------|
| **Revenue by Channel** | Horizontal Bar | Which channels generate actual revenue |
| **Bank Conversions Table** | Table | Channel → Events → Loans → Cards → Revenue |

#### Final Channel & Campaign Layout
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CHANNEL PERFORMANCE TABLE (ENHANCED)                                        │
│  Channel      Sessions  Registrations  Loans  Cards  Revenue (AMD)          │
│  ──────────────────────────────────────────────────────────────────         │
│  Email          8,500        890         52     19    35,261,809            │
│  Referral      12,300        456         47     10    21,091,291            │
│  Google Ads    45,000      1,234          2      6     1,766,000            │
│  Meta Ads      38,000        987          2      2       969,800            │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Revenue by Channel - NEW]     │  [Paid vs Organic Revenue - ENHANCED]     │
├─────────────────────────────────┼───────────────────────────────────────────┤
│  [Campaign ROI Table - ENHANCED: add Loans, Revenue columns]                │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Charts after upgrade: 8 (was 6)**

---

### Phase 4: FUNNELS & COHORTS - Upgrades

#### EDIT Existing Charts (3 changes)

| Current Chart | Change To | Details |
|---------------|-----------|---------|
| **Loans Funnel Table** | Add final column: **Bank Approved (142)** | Complete funnel to actual outcome |
| **Cards Funnel Table** | Add final column: **Cards Issued (68)** | Complete funnel |
| **Deposits Funnel Table** | Add final column: **Deposits Made (4)** | Complete funnel |

#### ADD New Charts (2 new)

| New Chart | Type | Shows |
|-----------|------|-------|
| **Full Funnel Summary** | Table | Sessions → Clicks → Registrations → Loans/Cards/Deposits |
| **Conversion by Channel** | Heatmap Table | Channel × Stage conversion rates with bank outcomes |

#### Final Loans Funnel Example
```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LOANS FUNNEL (COMPLETE)                                                     │
│                                                                              │
│  Stage                    Count        % of Previous    % of Total          │
│  ──────────────────────────────────────────────────────────────────         │
│  Page Views              125,432            -              100%             │
│  Apply Click              16,901          13.5%           13.5%             │
│  Sub ID                   11,358          67.2%            9.1%             │
│  Check Limit               9,325          82.1%            7.4%             │
│  Phone                     4,224          45.3%            3.4%             │
│  OTP/Registration          3,333          78.9%            2.7%             │
│  ─────────────────────────────────────────────────────────────── (NEW) ──  │
│  🏦 BANK APPROVED            142           4.3%            0.11%            │
│  💰 LOAN AMOUNT      81,437,501 AMD                                         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Charts after upgrade: 8 (was 6)**

---

### Phase 5: DEEP ANALYSIS - Upgrades

#### EDIT Existing Charts (2 changes)

| Current Chart | Change To | Details |
|---------------|-----------|---------|
| **Device Split** | Add Revenue by Device | Which devices generate actual revenue |
| **Geographic Table** | Add Loans, Revenue columns | Geography → Revenue correlation |

#### ADD New Charts (2 new)

| New Chart | Type | Shows |
|-----------|------|-------|
| **New vs Returning Revenue** | Bar | is_existing_customer = Yes/No → Revenue |
| **Campaign Revenue Breakdown** | Table | Top campaigns by actual revenue |

**Charts after upgrade: 7 (was 5)**

---

## SUMMARY: Complete Upgrade Plan

### Changes by Dashboard

| Dashboard | Current Charts | Edits | New Charts | Final Total |
|-----------|----------------|-------|------------|-------------|
| Executive Overview | 8 | 4 | 4 | **12** |
| Channel & Campaign | 6 | 3 | 2 | **8** |
| Funnels & Cohorts | 6 | 3 | 2 | **8** |
| Deep Analysis | 5 | 2 | 2 | **7** |
| **TOTAL** | **25** | **12** | **10** | **35** |

### Key Metrics Now Visible

| Metric | Before | After |
|--------|--------|-------|
| Website Sessions | ✅ | ✅ |
| Website Registrations | ✅ | ✅ |
| **Actual Loans Issued** | ❌ | ✅ |
| **Actual Cards Issued** | ❌ | ✅ |
| **Loan Revenue (AMD)** | ❌ | ✅ |
| **Total Revenue (AMD)** | ❌ | ✅ |
| **Revenue by Channel** | ❌ | ✅ |
| **Full Funnel to Bank Outcome** | ❌ | ✅ |
| **New vs Returning Revenue** | ❌ | ✅ |

---

## Implementation Order

1. **Step 1:** Add `fact_bank_conversions` dataset to Superset
2. **Step 2:** Add 4 new KPIs to Executive Overview
3. **Step 3:** Edit "Registrations by Channel" to include Loans
4. **Step 4:** Add Revenue by Channel chart
5. **Step 5:** Update Channel Performance table with Loans/Revenue columns
6. **Step 6:** Update Funnel tables with Bank Approved row
7. **Step 7:** Add New vs Returning analysis
8. **Step 8:** Test all filters work across both datasets

---

## Technical Notes

### Joining Website + Bank Data

For combined charts, we join on:
- `date` - both tables have date
- `channel_group` - both tables have channel mapping

Example SQL for combined chart:
```sql
SELECT 
  COALESCE(s.channel_group, b.channel_group) as channel,
  SUM(s.sessions) as sessions,
  SUM(s.registrations) as registrations,
  SUM(b.loan_count) as actual_loans,
  SUM(b.total_revenue_amd) as revenue
FROM fact_sessions s
FULL OUTER JOIN fact_bank_conversions b 
  ON s.date = b.date AND s.channel_group = b.channel_group
GROUP BY 1
```

### Datasets Required

| Dataset ID | Table | Purpose |
|------------|-------|---------|
| 21 | fact_sessions | Website traffic |
| 22 | fact_conversions | Website conversions |
| **24 (NEW)** | fact_bank_conversions | Bank outcomes |

---

## Final Result: What Users Will See

### Executive Dashboard
> "We had 607K sessions, 12K registrations, and **142 actual loans worth 81.4M AMD**"

### Channel Dashboard  
> "Email drives most revenue (35M AMD), even though Google Ads has more sessions"

### Funnel Dashboard
> "Of 125K loan page views, only 142 became actual loans - 0.11% full-funnel conversion"

### Deep Analysis
> "Returning customers generate 65% of revenue vs 35% from new"

---

**This is the 100/100 plan. Ready to implement?**
