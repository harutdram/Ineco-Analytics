-- ================================================================
-- DASHBOARD UPGRADE: Adding Bank Conversion Data
-- ================================================================

-- Step 1: Add fact_bank_conversions dataset (ID will be 24)
INSERT INTO tables (
  table_name, schema, database_id, sql, is_sqllab_view, 
  filter_select_enabled, main_dttm_col,
  created_on, changed_on, uuid
)
SELECT 
  'fact_bank_conversions',
  'ineco_marts',
  1,
  NULL,
  false,
  true,
  'date',
  NOW(),
  NOW(),
  gen_random_uuid()
WHERE NOT EXISTS (
  SELECT 1 FROM tables WHERE table_name = 'fact_bank_conversions'
);

-- Get the dataset ID for reference
-- SELECT id FROM tables WHERE table_name = 'fact_bank_conversions';

-- ================================================================
-- Step 2: Add columns for the new dataset
-- ================================================================
INSERT INTO table_columns (table_id, column_name, is_dttm, type, groupby, filterable, created_on, changed_on, uuid)
SELECT t.id, col.column_name, col.is_dttm, col.col_type, true, true, NOW(), NOW(), gen_random_uuid()
FROM tables t
CROSS JOIN (VALUES 
  ('date', true, 'DATE'),
  ('channel_group', false, 'STRING'),
  ('product_category', false, 'STRING'),
  ('acquired_source', false, 'STRING'),
  ('acquired_medium', false, 'STRING'),
  ('acquired_campaign', false, 'STRING'),
  ('is_existing_customer', false, 'STRING'),
  ('is_first_interaction', false, 'INTEGER'),
  ('loan_count', false, 'INTEGER'),
  ('loan_amount', false, 'FLOAT'),
  ('deposit_count', false, 'INTEGER'),
  ('deposit_amount', false, 'FLOAT'),
  ('card_count', false, 'INTEGER'),
  ('total_revenue_amd', false, 'FLOAT')
) AS col(column_name, is_dttm, col_type)
WHERE t.table_name = 'fact_bank_conversions'
AND NOT EXISTS (
  SELECT 1 FROM table_columns tc 
  WHERE tc.table_id = t.id AND tc.column_name = col.column_name
);

-- ================================================================
-- Step 3: Create NEW KPI Charts for Executive Overview
-- ================================================================

-- Chart: Actual Loans Issued
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Actual Loans Issued',
  'big_number',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "big_number", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(loan_count)", "label": "Loans"}, "granularity_sqla": "date", "time_range": "Last month", "time_grain_sqla": "P1D", "header_font_size": 0.4, "subheader_font_size": 0.15, "y_axis_format": ",d", "header_format_selector": "SUM", "comparison_lag": 7, "comparison_color_enabled": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Actual Cards Issued
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Actual Cards Issued',
  'big_number',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "big_number", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(card_count)", "label": "Cards"}, "granularity_sqla": "date", "time_range": "Last month", "time_grain_sqla": "P1D", "header_font_size": 0.4, "subheader_font_size": 0.15, "y_axis_format": ",d", "header_format_selector": "SUM", "comparison_lag": 7, "comparison_color_enabled": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Actual Deposits
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Actual Deposits',
  'big_number',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "big_number", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(deposit_count)", "label": "Deposits"}, "granularity_sqla": "date", "time_range": "Last month", "time_grain_sqla": "P1D", "header_font_size": 0.4, "subheader_font_size": 0.15, "y_axis_format": ",d", "header_format_selector": "SUM", "comparison_lag": 7, "comparison_color_enabled": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Loan Revenue
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Loan Revenue (AMD)',
  'big_number',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "big_number", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(loan_amount)", "label": "Loan Revenue"}, "granularity_sqla": "date", "time_range": "Last month", "time_grain_sqla": "P1D", "header_font_size": 0.4, "subheader_font_size": 0.15, "y_axis_format": ",.0f", "header_format_selector": "SUM", "comparison_lag": 7, "comparison_color_enabled": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Deposit Revenue
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Deposit Revenue (AMD)',
  'big_number',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "big_number", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(deposit_amount)", "label": "Deposit Revenue"}, "granularity_sqla": "date", "time_range": "Last month", "time_grain_sqla": "P1D", "header_font_size": 0.4, "subheader_font_size": 0.15, "y_axis_format": ",.0f", "header_format_selector": "SUM", "comparison_lag": 7, "comparison_color_enabled": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Total Revenue
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Total Revenue (AMD)',
  'big_number',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "big_number", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(total_revenue_amd)", "label": "Total Revenue"}, "granularity_sqla": "date", "time_range": "Last month", "time_grain_sqla": "P1D", "header_font_size": 0.4, "subheader_font_size": 0.15, "y_axis_format": ",.0f", "header_format_selector": "SUM", "comparison_lag": 7, "comparison_color_enabled": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- ================================================================
-- Step 4: Create Channel Charts
-- ================================================================

