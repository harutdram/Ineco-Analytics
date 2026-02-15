-- Dimension: dim_date
-- Calendar dimension with Armenian holidays
-- Grain: 1 row per day (2025-2027)

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.dim_date` AS
WITH date_spine AS (
  SELECT date
  FROM UNNEST(GENERATE_DATE_ARRAY('2025-01-01', '2027-12-31', INTERVAL 1 DAY)) AS date
)
SELECT
  date AS date_key,
  date,
  EXTRACT(YEAR FROM date) AS year,
  EXTRACT(QUARTER FROM date) AS quarter,
  EXTRACT(MONTH FROM date) AS month,
  FORMAT_DATE('%B', date) AS month_name,
  EXTRACT(WEEK FROM date) AS week_of_year,
  EXTRACT(DAYOFWEEK FROM date) AS day_of_week,
  FORMAT_DATE('%A', date) AS day_name,
  EXTRACT(DAY FROM date) AS day_of_month,
  DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
  DATE_TRUNC(date, MONTH) AS month_start,
  DATE_TRUNC(date, QUARTER) AS quarter_start,
  CASE WHEN EXTRACT(DAYOFWEEK FROM date) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend,
  -- Armenian holidays
  CASE 
    WHEN (EXTRACT(MONTH FROM date) = 1 AND EXTRACT(DAY FROM date) IN (1, 2, 6))  -- New Year, Christmas
      OR (EXTRACT(MONTH FROM date) = 3 AND EXTRACT(DAY FROM date) = 8)  -- Women's Day
      OR (EXTRACT(MONTH FROM date) = 4 AND EXTRACT(DAY FROM date) = 24)  -- Genocide Memorial
      OR (EXTRACT(MONTH FROM date) = 5 AND EXTRACT(DAY FROM date) IN (1, 9, 28))  -- Labor, Victory, Republic
      OR (EXTRACT(MONTH FROM date) = 7 AND EXTRACT(DAY FROM date) = 5)  -- Constitution Day
      OR (EXTRACT(MONTH FROM date) = 9 AND EXTRACT(DAY FROM date) = 21)  -- Independence Day
      OR (EXTRACT(MONTH FROM date) = 12 AND EXTRACT(DAY FROM date) = 31)  -- New Year Eve
    THEN TRUE 
    ELSE FALSE 
  END AS is_holiday
FROM date_spine;
