# BigQuery Scheduled Queries

## Overview

The mart tables are refreshed daily via a cron job on the GCE VM.

## Schedule

| Job | Time (UTC) | Description |
|-----|------------|-------------|
| PostgreSQL Backup | 02:00 | Backup Superset database to GCS |
| Mart Refresh | 06:00 | Refresh all BigQuery mart tables |

## Cron Jobs on VM

```bash
# View current cron jobs
crontab -l

# Current schedule:
0 2 * * * /home/harut/backup-superset.sh >> /home/harut/backup.log 2>&1
0 6 * * * /home/harut/.local/bin/python3 /home/harut/superset/bigquery/refresh_marts.py >> /home/harut/mart_refresh.log 2>&1
```

## Manual Refresh

To manually refresh the mart tables:

```bash
# SSH to VM
gcloud compute ssh superset-ineco --zone=us-central1-a --project=x-victor-477214-g0

# Run refresh script
export GOOGLE_APPLICATION_CREDENTIALS=/home/harut/superset/credentials/bigquery-service-account.json
python3 /home/harut/superset/bigquery/refresh_marts.py
```

## Logs

```bash
# View refresh logs
cat /home/harut/mart_refresh.log

# View backup logs
cat /home/harut/backup.log
```

## Tables Refreshed

1. `ineco_marts.mart_daily_overview` - Executive KPIs
2. `ineco_marts.mart_acquisition` - Traffic source performance
3. `ineco_marts.mart_funnel` - Conversion funnel
4. `ineco_marts.mart_product_performance` - Product metrics
5. `ineco_marts.mart_campaign_performance` - Campaign metrics

## Troubleshooting

If mart refresh fails:

1. Check the log: `cat /home/harut/mart_refresh.log`
2. Verify credentials: `ls -la /home/harut/superset/credentials/`
3. Test BigQuery connection manually
4. Check if service account has BigQuery permissions