-- Chart: Revenue by Channel (Bar)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Revenue by Channel',
  'echarts_timeseries_bar',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "echarts_timeseries_bar", "x_axis": "channel_group", "metrics": [{"expressionType": "SQL", "sqlExpression": "SUM(total_revenue_amd)", "label": "Revenue (AMD)"}], "granularity_sqla": "date", "time_range": "Last month", "groupby": ["channel_group"], "row_limit": 10, "order_desc": true, "color_scheme": "modernSunset", "show_legend": true}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Bank Conversions by Channel (Table)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Bank Conversions by Channel',
  'table',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "table", "metrics": [{"expressionType": "SQL", "sqlExpression": "SUM(loan_count)", "label": "Loans"}, {"expressionType": "SQL", "sqlExpression": "SUM(card_count)", "label": "Cards"}, {"expressionType": "SQL", "sqlExpression": "SUM(deposit_count)", "label": "Deposits"}, {"expressionType": "SQL", "sqlExpression": "SUM(total_revenue_amd)", "label": "Revenue (AMD)"}], "granularity_sqla": "date", "time_range": "Last month", "groupby": ["channel_group"], "row_limit": 20, "order_desc": true, "color_scheme": "modernSunset", "table_timestamp_format": "smart_date"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Loans by Channel (Bar)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Loans by Channel',
  'echarts_timeseries_bar',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "echarts_timeseries_bar", "x_axis": "channel_group", "metrics": [{"expressionType": "SQL", "sqlExpression": "SUM(loan_count)", "label": "Loans"}], "granularity_sqla": "date", "time_range": "Last month", "groupby": ["channel_group"], "row_limit": 10, "order_desc": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- ================================================================
-- Step 5: Create Funnel & Analysis Charts  
-- ================================================================

-- Chart: Full Funnel Summary (Table)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Full Funnel: Website to Bank',
  'table',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "table", "metrics": [{"expressionType": "SQL", "sqlExpression": "SUM(loan_count)", "label": "Actual Loans"}, {"expressionType": "SQL", "sqlExpression": "SUM(card_count)", "label": "Actual Cards"}, {"expressionType": "SQL", "sqlExpression": "SUM(deposit_count)", "label": "Actual Deposits"}, {"expressionType": "SQL", "sqlExpression": "SUM(total_revenue_amd)", "label": "Total Revenue (AMD)"}], "granularity_sqla": "date", "time_range": "Last month", "groupby": ["product_category"], "row_limit": 10, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: New vs Returning Customers
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'New vs Returning Revenue',
  'pie',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "pie", "metric": {"expressionType": "SQL", "sqlExpression": "SUM(total_revenue_amd)", "label": "Revenue"}, "granularity_sqla": "date", "time_range": "Last month", "groupby": ["is_existing_customer"], "row_limit": 10, "color_scheme": "modernSunset", "show_labels": true, "show_legend": true}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- Chart: Revenue by Campaign
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
SELECT 
  'Top Campaigns by Revenue',
  'table',
  t.id,
  'table',
  '{"datasource": "' || t.id || '__table", "viz_type": "table", "metrics": [{"expressionType": "SQL", "sqlExpression": "SUM(loan_count)", "label": "Loans"}, {"expressionType": "SQL", "sqlExpression": "SUM(card_count)", "label": "Cards"}, {"expressionType": "SQL", "sqlExpression": "SUM(total_revenue_amd)", "label": "Revenue (AMD)"}], "granularity_sqla": "date", "time_range": "Last month", "groupby": ["acquired_campaign", "channel_group"], "row_limit": 20, "order_desc": true, "color_scheme": "modernSunset"}',
  NOW(), NOW(), gen_random_uuid()
FROM tables t WHERE t.table_name = 'fact_bank_conversions';

-- ================================================================
-- Step 6: Link charts to dashboards
-- ================================================================

-- Get new chart IDs and link to Executive Overview (dashboard 7)
INSERT INTO dashboard_slices (dashboard_id, slice_id)
SELECT 7, s.id FROM slices s 
WHERE s.slice_name IN ('Actual Loans Issued', 'Actual Cards Issued', 'Actual Deposits', 
                       'Loan Revenue (AMD)', 'Deposit Revenue (AMD)', 'Total Revenue (AMD)')
AND NOT EXISTS (SELECT 1 FROM dashboard_slices ds WHERE ds.dashboard_id = 7 AND ds.slice_id = s.id);

-- Link to Channel & Campaign (dashboard 8)
INSERT INTO dashboard_slices (dashboard_id, slice_id)
SELECT 8, s.id FROM slices s 
WHERE s.slice_name IN ('Revenue by Channel', 'Bank Conversions by Channel', 'Loans by Channel', 'Top Campaigns by Revenue')
AND NOT EXISTS (SELECT 1 FROM dashboard_slices ds WHERE ds.dashboard_id = 8 AND ds.slice_id = s.id);

-- Link to Funnels & Cohorts (dashboard 9)
INSERT INTO dashboard_slices (dashboard_id, slice_id)
SELECT 9, s.id FROM slices s 
WHERE s.slice_name IN ('Full Funnel: Website to Bank')
AND NOT EXISTS (SELECT 1 FROM dashboard_slices ds WHERE ds.dashboard_id = 9 AND ds.slice_id = s.id);

-- Link to Deep Analysis (dashboard 10)
INSERT INTO dashboard_slices (dashboard_id, slice_id)
SELECT 10, s.id FROM slices s 
WHERE s.slice_name IN ('New vs Returning Revenue')
AND NOT EXISTS (SELECT 1 FROM dashboard_slices ds WHERE ds.dashboard_id = 10 AND ds.slice_id = s.id);

-- ================================================================
-- Done! Verify results
-- ================================================================
SELECT 'New charts created:' as status, COUNT(*) as count 
FROM slices WHERE datasource_id = (SELECT id FROM tables WHERE table_name = 'fact_bank_conversions');
