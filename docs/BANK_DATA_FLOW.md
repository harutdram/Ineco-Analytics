# Bank Conversion Data Flow

## Current BigQuery Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA LAYERS                                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  📁 ineco_raw (Raw Data - As Received)                                  │
│     └── bank_conversions          ← CSV files from Ineco                │
│     └── ad_spend                  ← Manual uploads                       │
│     └── ads_insights, campaigns   ← Airbyte (Facebook)                  │
│                                                                          │
│  📁 ineco_staging (Cleaned & Deduplicated)                              │
│     └── stg_bank_conversions      ← Deduplicated, validated             │
│     └── stg_events                ← GA4 events cleaned                  │
│                                                                          │
│  📁 ineco_marts (Business-Ready Facts & Dimensions)                     │
│     └── fact_bank_conversions     ← Final aggregated data               │
│     └── fact_sessions             ← Website sessions                    │
│     └── fact_conversions          ← Website conversions                 │
│     └── fact_ad_spend             ← Ad platform spend                   │
│     └── dim_date, dim_channel...  ← Dimension tables                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Bank Data Flow (Email → BigQuery → Superset)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   Ineco Bank                                                             │
│   ┌─────────┐     Email      ┌─────────┐     Upload      ┌───────────┐ │
│   │  Core   │ ─────────────► │   CSV   │ ──────────────► │  ineco_   │ │
│   │ Banking │   (Daily/      │  File   │   (Manual or    │    raw    │ │
│   │ System  │    Weekly)     │         │    Script)      │           │ │
│   └─────────┘                └─────────┘                 └───────────┘ │
│                                                                 │       │
│                                           ┌─────────────────────┘       │
│                                           ▼                             │
│                              ┌─────────────────────┐                    │
│                              │  Deduplication &    │                    │
│                              │  Validation Script  │                    │
│                              └─────────────────────┘                    │
│                                           │                             │
│                                           ▼                             │
│                              ┌─────────────────────┐                    │
│                              │   ineco_staging.    │                    │
│                              │ stg_bank_conversions│                    │
│                              └─────────────────────┘                    │
│                                           │                             │
│                                           ▼                             │
│                              ┌─────────────────────┐                    │
│                              │   ineco_marts.      │                    │
│                              │fact_bank_conversions│──► Superset       │
│                              └─────────────────────┘                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Handling Duplicates & Overlapping Data

### Unique Key for Deduplication
Each record is uniquely identified by:
- `token_id` (Event Param Value - UUID)
- `client_code`
- `event_date`

### Deduplication Strategy
```sql
-- When loading new data, use MERGE to avoid duplicates
MERGE INTO stg_bank_conversions target
USING new_data source
ON target.token_id = source.token_id 
   AND target.client_code = source.client_code
WHEN MATCHED THEN UPDATE SET ...  -- Update if changed
WHEN NOT MATCHED THEN INSERT ...  -- Insert if new
```

## Data Loading Process

### Step 1: Receive CSV via Email
- Ineco sends: `bank_conversions_YYYYMMDD.csv`
- Save to: `/Users/harut/Desktop/Ineco/data/incoming/`

### Step 2: Upload to Raw Layer
```bash
python3 load_bank_data.py /path/to/file.csv
```

### Step 3: Deduplicate to Staging
Automatic deduplication based on unique key

### Step 4: Refresh Marts
```bash
python3 refresh_marts.py
```

## File Naming Convention

Ineco should name files as:
```
bank_conversions_YYYYMMDD.csv       # Daily file
bank_conversions_YYYYMMDD_YYYYMMDD.csv  # Date range
```

## Expected Frequency

| Scenario | Recommendation |
|----------|----------------|
| Ideal | Daily export (previous day's data) |
| Acceptable | Weekly export (last 7 days) |
| Minimum | Weekly with full month overlap |

## Data Quality Checks

Before loading:
1. ✅ Check required columns exist
2. ✅ Validate date formats
3. ✅ Check for empty critical fields
4. ✅ Log duplicate count

## Contact for Data

Ineco IT Team should export from core banking:
- Filter: Digital channel applications only
- Include: All loan, card, deposit applications
- Fields: As per current CSV structure
