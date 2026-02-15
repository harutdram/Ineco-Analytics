-- Ineco Performance Marketing Dashboards
-- Based on DASHBOARD_DESIGN.md v2.0
-- Total: 25 charts across 4 dashboards

-- First, rename dashboards to match design
UPDATE dashboards SET dashboard_title = 'Executive Overview' WHERE id = 1;
UPDATE dashboards SET dashboard_title = 'Channel & Campaign' WHERE id = 2;
UPDATE dashboards SET dashboard_title = 'Funnels & Cohorts' WHERE id = 3;
UPDATE dashboards SET dashboard_title = 'Deep Analysis' WHERE id = 4;
DELETE FROM dashboards WHERE id IN (5, 6);

-- ============================================================
-- DASHBOARD 1: EXECUTIVE OVERVIEW (8 charts)
-- ============================================================

-- Chart 1: Total Sessions KPI
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Total Sessions',
  'big_number_total',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "big_number_total",
    "metric": {"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"},
    "adhoc_filters": [],
    "header_font_size": 0.4,
    "subheader_font_size": 0.15,
    "y_axis_format": ",.0f",
    "time_format": "%Y-%m-%d"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 2: Total Users KPI
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Total Users',
  'big_number_total',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "big_number_total",
    "metric": {"expressionType": "SIMPLE", "column": {"column_name": "users"}, "aggregate": "SUM", "label": "Users"},
    "adhoc_filters": [],
    "header_font_size": 0.4,
    "subheader_font_size": 0.15,
    "y_axis_format": ",.0f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 3: Total Registrations KPI
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Total Registrations',
  'big_number_total',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "big_number_total",
    "metric": {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"},
    "adhoc_filters": [],
    "header_font_size": 0.4,
    "subheader_font_size": 0.15,
    "y_axis_format": ",.0f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 4: Total Apply Clicks KPI
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Total Apply Clicks',
  'big_number_total',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "big_number_total",
    "metric": {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Apply Clicks"},
    "adhoc_filters": [],
    "header_font_size": 0.4,
    "subheader_font_size": 0.15,
    "y_axis_format": ",.0f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 5: Bounce Rate KPI
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Bounce Rate',
  'big_number_total',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "big_number_total",
    "metric": {"expressionType": "SQL", "sqlExpression": "SAFE_DIVIDE(SUM(bounced_sessions), SUM(sessions)) * 100", "label": "Bounce Rate %"},
    "adhoc_filters": [],
    "header_font_size": 0.4,
    "subheader_font_size": 0.15,
    "y_axis_format": ",.1f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 6: CVR KPI (Apply to Registration)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Conversion Rate',
  'big_number_total',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "big_number_total",
    "metric": {"expressionType": "SQL", "sqlExpression": "SAFE_DIVIDE(SUM(registrations), SUM(loans_apply_click) + SUM(cards_deposits_apply_click)) * 100", "label": "CVR %"},
    "adhoc_filters": [],
    "header_font_size": 0.4,
    "subheader_font_size": 0.15,
    "y_axis_format": ",.2f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 7: Daily Trend (Sessions & Registrations)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Daily Performance Trend',
  'echarts_timeseries_line',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "echarts_timeseries_line",
    "x_axis": "date",
    "time_grain_sqla": "P1D",
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SIMPLE", "column": {"column_name": "users"}, "aggregate": "SUM", "label": "Users"}
    ],
    "groupby": [],
    "adhoc_filters": [],
    "row_limit": 1000,
    "show_legend": true,
    "legendOrientation": "top",
    "y_axis_format": ",.0f",
    "rich_tooltip": true
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 8: Channel Contribution (Stacked Bar)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Channel Contribution',
  'echarts_timeseries_bar',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "echarts_timeseries_bar",
    "x_axis": "date",
    "time_grain_sqla": "P1W",
    "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"}],
    "groupby": ["channel_group"],
    "adhoc_filters": [],
    "row_limit": 1000,
    "stack": "Stack",
    "show_legend": true,
    "legendOrientation": "top"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- ============================================================
-- DASHBOARD 2: CHANNEL & CAMPAIGN (7 charts)
-- ============================================================

