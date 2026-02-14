-- Table: bank_conversions (Raw layer)
-- For daily CSV uploads from bank with conversion/approval data
-- Created: 2026-02-14

CREATE TABLE IF NOT EXISTS `x-victor-477214-g0.ineco_raw.bank_conversions` (
  -- Identifiers
  application_id STRING NOT NULL,
  
  -- Dates
  application_date DATE,
  approved_date DATE,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  
  -- Product info
  product_type STRING,  -- loan, card, deposit
  product_name STRING,  -- specific product (1-click, refinance, etc.)
  
  -- Status
  status STRING,  -- pending, approved, rejected
  
  -- User matching fields
  user_phone STRING,
  user_email STRING,
  
  -- Amount
  amount FLOAT64,
  currency STRING
)
OPTIONS (
  description = 'Bank conversion data uploaded daily from CSV'
);


-- Staging view for cleaned bank conversions
CREATE OR REPLACE VIEW `x-victor-477214-g0.ineco_staging.stg_bank_conversions` AS
SELECT
  application_id,
  application_date,
  approved_date,
  uploaded_at,
  
  -- Standardize product types
  LOWER(TRIM(product_type)) AS product_type,
  product_name,
  
  -- Standardize status
  LOWER(TRIM(status)) AS status,
  
  -- Clean phone (remove spaces, dashes)
  REGEXP_REPLACE(user_phone, r'[^0-9+]', '') AS user_phone,
  LOWER(TRIM(user_email)) AS user_email,
  
  amount,
  UPPER(currency) AS currency

FROM `x-victor-477214-g0.ineco_raw.bank_conversions`;
