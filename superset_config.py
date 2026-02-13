# Superset Configuration for Ineco Bank
# https://superset.apache.org/docs/configuration/configuring-superset

import os
from datetime import timedelta
from celery.schedules import crontab

# =============================================================================
# GENERAL CONFIGURATION
# =============================================================================

# App name displayed in UI and browser tab
APP_NAME = "INECOBANK Growth Marketing"

# Additional Flask-AppBuilder settings
from flask_appbuilder import __version__ as fab_version
FAB_API_SWAGGER_UI = True

# Secret key for session management (CHANGE THIS IN PRODUCTION!)
SECRET_KEY = os.environ.get("SECRET_KEY", "your-secret-key-change-in-production")

# =============================================================================
# DATABASE CONFIGURATION (Superset metadata database)
# =============================================================================

SQLALCHEMY_DATABASE_URI = (
    f"postgresql://{os.environ.get('POSTGRES_USER', 'superset')}:"
    f"{os.environ.get('POSTGRES_PASSWORD', 'superset')}@"
    f"{os.environ.get('POSTGRES_HOST', 'db')}:"
    f"{os.environ.get('POSTGRES_PORT', '5432')}/"
    f"{os.environ.get('POSTGRES_DB', 'superset')}"
)

# =============================================================================
# REDIS / CACHE CONFIGURATION
# =============================================================================

REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = os.environ.get("REDIS_PORT", 6379)
REDIS_CELERY_DB = os.environ.get("REDIS_CELERY_DB", 0)
REDIS_RESULTS_DB = os.environ.get("REDIS_RESULTS_DB", 1)

# Cache configuration
CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_DB": REDIS_RESULTS_DB,
}

DATA_CACHE_CONFIG = CACHE_CONFIG

# =============================================================================
# CELERY CONFIGURATION (for async queries)
# =============================================================================

class CeleryConfig:
    broker_url = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_CELERY_DB}"
    result_backend = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}"
    imports = ("superset.sql_lab",)
    task_annotations = {
        "sql_lab.get_sql_results": {"rate_limit": "100/s"},
    }

CELERY_CONFIG = CeleryConfig

# Enable async queries
RESULTS_BACKEND = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}"

# =============================================================================
# BIGQUERY CONFIGURATION
# =============================================================================

# Path to Google Cloud service account credentials
GOOGLE_APPLICATION_CREDENTIALS = "/app/credentials/bigquery-service-account.json"

# Set the environment variable for Google Cloud SDK
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = GOOGLE_APPLICATION_CREDENTIALS

# =============================================================================
# FEATURE FLAGS
# =============================================================================

FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_NATIVE_FILTERS": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "DASHBOARD_NATIVE_FILTERS_SET": True,
    "ALERT_REPORTS": True,
    "EMBEDDABLE_CHARTS": True,
    "EMBEDDED_SUPERSET": True,
    "ESTIMATE_QUERY_COST": True,
    "DYNAMIC_PLUGINS": False,  # Disabled - causes 404 errors
}

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

# Enable CSRF protection
WTF_CSRF_ENABLED = True

# Set cookie secure flag (enable in production with HTTPS)
SESSION_COOKIE_SECURE = os.environ.get("SESSION_COOKIE_SECURE", "False").lower() == "true"
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"

# =============================================================================
# SQL LAB CONFIGURATION
# =============================================================================

# Enable SQL Lab
SQL_MAX_ROW = 100000
DISPLAY_MAX_ROW = 10000

# Timeout for SQL queries (seconds)
SQLLAB_TIMEOUT = 300
SUPERSET_WEBSERVER_TIMEOUT = 300

# =============================================================================
# WEBSERVER CONFIGURATION
# =============================================================================

# Enable proxy fix if behind a reverse proxy (like nginx)
ENABLE_PROXY_FIX = True

# Row limit for charts
ROW_LIMIT = 50000

# =============================================================================
# FILE UPLOAD CONFIGURATION
# =============================================================================

# Allow CSV/Excel uploads
CSV_EXTENSIONS = ["csv", "tsv"]
EXCEL_EXTENSIONS = ["xls", "xlsx"]
COLUMNAR_EXTENSIONS = ["parquet"]
ALLOWED_EXTENSIONS = CSV_EXTENSIONS + EXCEL_EXTENSIONS + COLUMNAR_EXTENSIONS

# Max upload size (100MB)
CSV_ROW_LIMIT = 100000
UPLOAD_FOLDER = "/app/superset_home/uploads/"

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

LOG_FORMAT = "%(asctime)s:%(levelname)s:%(name)s:%(message)s"
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")

# =============================================================================
# LANGUAGE / LOCALIZATION
# =============================================================================

# Available languages
# Note: Russian translation is partial in Superset (some UI elements remain in English)
LANGUAGES = {
    "en": {"flag": "us", "name": "English"},
    "ru": {"flag": "ru", "name": "Russian"},
}

# Default language
BABEL_DEFAULT_LOCALE = "en"

# =============================================================================
# THEME CONFIGURATION
# =============================================================================

# Default to light theme
DEFAULT_THEME = "light"

# =============================================================================
# BRANDING - INECOBANK
# =============================================================================

# Custom logo for navbar
APP_ICON = "/static/assets/custom/inecobank_logo.png"

# Custom favicon
FAVICONS = [
    {"href": "/static/assets/custom/inecobank_favicon.png"}
]

# Welcome message
WELCOME_MESSAGE = "Welcome to INECOBANK Growth Marketing Platform"

# =============================================================================
# INECOBANK BRAND COLORS
# =============================================================================

# Inecobank Green: #48a74a
EXTRA_CATEGORICAL_COLOR_SCHEMES = [
    {
        "id": "inecobank",
        "description": "Inecobank brand colors",
        "label": "Inecobank",
        "isDefault": True,
        "colors": [
            "#48a74a",  # Inecobank Green (primary)
            "#3d8b3f",  # Darker green
            "#5cb85c",  # Lighter green
            "#2e7d32",  # Deep green
            "#81c784",  # Soft green
            "#1b5e20",  # Forest green
            "#a5d6a7",  # Pale green
            "#4caf50",  # Material green
            "#66bb6a",  # Light material green
            "#43a047",  # Medium green
        ],
    }
]

# Theme overrides for Ant Design components (buttons, etc.)
THEME_OVERRIDES = {
    "colors": {
        "primary": {
            "base": "#48a74a",
            "dark1": "#3d8b3f",
            "dark2": "#2e7d32",
            "light1": "#5cb85c",
            "light2": "#81c784",
            "light3": "#a5d6a7",
            "light4": "#c8e6c9",
            "light5": "#e8f5e9",
        },
        "secondary": {
            "base": "#3d8b3f",
            "dark1": "#2e7d32",
            "dark2": "#1b5e20",
            "light1": "#48a74a",
            "light2": "#5cb85c",
            "light3": "#81c784",
            "light4": "#a5d6a7",
            "light5": "#c8e6c9",
        },
    },
}