-- Chart 9: Channel Performance Table
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Channel Performance Table',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["channel_group"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SIMPLE", "column": {"column_name": "total_users"}, "aggregate": "SUM", "label": "Users"},
      {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Applies"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"},
      {"expressionType": "SQL", "sqlExpression": "SAFE_DIVIDE(SUM(registrations), SUM(loans_apply_click) + SUM(cards_deposits_apply_click)) * 100", "label": "CVR %"}
    ],
    "adhoc_filters": [],
    "row_limit": 50,
    "order_by_cols": ["[\"registrations\", false]"],
    "table_timestamp_format": "%Y-%m-%d",
    "page_length": 20
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 10: Top Campaigns Table
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Top Campaigns',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["campaign", "channel_group"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Applies"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"}
    ],
    "adhoc_filters": [],
    "row_limit": 20,
    "order_by_cols": ["[\"registrations\", false]"],
    "page_length": 20
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 11: Channel Trend Line
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Channel Trend',
  'echarts_timeseries_line',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "echarts_timeseries_line",
    "x_axis": "date",
    "time_grain_sqla": "P1D",
    "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"}],
    "groupby": ["channel_group"],
    "adhoc_filters": [],
    "row_limit": 5000,
    "show_legend": true,
    "legendOrientation": "top",
    "y_axis_format": ",.0f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 12: Registrations by Channel (Bar)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Registrations by Channel',
  'echarts_timeseries_bar',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "dist_bar",
    "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"}],
    "groupby": ["channel_group"],
    "adhoc_filters": [],
    "row_limit": 20,
    "y_axis_format": ",.0f",
    "show_legend": false,
    "color_scheme": "supersetColors"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 13: Campaign ROI Scatter (Using available metrics)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Campaign Performance Matrix',
  'bubble',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "bubble",
    "entity": "campaign",
    "x": {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
    "y": {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"},
    "size": {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Applies"},
    "adhoc_filters": [],
    "row_limit": 50,
    "max_bubble_size": 50,
    "color_scheme": "supersetColors"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 14: Paid vs Organic Split
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Paid vs Organic',
  'dist_bar',
  19,
  'table',
  '{
    "datasource": "19__table",
    "viz_type": "dist_bar",
    "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "channel_key"}, "aggregate": "COUNT", "label": "Count"}],
    "groupby": ["channel_type"],
    "adhoc_filters": [],
    "row_limit": 10,
    "y_axis_format": ",.0f",
    "color_scheme": "supersetColors"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 15: Sessions by Product Category
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Sessions by Product',
  'dist_bar',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "dist_bar",
    "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"}],
    "groupby": ["product_category"],
    "adhoc_filters": [],
    "row_limit": 10,
    "y_axis_format": ",.0f",
    "color_scheme": "supersetColors"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- ============================================================
-- DASHBOARD 3: FUNNELS & COHORTS (6 charts)
-- ============================================================

-- Chart 16: Loans Funnel
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Loans Funnel',
  'funnel',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "funnel",
    "metric": {"expressionType": "SIMPLE", "column": {"column_name": "loans_pageview"}, "aggregate": "SUM", "label": "Pageviews"},
    "groupby": [],
    "adhoc_filters": [],
    "row_limit": 10,
    "number_format": ",.0f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 17: Loans Funnel Table (Detailed)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Loans Funnel Stages',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": [],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "loans_pageview"}, "aggregate": "SUM", "label": "1. Page Views"},
      {"expressionType": "SIMPLE", "column": {"column_name": "loans_apply_click"}, "aggregate": "SUM", "label": "2. Apply Clicks"},
      {"expressionType": "SIMPLE", "column": {"column_name": "loans_sub_id"}, "aggregate": "SUM", "label": "3. Sub IDs"},
      {"expressionType": "SIMPLE", "column": {"column_name": "loans_check_limit"}, "aggregate": "SUM", "label": "4. Check Limit"},
      {"expressionType": "SIMPLE", "column": {"column_name": "loans_phone_submit"}, "aggregate": "SUM", "label": "5. Phone Submit"},
      {"expressionType": "SIMPLE", "column": {"column_name": "loans_otp_submit"}, "aggregate": "SUM", "label": "6. OTP Submit"}
    ],
    "adhoc_filters": [],
    "row_limit": 1
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 18: Cards/Deposits Funnel Table
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Cards & Deposits Funnel',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": [],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "cards_deposits_pageview"}, "aggregate": "SUM", "label": "1. Page Views"},
      {"expressionType": "SIMPLE", "column": {"column_name": "cards_deposits_apply_click"}, "aggregate": "SUM", "label": "2. Apply Clicks"},
      {"expressionType": "SIMPLE", "column": {"column_name": "cards_deposits_sub_id"}, "aggregate": "SUM", "label": "3. Sub IDs"},
      {"expressionType": "SIMPLE", "column": {"column_name": "cards_deposits_phone_submit"}, "aggregate": "SUM", "label": "4. Phone Submit"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "5. Registrations"}
    ],
    "adhoc_filters": [],
    "row_limit": 1
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 19: Funnel by Channel
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Funnel by Channel',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["channel_group"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Applies"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"},
      {"expressionType": "SQL", "sqlExpression": "SAFE_DIVIDE(SUM(registrations), SUM(loans_apply_click) + SUM(cards_deposits_apply_click)) * 100", "label": "Apply→Reg %"}
    ],
    "adhoc_filters": [],
    "row_limit": 20,
    "order_by_cols": ["[\"registrations\", false]"]
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 20: Registrations Trend
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Registrations Trend',
  'echarts_timeseries_line',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "echarts_timeseries_line",
    "x_axis": "date",
    "time_grain_sqla": "P1D",
    "metrics": [{"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"}],
    "groupby": [],
    "adhoc_filters": [],
    "row_limit": 1000,
    "show_legend": true,
    "y_axis_format": ",.0f"
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 21: Weekly Cohort Summary
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Weekly Registration Cohorts',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["date"],
    "time_grain_sqla": "P1W",
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Applies"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"}
    ],
    "adhoc_filters": [],
    "row_limit": 10,
    "order_by_cols": ["[\"date\", false]"]
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- ============================================================
-- DASHBOARD 4: DEEP ANALYSIS (4 charts)
-- ============================================================

