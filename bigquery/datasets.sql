-- BigQuery Datasets for Ineco Bank Marketing Analytics
-- Created: 2026-02-14
-- Location: EU (to match GA4 analytics_280405726 dataset)

-- Raw data layer (for CSV uploads)
CREATE SCHEMA IF NOT EXISTS `x-victor-477214-g0.ineco_raw`
OPTIONS (location = 'EU');

-- Staging layer (cleaned/transformed data)
CREATE SCHEMA IF NOT EXISTS `x-victor-477214-g0.ineco_staging`
OPTIONS (location = 'EU');

-- Mart layer (final tables for Superset)
CREATE SCHEMA IF NOT EXISTS `x-victor-477214-g0.ineco_marts`
OPTIONS (location = 'EU');
