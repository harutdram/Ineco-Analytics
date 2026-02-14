# Ineco Bank - GCP Permissions Request for Superset Analytics Platform

**Project:** x-victor-477214-g0  
**Requested for:** harutyun.amirkhanyan@gmail.com  
**Purpose:** Deploy and manage the INECOBANK Growth Marketing analytics platform (Apache Superset) on Google Cloud

---

## Summary of Request

We need permissions to:
1. Deploy Superset on a Compute Engine VM
2. Connect Superset to BigQuery
3. Manage the platform (updates, monitoring, troubleshooting)

---

## Option A: Simple Request (Recommended)

**Grant the following user the Editor role on the project:**

| What to add | Value |
|-------------|-------|
| **Principal (email)** | `harutyun.amirkhanyan@gmail.com` |
| **Role** | **Editor** |
| **Scope** | Project: `x-victor-477214-g0` |

**How to do it in Google Cloud Console:**
1. Go to [IAM & Admin → IAM](https://console.cloud.google.com/iam-admin/iam)
2. Select project `x-victor-477214-g0`
3. Click **+ Grant Access**
4. New principals: `harutyun.amirkhanyan@gmail.com`
5. Role: **Editor**
6. Click **Save**

**Using gcloud (run by project Owner):**
```bash
gcloud projects add-iam-policy-binding x-victor-477214-g0 \
  --member="user:harutyun.amirkhanyan@gmail.com" \
  --role="roles/editor"
```

**This single role covers everything below.**

---

## Option B: Minimal Permissions (If Editor is too broad)

If Ineco prefers to grant only the minimum required permissions, use these roles:

| Role | Purpose |
|------|---------|
| **Compute Admin** | Create/manage VMs, disks, firewall rules |
| **Service Usage Admin** | Enable APIs (Compute Engine, BigQuery) |
| **BigQuery User** | Run queries, connect Superset to BigQuery |
| **BigQuery Data Viewer** | Read data from BigQuery datasets |
| **Storage Object Viewer** (optional) | If using Cloud Storage for backups |

**gcloud command for minimal permissions:**
```bash
PROJECT="x-victor-477214-g0"
USER="harutyun.amirkhanyan@gmail.com"

gcloud projects add-iam-policy-binding $PROJECT \
  --member="user:$USER" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT \
  --member="user:$USER" \
  --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT \
  --member="user:$USER" \
  --role="roles/bigquery.user"

gcloud projects add-iam-policy-binding $PROJECT \
  --member="user:$USER" \
  --role="roles/bigquery.dataViewer"
```

---

## BigQuery Service Account (Separate)

Superset connects to BigQuery using a **service account** (not a user account). Ineco needs to either:

### Option 1: Create a new service account for Superset
1. Go to IAM & Admin → Service Accounts
2. Create service account: `superset-bigquery`
3. Grant it: **BigQuery User** + **BigQuery Data Viewer**
4. Create JSON key and provide it to us (securely)

### Option 2: Use existing service account
- If there's already a service account with BigQuery access
- Provide the JSON key file
- Ensure it has access to the datasets Superset will use

**Datasets:** Ineco should specify which BigQuery datasets the service account needs access to (e.g. `marketing_data`, `analytics`, etc.)

---

## What We Will Do With These Permissions

| Action | Permissions Used |
|--------|------------------|
| Create VM (e2-standard-2) | Compute Admin |
| Create firewall (port 8088) | Compute Admin |
| Enable Compute API | Service Usage Admin |
| Deploy Superset via Docker | Compute Admin |
| Connect to BigQuery | BigQuery User + Data Viewer |
| Future: Add HTTPS/domain | Compute Admin |
| Future: Upgrade VM size | Compute Admin |
| Future: Cloud SQL (optional) | Would need additional roles |

---

## Email Template (Copy-Paste for Ineco)

---

**Subject:** GCP Permissions Request - Superset Analytics Platform (Project x-victor-477214-g0)

Dear [Ineco IT Team],

We are deploying the INECOBANK Growth Marketing analytics platform (Apache Superset) on Google Cloud. To complete the deployment, we need the following:

**1. User account access**  
Please grant **Editor** role on project **x-victor-477214-g0** to:
- **harutyun.amirkhanyan@gmail.com**

This allows us to create the Compute Engine VM, configure networking, and manage the Superset application.

**2. BigQuery access**  
Please create a service account for Superset with:
- **BigQuery User** role
- **BigQuery Data Viewer** role  
- Access to the datasets we will use for analytics

Then provide the JSON key file securely (the service account will be used only to connect Superset to BigQuery).

**3. Datasets**  
Please confirm which BigQuery datasets the Superset service account should have read access to:  
[Add list of datasets, e.g. marketing_data, campaign_analytics, etc.]

Thank you,  
[Your name]

---

## Checklist for Ineco

- [ ] Grant Editor role to harutyun.amirkhanyan@gmail.com on project x-victor-477214-g0
- [ ] Create service account for Superset with BigQuery User + BigQuery Data Viewer
- [ ] Grant service account access to required BigQuery datasets
- [ ] Provide JSON key file securely
- [ ] Confirm dataset names for connection

---

## After Permissions Are Granted

Once we receive confirmation and the BigQuery key (if applicable), we will:

1. Create the firewall rule
2. Create the VM (e2-standard-2, ~$60/month)
3. Deploy Superset from GitHub
4. Configure BigQuery connection
5. Provide the access URL and admin credentials
