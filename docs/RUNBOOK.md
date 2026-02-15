---
owner: Analytics Team
last_updated: 2026-02-14
review_cadence: Quarterly
audience: On-call, DevOps, Data Engineers
---

# Ineco Analytics - Runbook

> Step-by-step procedures for operations, incidents, and maintenance

---

## Quick Reference

| Item | Value |
|------|-------|
| **GCP Project** | `x-victor-477214-g0` |
| **VM** | `superset-ineco` (us-central1-a, e2-standard-2) |
| **Superset URL** | `http://<VM_EXTERNAL_IP>:8088` (check `gcloud compute instances list`) |
| **Mart refresh cron** | 6:00 AM daily |
| **Refresh script** | `/home/harut/superset/bigquery/refresh_marts.py` |
| **Log file** | `/home/harut/superset/logs/mart_refresh.log` |
| **Status file** | `/home/harut/superset/logs/mart_status.json` |

---

## 1. Daily Mart Refresh

### Normal Operation

```bash
# SSH to VM
gcloud compute ssh superset-ineco --zone=us-central1-a --project=x-victor-477214-g0

# Run refresh manually (if needed)
cd /home/harut/superset/bigquery
python3 refresh_marts.py

# Check status
python3 check_status.py
# Or: cat /home/harut/superset/logs/mart_status.json | python3 -m json.tool
```

### Verify Success

```bash
# Check last run
tail -50 /home/harut/superset/logs/mart_refresh.log

# Expected: "Completed: 17/17 tables refreshed"
# If failures: grep FAILED /home/harut/superset/logs/mart_refresh.log
```

### Verify Cron Is Running

```bash
# View crontab
crontab -l
# Expected: line with "refresh_marts.py" scheduled at 6:00

# Check last cron execution
ls -la /home/harut/superset/logs/mart_status.json
# File modification time should be today ~6 AM
```

---

## 2. Incident: Mart Refresh Failed

### Step 1: Identify failed table

```bash
cat /home/harut/superset/logs/mart_status.json | python3 -m json.tool
# Look for "status": "failed" in results
```

### Step 2: Read error

```bash
grep -A 2 "FAILED" /home/harut/superset/logs/mart_refresh.log
```

### Step 3: Common fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Unrecognized name: X` | Column/schema change in source | Update SQL in refresh_marts.py |
| `Syntax error` | SQL typo, reserved keyword | Fix query, test locally first |
| `Permission denied` | Service account issue | Check `GOOGLE_APPLICATION_CREDENTIALS` path |
| `Timeout` | Large query | Increase timeout or optimize query |
| `Rate limit` | Too many concurrent queries | Run marts sequentially (already done) |
| `Not found: Table` | Raw table missing or renamed | Check GA4 export status in GCP console |

### Step 4: Re-run after fix

```bash
python3 refresh_marts.py
```

### Step 5: If Superset still shows stale data

```bash
cd /home/harut/superset
docker-compose restart superset superset-worker
# Wait 2-3 min for restart
```

---

## 3. Incident: Superset Dashboard "Data error"

### Step 1: Identify chart and dataset

Note the chart name and error message (e.g., "Columns missing: apply_clicks").

### Step 2: Verify BigQuery table schema

```bash
# From local machine with BigQuery access
bq show --schema --format=prettyjson x-victor-477214-g0:ineco_marts.mart_NAME
```

### Step 3: Sync Superset metadata

```bash
gcloud compute ssh superset-ineco --zone=us-central1-a --project=x-victor-477214-g0

docker exec superset_db psql -U superset -d superset -c "
SELECT id, table_name FROM tables WHERE table_name = 'mart_NAME';
SELECT column_name FROM table_columns WHERE table_id = X;
"
```

If columns are missing: add them to `table_columns` or re-sync in Superset UI (Data → Datasets → Edit → Sync columns from source).

### Step 4: Restart Superset

```bash
docker-compose restart superset superset-worker
```

### Step 5: Verify fix

Open the chart in Superset UI and confirm data loads.

---

## 4. Incident: Superset Down / Not Loading

### Step 1: Check containers

```bash
docker ps -a
# superset_app, superset_db, superset_worker should be "Up"
```

### Step 2: Restart all

```bash
cd /home/harut/superset
docker-compose down
docker-compose up -d
```

### Step 3: Verify health

```bash
# Wait 60 seconds, then:
curl -s -o /dev/null -w "%{http_code}" http://localhost:8088/health
# Expected: 200
```

### Step 4: Check logs if still failing

```bash
docker-compose logs superset --tail=100
docker-compose logs superset_db --tail=50
```

### Step 5: If DB connection failed

```bash
# Ensure DB is up first
docker-compose up -d superset_db
sleep 10
docker-compose up -d superset superset-worker
```

---

## 5. Add New Mart Table

1. Write SQL in `bigquery/marts/mart_NAME.sql`
2. Add to `REFRESH_QUERIES` dict in `refresh_marts.py`
3. Deploy script to VM: `gcloud compute scp refresh_marts.py superset-ineco:/home/harut/superset/bigquery/`
4. Run refresh once manually to create table in BigQuery
5. In Superset: Data → Datasets → + Dataset → Select new table
6. Add columns to dataset, create charts, add to dashboards
7. **Update docs:** LINEAGE.md, DATA_DICTIONARY.md, DATA_QUALITY_MATRIX.md

---

## 6. Schema Change in stg_events

1. Update `stg_events` view SQL in BigQuery
2. Check impact: all 17 marts depend on stg_events (see LINEAGE.md)
3. Update mart SQL in refresh_marts.py if column names changed
4. Deploy and run full refresh
5. Update Superset dataset columns if needed (sync or manual)
6. Update chart params if column names changed
7. **Update docs:** DATA_DICTIONARY.md, METRIC_CONTRACTS.md, LINEAGE.md

---

## 7. Rollback Procedure

### Mart data (BigQuery)

- Marts are overwritten daily; no built-in snapshot
- **BigQuery time travel:** Query historical data up to 7 days back:
  ```sql
  SELECT * FROM `ineco_marts.mart_NAME`
  FOR SYSTEM_TIME AS OF TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY);
  ```
- To restore: re-run `refresh_marts.py` (will rebuild from current staging)
- For historical fix: modify stg_events view logic, then re-refresh

### Superset metadata

- **Backup before major changes:**
  ```bash
  docker exec superset_db pg_dump -U superset superset > superset_backup_$(date +%Y%m%d).sql
  ```
- **Restore from backup:**
  ```bash
  docker exec -i superset_db psql -U superset superset < superset_backup_YYYYMMDD.sql
  docker-compose restart superset superset-worker
  ```

---

## 8. Escalation

| Severity | Condition | Response Time | Action |
|----------|-----------|---------------|--------|
| **P1** | Dashboards down, exec meeting today | 2 hours | Fix immediately; notify stakeholders |
| **P2** | Mart refresh failed, data stale | Same day | Fix and re-run; document in log |
| **P3** | Minor chart error, workaround exists | 1 week | Schedule fix |

**Escalation contacts:** (to be filled by Ineco)
- Analytics lead: ___
- DevOps: ___
- Ineco stakeholder: ___

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-02-14 | v2: Added cron verification; health check; BQ time travel rollback; doc update reminders; escalation contacts placeholder; restore procedure | Analytics Team |
| 2026-02-14 | v1: Initial version | Analytics Team |
