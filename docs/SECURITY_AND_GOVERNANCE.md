---
owner: Analytics Team / CISO
last_updated: 2026-02-14
review_cadence: Semi-annual
classification: Internal
---

# Ineco Analytics - Security & Governance

> Access, PII, retention, and compliance for analytics data (bank context)

---

## 1. Data Classification

| Layer | Classification | PII | Rationale |
|-------|----------------|-----|------------|
| Raw (events_*, ad_spend) | Internal | user_pseudo_id (pseudonymous) | GA4 exports; no direct identifiers |
| Staging (stg_events) | Internal | Same as raw + user_id (restricted) | Transformed, user_id may be present |
| Marts | Internal | Aggregated only | No user-level rows; counts and sums only |
| Superset | Internal | Aggregated only | Dashboards show aggregates |

**Note:** `user_pseudo_id` is a randomly generated anonymous ID per device — it is NOT a hash of any personal data. However, `user_id` (when present for logged-in users) can be a real identifier and must be restricted.

---

## 2. Access Model

### BigQuery

| Role | Access | Scope |
|------|--------|-------|
| Service account (refresh script) | Read raw, staging; Write marts | VM only, key stored at `/home/harut/superset/credentials/` |
| Analytics team | Read all datasets | Via GCP console / authorized tools |
| Superset connection | Read marts only | **Recommendation:** Create dedicated SA with marts-only read access |

**Principle:** Marts are the only layer Superset (and downstream users) should query. Raw and staging access should be limited to the analytics team.

### Superset

| Role | Capabilities |
|------|--------------|
| Admin | Full access, user management, dataset sync |
| Gamma | Create charts, edit own dashboards |
| Dashboard viewer | View only |

**Recommendation:** Assign Gamma or viewer for business users; Admin for data/analytics team only.

---

## 3. Network Security

| Component | Current State | Recommendation |
|-----------|---------------|----------------|
| **Superset** | HTTP on port 8088, open to internet | Configure HTTPS with SSL certificate + domain |
| **Firewall** | Port 8088 open | Restrict to Ineco office IPs or use VPN |
| **SSH** | GCP IAM-based | Keep as-is |
| **BigQuery** | GCP IAM + service account | Keep as-is; add read-only SA for Superset |

**Action item:** Ineco IT to provide domain name for HTTPS setup. Owner: Ineco IT. Target: TBD.

---

## 4. PII Handling

| Data element | Present in | Action |
|--------------|------------|--------|
| user_pseudo_id | Raw, staging | Retained; pseudonymous, random ID |
| user_id | Raw, staging (if logged in) | **Do not expose in Superset**; exclude from marts |
| page_location (URL) | Raw, staging, mart_landing_pages | May contain query params/tokens; mart_landing_pages extracts path only (strips params) |
| country, city | Raw, staging, marts | Aggregated in marts; no individual identification risk |
| access_token_sub_id | Staging | Application token; do not expose in dashboards |

**Marts:** No user-level rows. All aggregations (counts, sums). Safe for broader dashboard access.

---

## 5. Retention

| Dataset | Retention | Notes |
|---------|-----------|-------|
| Raw events_* | No auto-expiry in BigQuery | GA4 BigQuery export persists until manually deleted or table expiration set. (Note: 14-month limit is GA4 UI reporting only, not the BQ export.) |
| ad_spend | No auto-expiry | Recommend: set 2-year table expiration for billing/audit |
| Staging (views) | Same as raw | Views read from raw in real-time |
| Marts (tables) | Rebuilt daily | Current data only; no historical snapshots retained (but BigQuery time travel allows 7-day lookback) |

**Action:** Consider setting BigQuery table expiration policies on raw tables to manage storage costs long-term.

---

## 6. Audit & Compliance

| Requirement | Implementation |
|-------------|----------------|
| Access logging | GCP Audit Logs enabled for BigQuery by default |
| Change tracking | SQL code in GitHub; mart refresh logs on VM |
| Data lineage | See LINEAGE.md |
| Incident response | See RUNBOOK.md |
| Data quality | See DATA_QUALITY_MATRIX.md |

---

## 7. Bank-Specific Considerations

- **Regulatory:** Confirm with Ineco compliance team which regulations apply (e.g., Armenian banking regulations, GDPR if processing EU user data). **Owner: Analytics Team. Action: Request compliance review before production rollout.**
- **Segregation:** Analytics data is completely isolated from core banking systems. Read-only access to analytics datasets only.
- **Masking:** If `user_id` is ever needed in analytics, hash or mask before use.
- **Encryption:** BigQuery encrypts data at rest (AES-256) and in transit (TLS). No additional encryption needed.
- **Data residency:** BigQuery datasets are in EU multi-region. Verify this meets Ineco's data residency requirements.

---

## 8. Recommendations & Action Items

| # | Action | Owner | Priority | Status |
|---|--------|-------|----------|--------|
| 1 | Create read-only BigQuery SA for Superset (marts only) | Analytics | High | Not started |
| 2 | Configure HTTPS + domain for Superset | Ineco IT | High | Pending domain |
| 3 | Restrict firewall to Ineco office IPs | Analytics | Medium | Not started |
| 4 | Enable GCP Audit Logs review cadence | Analytics | Medium | Not started |
| 5 | Request compliance review from Ineco legal/compliance | Analytics | High | Not started |
| 6 | Set table expiration on raw tables (2 years) | Analytics | Low | Not started |
| 7 | Review access quarterly | Analytics | Low | Ongoing |

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-02-14 | v2: Fixed retention (BQ export has no auto-expiry); added network security; added HTTPS gap; fixed user_pseudo_id description; added action items table | Analytics Team |
| 2026-02-14 | v1: Initial version | Analytics Team |
