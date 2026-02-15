---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
---

# Ineco Analytics Documentation

> Data warehouse and dashboard documentation for Ineco Bank

---

## Documents

| Document | Description | Audience |
|----------|-------------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Data architecture, layers, flow | All |
| [DATA_DICTIONARY.md](DATA_DICTIONARY.md) | Table and column definitions | Engineers, Analysts |
| [BUSINESS_GLOSSARY.md](BUSINESS_GLOSSARY.md) | Business terms (Sub ID, CVR, etc.) | All |
| [METRIC_CONTRACTS.md](METRIC_CONTRACTS.md) | Canonical metric formulas and edge cases | Analysts, Engineers |
| [RUNBOOK.md](RUNBOOK.md) | Operations and incident procedures | On-call, DevOps |
| [DATA_QUALITY_MATRIX.md](DATA_QUALITY_MATRIX.md) | Tests, thresholds, alerts | Data Engineers |
| [LINEAGE.md](LINEAGE.md) | Source-to-target dependencies | Engineers |
| [SECURITY_AND_GOVERNANCE.md](SECURITY_AND_GOVERNANCE.md) | Access, PII, retention (bank context) | Security, Compliance |
| [ROADMAP_10_OUT_OF_10.md](ROADMAP_10_OUT_OF_10.md) | Path to best-in-class architecture | Leadership, Engineers |
| [CHANGELOG.md](CHANGELOG.md) | Documentation version history | All |

---

## Quick Reference

| Item | Value |
|------|-------|
| **GCP Project** | `x-victor-477214-g0` |
| **BigQuery Location** | EU (multi-region) |
| **Datasets** | `ineco_raw`, `ineco_staging`, `ineco_marts` (17 tables) |
| **VM** | `superset-ineco` (us-central1-a) |
| **Superset** | Port 8088 on VM external IP (run `gcloud compute instances list` for current IP) |
| **Mart Refresh** | Daily 6:00 AM via cron (`refresh_marts.py`) |
| **HTTPS** | Not yet configured (see SECURITY_AND_GOVERNANCE.md) |

---

## Getting Started

| Role | Start here |
|------|------------|
| **New to project** | [ARCHITECTURE.md](ARCHITECTURE.md) → [BUSINESS_GLOSSARY.md](BUSINESS_GLOSSARY.md) |
| **Building queries** | [DATA_DICTIONARY.md](DATA_DICTIONARY.md) → [METRIC_CONTRACTS.md](METRIC_CONTRACTS.md) |
| **Incident / ops** | [RUNBOOK.md](RUNBOOK.md) |
| **Data quality** | [DATA_QUALITY_MATRIX.md](DATA_QUALITY_MATRIX.md) |
| **Schema changes** | [LINEAGE.md](LINEAGE.md) → [RUNBOOK.md](RUNBOOK.md) |
| **Security / compliance** | [SECURITY_AND_GOVERNANCE.md](SECURITY_AND_GOVERNANCE.md) |

---

## Contributing to These Docs

- When changing a schema, mart, or metric: update the relevant docs in the same PR.
- Every doc has front-matter with `owner`, `last_updated`, and `review_cadence`. Update `last_updated` on edit.
- Log changes in [CHANGELOG.md](CHANGELOG.md).