-- Chart 22: Segment Performance Table
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Device Performance',
  'table',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["device_category"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SIMPLE", "column": {"column_name": "users"}, "aggregate": "SUM", "label": "Users"},
      {"expressionType": "SQL", "sqlExpression": "SAFE_DIVIDE(SUM(bounced_sessions), SUM(sessions)) * 100", "label": "Bounce Rate %"},
      {"expressionType": "SIMPLE", "column": {"column_name": "avg_session_duration_sec"}, "aggregate": "AVG", "label": "Avg Duration (sec)"}
    ],
    "adhoc_filters": [],
    "row_limit": 10
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 23: Country Performance
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Country Performance',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["country"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SQL", "sqlExpression": "SUM(loans_apply_click) + SUM(cards_deposits_apply_click)", "label": "Applies"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"}
    ],
    "adhoc_filters": [],
    "row_limit": 15,
    "order_by_cols": ["[\"registrations\", false]"]
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 24: User Type Analysis
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'New vs Returning Users',
  'table',
  21,
  'table',
  '{
    "datasource": "21__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["user_type"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SIMPLE", "column": {"column_name": "users"}, "aggregate": "SUM", "label": "Users"},
      {"expressionType": "SQL", "sqlExpression": "SAFE_DIVIDE(SUM(bounced_sessions), SUM(sessions)) * 100", "label": "Bounce Rate %"}
    ],
    "adhoc_filters": [],
    "row_limit": 5
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Chart 25: City Performance (Armenia)
INSERT INTO slices (slice_name, viz_type, datasource_id, datasource_type, params, created_on, changed_on, uuid)
VALUES (
  'Armenia Cities',
  'table',
  22,
  'table',
  '{
    "datasource": "22__table",
    "viz_type": "table",
    "query_mode": "aggregate",
    "groupby": ["city"],
    "metrics": [
      {"expressionType": "SIMPLE", "column": {"column_name": "total_sessions"}, "aggregate": "SUM", "label": "Sessions"},
      {"expressionType": "SIMPLE", "column": {"column_name": "registrations"}, "aggregate": "SUM", "label": "Registrations"}
    ],
    "adhoc_filters": [{"expressionType": "SIMPLE", "subject": "country", "operator": "==", "comparator": "Armenia", "clause": "WHERE"}],
    "row_limit": 10,
    "order_by_cols": ["[\"registrations\", false]"]
  }',
  NOW(), NOW(), gen_random_uuid()
);

-- Get IDs of newly created charts
-- SELECT id, slice_name FROM slices ORDER BY id DESC LIMIT 25;
