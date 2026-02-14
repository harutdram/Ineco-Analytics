# Custom Superset image with BigQuery support
FROM apache/superset:6.0.0

USER root

# Use uv to install packages into the virtual environment
# - psycopg2-binary: PostgreSQL driver (for Superset metadata DB)
# - sqlalchemy-bigquery: Google BigQuery driver
# - shillelagh[gsheetsapi]: Google Sheets driver
RUN uv pip install --python /app/.venv/bin/python \
    psycopg2-binary \
    "sqlalchemy-bigquery>=1.15.0,<2.0.0" \
    "shillelagh[gsheetsapi]"

USER superset
