# Ineco Data Templates

These CSV templates should be filled by Ineco team and uploaded to BigQuery.

## 1. bank_conversions.csv (REQUIRED)

**Purpose:** Track actual loan/card/deposit approvals from bank systems  
**Frequency:** Daily or weekly export  
**Source:** Core banking system

| Column | Type | Required | Description | Example |
|--------|------|----------|-------------|---------|
| `application_id` | STRING | Yes | Unique application ID | APP-2026-001234 |
| `user_id` | STRING | No | Internal user ID (if available) | USR-567890 |
| `product_type` | STRING | Yes | loan, card, or deposit | loan |
| `apply_date` | DATE | Yes | Date application was submitted | 2026-02-01 |
| `apply_source` | STRING | Yes | Traffic source (must match GA4) | google, meta, direct, organic |
| `apply_campaign` | STRING | No | Campaign name (must match GA4 UTM) | prolongation |
| `status` | STRING | Yes | approved, rejected, pending | approved |
| `approval_date` | DATE | No | Date of approval (NULL if pending/rejected) | 2026-02-04 |
| `rejection_reason` | STRING | No | Reason for rejection | low_credit_score |
| `approved_amount_amd` | NUMBER | No | Approved loan/card limit in AMD | 5000000 |
| `revenue_amd` | NUMBER | No | Revenue generated (fees, interest) in AMD | 125000 |
| `notes` | STRING | No | Any additional notes | Sprint loan |

**Important:**
- `apply_source` must match GA4 source values: google, meta, direct, organic, referral, email, sms, etc.
- `apply_campaign` must match GA4 UTM campaign names exactly
- This is critical for joining website data with bank approvals

---

## 2. monthly_targets.csv (RECOMMENDED)

**Purpose:** Define monthly targets for dashboard variance calculations  
**Frequency:** Monthly (beginning of each month)  
**Source:** Marketing/Finance team

| Column | Type | Required | Description | Example |
|--------|------|----------|-------------|---------|
| `period` | DATE | Yes | First day of month | 2026-02-01 |
| `metric` | STRING | Yes | revenue, approved, cpa, roas, approval_rate | revenue |
| `channel` | STRING | Yes | all, google_ads, meta_ads, etc. | all |
| `product` | STRING | Yes | all, loan, card, deposit | loan |
| `target_value` | NUMBER | Yes | Target value | 1100000000 |
| `notes` | STRING | No | Description | Overall monthly revenue |

**Metric values:**
- `revenue` - in AMD
- `approved` - count of approved applications
- `cpa` - in USD
- `roas` - ratio (e.g., 2.5 means $2.5 return per $1 spent)
- `approval_rate` - percentage (e.g., 55 means 55%)

---

## 3. monthly_budgets.csv (RECOMMENDED)

**Purpose:** Track ad spend budget pacing  
**Frequency:** Monthly (beginning of each month)  
**Source:** Marketing team

| Column | Type | Required | Description | Example |
|--------|------|----------|-------------|---------|
| `period` | DATE | Yes | First day of month | 2026-02-01 |
| `channel` | STRING | Yes | google_ads, meta_ads, linkedin, etc. | google_ads |
| `monthly_budget_usd` | NUMBER | Yes | Monthly budget in USD | 15000 |
| `daily_budget_usd` | NUMBER | No | Daily budget (auto-calc if empty) | 535 |
| `notes` | STRING | No | Description | Google Ads February |

---

## 4. ad_spend.csv (OPTIONAL - if no API integration)

**Purpose:** Manual ad spend upload (if not using API integration)  
**Frequency:** Daily  
**Source:** Export from Google Ads, Meta Ads Manager, etc.

| Column | Type | Required | Description | Example |
|--------|------|----------|-------------|---------|
| `date` | DATE | Yes | Date | 2026-02-01 |
| `channel` | STRING | Yes | google_ads, meta_ads, linkedin, yandex | google_ads |
| `campaign` | STRING | Yes | Campaign name | prolongation |
| `adset` | STRING | No | Ad set/ad group name | adset_loans_25-34 |
| `creative` | STRING | No | Creative/ad name | text_ad_v1 |
| `impressions` | NUMBER | Yes | Total impressions | 45234 |
| `clicks` | NUMBER | Yes | Total clicks | 1234 |
| `spend_usd` | NUMBER | Yes | Spend in USD | 156.78 |
| `spend_amd` | NUMBER | No | Spend in AMD (optional) | 62712 |

**Note:** Prefer API integration over manual CSV. Manual upload is error-prone and time-consuming.

---

## How to Upload

### Option A: BigQuery Console (Manual)
1. Go to BigQuery Console
2. Select dataset `ineco_raw`
3. Click "Create Table"
4. Source: Upload CSV
5. Select the CSV file
6. Table name: match the file name (e.g., `bank_conversions`)
7. Auto-detect schema: Yes
8. Click "Create Table"

### Option B: Automated (Recommended)
Send CSV files to Harut, and they will be uploaded via script.

---

## Questions?

Contact: [Harut's email]
