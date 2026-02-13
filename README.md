# Ineco Bank - Apache Superset Deployment

Business Intelligence platform for Ineco Bank powered by Apache Superset, connected to Google BigQuery.

## Prerequisites

- Docker & Docker Compose
- Google Cloud service account with BigQuery access
- BigQuery dataset to connect to

## Quick Start (Local Development)

### 1. Clone and Setup

```bash
cd /path/to/this/project

# Copy environment template
cp .env.example .env

# Edit .env and set secure passwords
nano .env  # or use any editor
```

### 2. Setup BigQuery Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **IAM & Admin** → **Service Accounts**
3. Create a service account with **BigQuery User** and **BigQuery Data Viewer** roles
4. Create and download a JSON key
5. Place it in the project:

```bash
mkdir -p credentials
mv ~/Downloads/your-service-account-key.json credentials/bigquery-service-account.json
```

### 3. Start Superset

```bash
docker-compose up -d
```

Wait 1-2 minutes for initialization, then open: **http://localhost:8088**

Default login (change in `.env`):
- Username: `admin`
- Password: `admin`

### 4. Connect BigQuery

1. Go to **Settings** → **Database Connections** → **+ Database**
2. Select **Google BigQuery**
3. Use this connection string:
   ```
   bigquery://your-project-id
   ```
4. Test and save the connection

## Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f superset

# Stop all services
docker-compose down

# Stop and remove all data (fresh start)
docker-compose down -v
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Superset                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   Web    │  │  Worker  │  │   Beat   │  │  Redis   │    │
│  │  :8088   │  │ (Celery) │  │(Scheduler)│  │ (Cache)  │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │           │
│       └─────────────┴─────────────┴─────────────┘           │
│                           │                                  │
│                    ┌──────┴──────┐                          │
│                    │  PostgreSQL │                          │
│                    │  (Metadata) │                          │
│                    └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │    Google BigQuery      │
              │    (Ineco Bank Data)    │
              └─────────────────────────┘
```

## Production Deployment (Google Cloud)

See deployment instructions in `/docs/DEPLOYMENT.md` (to be created).

## Security Notes

- **NEVER** commit `.env` or credential files
- Change all default passwords before production
- Enable HTTPS in production
- Restrict BigQuery service account permissions

## Troubleshooting

### Superset not starting
```bash
docker-compose logs superset
```

### BigQuery connection issues
- Verify service account JSON is in `credentials/` folder
- Check service account has correct permissions
- Verify project ID in connection string

### Reset everything
```bash
docker-compose down -v
docker-compose up -d
```
