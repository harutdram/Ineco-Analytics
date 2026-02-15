-- Dimension: dim_product
-- Product dimension with Ineco banking products and funnel definitions
-- Grain: 1 row per product category

CREATE OR REPLACE TABLE `x-victor-477214-g0.ineco_marts.dim_product` AS
SELECT * FROM UNNEST([
  -- LOANS (Sprint funnel)
  STRUCT(1 AS product_key, 'Consumer Loans' AS product_name, 'Loans' AS product_group, 
         'Sprint, 1-Click, Refinance loans' AS description, TRUE AS has_funnel,
         'sprint_apply_button_click' AS apply_event, 'Get Sub ID sprint' AS sub_id_event, 
         'check_limit_click' AS check_limit_event),
  STRUCT(2, 'Car Loans', 'Loans', 'Auto/vehicle loans', TRUE,
         'sprint_apply_button_click', 'Get Sub ID sprint', 'check_limit_click'),
  STRUCT(3, 'Mortgage', 'Loans', 'Home mortgage loans', TRUE,
         'sprint_apply_button_click', 'Get Sub ID sprint', 'check_limit_click'),
  
  -- CARDS & DEPOSITS (Registration funnel)
  STRUCT(4, 'Cards', 'Cards', 'Credit and debit cards', TRUE,
         'Reg_apply_button_click', 'Get Sub ID', CAST(NULL AS STRING)),
  STRUCT(5, 'Deposits', 'Deposits', 'Savings and term deposits', TRUE,
         'Reg_apply_button_click', 'Get Sub ID', CAST(NULL AS STRING)),
  
  -- OTHER PRODUCTS (no funnel tracking)
  STRUCT(6, 'Digital Banking', 'Services', 'Mobile and online banking', FALSE, 
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(7, 'Accounts', 'Services', 'Current and savings accounts', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(8, 'Business', 'Business', 'Business banking services', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(9, 'Salary Project', 'Services', 'Corporate salary programs', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(10, 'Campaigns', 'Marketing', 'Seasonal promotions', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(11, 'Homepage', 'General', 'Main website', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(12, 'Support & Info', 'General', 'Help and information pages', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(13, 'User Account', 'General', 'User profile pages', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING)),
  STRUCT(14, 'Other', 'Other', 'Uncategorized pages', FALSE,
         CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING))
]);
