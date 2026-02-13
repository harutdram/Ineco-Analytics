# INECOBANK Superset - Google Cloud Deployment Guide

Deploy the INECOBANK Growth Marketing platform to Google Cloud Platform using Compute Engine.

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Compute Engine VM              │
                    │  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
                    │  │Superset │ │PostgreSQL│ │   Redis   │ │
                    │  │  :8088  │ │  :5432  │ │   :6379   │ │
                    │  └─────────┘ └─────────┘ └───────────┘ │
                    └────────────────────┬──────────────────┘
                                          │
                    ┌─────────────────────▼──────────────────┐
                    │           Google BigQuery               │
                    │         (Ineco Bank Data)                │
                    └─────────────────────────────────────────┘
```

## Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed ([Install guide](https://cloud.google.com/sdk/docs/install))
- BigQuery service account JSON key (place in `credentials/` after deployment)

---

## Step 1: Create / Select GCP Project

```bash
# Login to Google Cloud
gcloud auth login

# Create new project (or use existing)
gcloud projects create ineco-analytics --name="Ineco Analytics"

# Set as active project
gcloud config set project ineco-analytics

# Enable billing (required for Compute Engine)
# Do this in Console: https://console.cloud.google.com/billing
```

---

## Step 2: Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable bigquery.googleapis.com
```

---

## Step 3: Create Firewall Rule (Allow HTTP/HTTPS)

```bash
gcloud compute firewall-rules create superset-allow-http \
  --allow tcp:8088 \
  --source-ranges 0.0.0.0/0 \
  --target-tags superset

# For production with HTTPS, use port 443 instead
# gcloud compute firewall-rules create superset-allow-https \
#   --allow tcp:443 \
#   --source-ranges 0.0.0.0/0 \
#   --target-tags superset
```

---

## Step 4: Create Compute Engine VM

```bash
# Create VM with Docker-friendly config
gcloud compute instances create superset-vm \
  --zone=us-central1-a \
  --machine-type=e2-standard-2 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --tags=superset \
  --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y git
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu
'
```

**Note:** For production, use a larger machine (e2-standard-4) and add more disk.

---

## Step 5: SSH and Deploy

### 5a. Connect to VM

```bash
gcloud compute ssh superset-vm --zone=us-central1-a
```

### 5b. Clone Repository

```bash
sudo -i  # Switch to root for Docker
cd /opt
git clone https://github.com/harutdram/Ineco-Analytics.git
cd Ineco-Analytics
```

### 5c. Create Production .env

```bash
cp .env.example .env
nano .env  # Edit with production values
```

**Required .env changes for production:**
```env
# Use strong passwords!
ADMIN_PASSWORD=<your-secure-password>
SECRET_KEY=<generate-with-openssl-rand-base64-42>
POSTGRES_PASSWORD=<strong-postgres-password>

# For external access, Superset binds to 0.0.0.0 by default
SUPERSET_PORT=8088
```

### 5d. Add BigQuery Credentials

```bash
mkdir -p credentials
# Copy your service account JSON to the VM, then:
# mv /path/to/your-key.json credentials/bigquery-service-account.json
```

### 5e. Start Superset

```bash
docker compose up -d
```

Wait 2-3 minutes for initialization.

### 5f. Get VM External IP

```bash
# From your local machine:
gcloud compute instances describe superset-vm --zone=us-central1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

Open: `http://<EXTERNAL_IP>:8088`

---

## Step 6: Production Hardening (Optional)

### Use Managed Cloud SQL (Recommended for production)

1. Create Cloud SQL PostgreSQL instance in GCP Console
2. Update `.env`:
   ```
   POSTGRES_HOST=<cloud-sql-connection-name>
   POSTGRES_PASSWORD=<cloud-sql-password>
   ```
3. Use Cloud SQL Proxy in docker-compose or connect via private IP

### Use Memorystore for Redis (Recommended for production)

1. Create Memorystore Redis instance
2. Update `.env`:
   ```
   REDIS_HOST=<memorystore-ip>
   REDIS_PORT=6379
   ```

### Set up HTTPS

Use [Cloud Load Balancing](https://cloud.google.com/load-balancing) with a backend pointing to your VM:8088, then add SSL certificate for your domain.

---

## Commands Reference

| Action | Command |
|--------|---------|
| Start | `docker compose up -d` |
| Stop | `docker compose down` |
| Logs | `docker compose logs -f superset` |
| Restart | `docker compose restart superset` |
| Reset admin password | `docker exec superset_app superset fab reset-password --username admin --password NEW_PASSWORD` |

---

## Troubleshooting

### Can't access from browser
- Check firewall rule allows port 8088
- Verify VM has external IP: `gcloud compute instances list`
- Check Superset is running: `docker compose ps`

### BigQuery connection fails
- Verify `credentials/bigquery-service-account.json` exists
- Service account needs BigQuery User + BigQuery Data Viewer roles
- Project ID in connection string must match your GCP project

### Out of memory
- Upgrade VM: `gcloud compute instances set-machine-type superset-vm --machine-type=e2-standard-4 --zone=us-central1-a`
