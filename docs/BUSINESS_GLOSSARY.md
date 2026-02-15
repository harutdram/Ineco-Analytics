---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
---

# Ineco Analytics - Business Glossary

> Definitions of key terms used in dashboards and data

---

## Conversion & Funnel Terms

| Term | Definition |
|------|------------|
| **Sub ID** | Unique identifier assigned when user enters an application flow. Represents "intent to apply." |
| **Get Sub ID** | Event fired when user enters Cards/Deposits registration flow. Shared across Cards and Deposits — not product-specific. |
| **Get Sub ID sprint** | Event fired when user enters Loans (Sprint) application flow. Ineco: "вход в спринт" (entry into Sprint). |
| **Apply Click** | User clicked the "Apply" button. Loans: `sprint_apply_button_click`. Cards/Deposits: `reg_apply_button_click`. **Known gap:** ~82% of users bypass this event via direct/deep links. |
| **Check Limit** | User checked their approved credit limit (Loans only). Ineco: "проверка одобренных лимитов" (checking approved limits). Occurs after Sub ID. |
| **Registration** | User completed full registration (phone + OTP verified). Event: `registration_success`. |
| **CVR** | Conversion Rate = (Conversions / Sessions) x 100. See METRIC_CONTRACTS.md for exact formula. |
| **CPA** | Cost Per Acquisition = Ad Spend / Registrations |
| **CPR** | Cost Per Registration (same as CPA in our context) |
| **CPS** | Cost Per Session = Ad Spend / Sessions |
| **ROAS** | Return on Ad Spend = Revenue / Ad Spend (future, needs bank revenue data) |

---

## Funnel Definitions (from Ineco)

**Cards & Deposits (Депозит и карта):**
```
PageView → reg_apply_button_click → Get Sub ID
```

**Loans (Кредит):**
```
PageView → sprint_apply_button_click → Get Sub ID sprint → check_limit_click
```

> "get sub id — это вход в спринт, а check limit — уже проверка одобренных лимитов"

---

## Traffic & Acquisition Terms

| Term | Definition |
|------|------------|
| **Session** | Period of user activity on the site. Ends after 30 min inactivity (GA4 default). |
| **User** | Unique visitor identified by `user_pseudo_id` (randomly generated per device, not a hash). Same person on different devices = 2 users. |
| **New User** | First session ever (session_number = 1) |
| **Returning User** | User with prior sessions (session_number > 1) |
| **Page View** | Single page load event |
| **Bounce** | Session with no engaged events (user left quickly) |
| **Bounce Rate** | % of sessions that were not engaged |
| **Engaged Session** | GA4 flag: session_engaged = 1 if engagement >10 sec OR conversion event occurred |
| **Source** | Raw origin of traffic (google, facebook, etc.) |
| **Source Clean** | Standardized source name (see channel table below) |
| **Channel** | Grouped marketing channel (Direct, Google Organic, etc.) |
| **Medium** | Traffic type (organic, cpc, referral, email) |
| **WoW** | Week over Week comparison (% change) |

---

## Product Terms

| Term | Definition |
|------|------------|
| **Consumer Loans** | Loan products: 1-click loans, refinance, etc. Primary product. |
| **Cards** | Card products (debit, credit). |
| **Deposits** | Deposit products (simple deposit, etc.). |
| **Sprint** | Ineco's loan application flow/system. "Sprint" events (`*_sprint`) belong to the Loans funnel. |
| **Reg** | Registration flow for Cards/Deposits. "Reg" events (`*_reg`) belong to the Cards/Deposits funnel. |

---

## Channel Definitions (source_clean)

All values produced by the `source_clean` CASE logic in `stg_events`:

| Channel | Sources Included |
|---------|------------------|
| Direct | `(direct)` |
| Google | `google` (organic) |
| Bing | `bing` |
| Google Ads | `google` (cpc) |
| Meta | fb, ig, facebook, instagram, FB, Meta*, fb_*, fbads* |
| NN Ads | NN*, nn* |
| MS Network | MS*, ms_*, ms_network, MediaSystem* |
| Native Ads | *Native*, *native* |
| Intent Ads | *intent*, *Intent* |
| Prodigi Ads | *prodigi*, *Prodigi* |
| Email | email, sfmc, Mailing, mailing, *mail.* |
| SMS | SMS, *sms* |
| Viber | *viber* |
| Yandex | *yandex*, ya.* |
| Yahoo | *yahoo* |
| Adfox | adfox |
| LinkedIn | *linkedin*, *lnkd*, LinkedIn_ads |
| Survey | *survey* |
| Telegram | *telegram*, Telegram |
| Mastercard Promo | *Mastercard*, *mastercard* |
| Internal | *inecobank*, landing |
| Armenian Sites | *.am, *.am:* |
| AI Tools | chatgpt*, claude*, gemini*, copilot*, perplexity* |
| (other) | Any source not matching above; passes through as-is |

---

## Technical Terms

| Term | Definition |
|------|------------|
| **Mart** | Pre-aggregated table in BigQuery, optimized for dashboard queries |
| **Staging** | Cleaned/intermediate layer between raw and marts |
| **Grain** | Level of granularity of a table (e.g., one row per date + channel) |
| **Refresh** | Rebuild mart tables with latest data (daily cron) |
| **Medallion Architecture** | Raw → Staging → Marts pattern (Bronze/Silver/Gold) |
| **Engagement Time** | Time in milliseconds the user actively interacted with the page (GA4) |
| **Session Engaged** | GA4 flag: 1 if session had engagement >10 sec or a conversion event |
| **Star Schema** | Fact tables + dimension tables design pattern (Kimball). See ROADMAP. |
