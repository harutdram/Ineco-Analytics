# Ineco Analytics Platform - Project Overview

## What We Built

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                               │
│    INECO MARKETING ANALYTICS PLATFORM                                        │
│                                                                               │
│    ┌────────┐    ┌─────────┐    ┌──────────┐    ┌──────────┐    ┌────────┐  │
│    │  Data  │    │ Airbyte │    │ BigQuery │    │ Superset │    │ Users  │  │
│    │Sources │───►│   ETL   │───►│   DWH    │───►│Dashboards│───►│        │  │
│    └────────┘    └─────────┘    └──────────┘    └──────────┘    └────────┘  │
│                                                                               │
│    GA4            Data           Google          Apache         Marketing    │
│    Ad Platforms   Pipeline       Cloud           Superset       Team         │
│    Bank CSVs                                                                  │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology | What It Does |
|-------|------------|--------------|
| **Data Sources** | GA4, Ad Platforms, CSVs | Raw data |
| **Data Ingestion** | Airbyte | ETL pipeline |
| **Data Warehouse** | Google BigQuery | Storage & processing |
| **Compute** | Google Cloud VM | Hosts all services |
| **Visualization** | Apache Superset | Dashboards & reports |
| **Automation** | Python + Cron | Daily data refresh |
| **Version Control** | GitHub | Code backup |

---

## Delivered

| Item | Count |
|------|-------|
| Platform services | 4 (Airbyte, BigQuery, Superset, VM) |
| Database tables | 11 |
| Dashboards | 4 |
| Charts | 25 |
| Data records | 114K+ |

---

## Dashboards

1. **Executive Overview** - KPIs & trends
2. **Channel & Campaign** - Traffic sources
3. **Funnels & Cohorts** - Conversion tracking
4. **Deep Analysis** - Device, geo, time

---

## Monthly Cost

| Service | Cost |
|---------|------|
| Google Cloud VM | ~$40 |
| BigQuery | ~$15 |
| **Total** | **~$55/mo** |

---

## Access

| Service | URL |
|---------|-----|
| **Superset** | http://34.66.133.243:8088 |
| **Airbyte** | http://34.66.133.243:8000 |
| **GitHub** | github.com/harutdram/Ineco-Analytics |

---

*Built from scratch in February 2026*
