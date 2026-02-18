#!/usr/bin/env python3
"""
Data Quality Tests for Ineco Analytics

Runs automated checks on BigQuery tables to ensure data integrity.
Can be run manually or scheduled via cron/Cloud Scheduler.

Usage:
    python3 data_quality_tests.py
"""

import os
import sys
from datetime import datetime, timedelta
from google.cloud import bigquery

# Configuration
PROJECT_ID = 'x-victor-477214-g0'
CREDENTIALS_PATH = '/Users/harut/Desktop/Ineco/credentials/bigquery-service-account.json'

# Test thresholds
MAX_NULL_PERCENT = 5  # Max % of nulls allowed in key columns
MAX_STALENESS_DAYS = 7  # Alert if data is older than this
MIN_ROW_COUNT = 100  # Minimum expected rows per table


class DataQualityTester:
    def __init__(self):
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
        self.client = bigquery.Client(project=PROJECT_ID)
        self.results = []
        self.failures = []
    
    def run_query(self, sql):
        """Execute query and return first row"""
        return list(self.client.query(sql).result())[0]
    
    def log_result(self, test_name, passed, details=""):
        """Log test result"""
        status = "✅ PASS" if passed else "❌ FAIL"
        self.results.append({
            'test': test_name,
            'passed': passed,
            'details': details
        })
        if not passed:
            self.failures.append(test_name)
        print(f"{status} | {test_name}")
        if details:
            print(f"         {details}")
    
    # ==================== ROW COUNT TESTS ====================
    
    def test_row_counts(self):
        """Check that tables have minimum expected rows"""
        print("\n📊 ROW COUNT TESTS")
        print("-" * 50)
        
        tables = [
            ('fact_sessions', 1000),
            ('fact_conversions', 1000),
            ('fact_bank_conversions', 100),
            ('dim_channel', 5),
            ('dim_product', 3),
        ]
        
        for table, min_rows in tables:
            sql = f"SELECT COUNT(*) as cnt FROM `{PROJECT_ID}.ineco_marts.{table}`"
            try:
                result = self.run_query(sql)
                passed = result.cnt >= min_rows
                self.log_result(
                    f"{table} row count",
                    passed,
                    f"Found {result.cnt:,} rows (min: {min_rows})"
                )
            except Exception as e:
                self.log_result(f"{table} row count", False, str(e))
    
    # ==================== NULL VALUE TESTS ====================
    
    def test_null_values(self):
        """Check for unexpected nulls in key columns"""
        print("\n🔍 NULL VALUE TESTS")
        print("-" * 50)
        
        checks = [
            ('fact_sessions', 'date'),
            ('fact_sessions', 'channel_group'),
            ('fact_conversions', 'date'),
            ('fact_conversions', 'product_category'),
            ('fact_bank_conversions', 'date'),
            ('fact_bank_conversions', 'channel_group'),
            ('fact_bank_conversions', 'loan_count'),
        ]
        
        for table, column in checks:
            sql = f"""
            SELECT 
                COUNT(*) as total,
                COUNTIF({column} IS NULL) as null_count,
                SAFE_DIVIDE(COUNTIF({column} IS NULL), COUNT(*)) * 100 as null_pct
            FROM `{PROJECT_ID}.ineco_marts.{table}`
            """
            try:
                result = self.run_query(sql)
                passed = result.null_pct <= MAX_NULL_PERCENT
                self.log_result(
                    f"{table}.{column} nulls",
                    passed,
                    f"{result.null_pct:.1f}% null (max: {MAX_NULL_PERCENT}%)"
                )
            except Exception as e:
                self.log_result(f"{table}.{column} nulls", False, str(e))
    
    # ==================== DATA FRESHNESS TESTS ====================
    
    def test_data_freshness(self):
        """Check that data is recent"""
        print("\n📅 DATA FRESHNESS TESTS")
        print("-" * 50)
        
        tables = ['fact_sessions', 'fact_conversions']
        
        for table in tables:
            sql = f"""
            SELECT 
                MAX(date) as max_date,
                DATE_DIFF(CURRENT_DATE(), MAX(date), DAY) as days_old
            FROM `{PROJECT_ID}.ineco_marts.{table}`
            """
            try:
                result = self.run_query(sql)
                passed = result.days_old <= MAX_STALENESS_DAYS
                self.log_result(
                    f"{table} freshness",
                    passed,
                    f"Latest: {result.max_date} ({result.days_old} days old, max: {MAX_STALENESS_DAYS})"
                )
            except Exception as e:
                self.log_result(f"{table} freshness", False, str(e))
    
    # ==================== VALUE RANGE TESTS ====================
    
    def test_value_ranges(self):
        """Check that metrics are within expected ranges"""
        print("\n📈 VALUE RANGE TESTS")
        print("-" * 50)
        
        # Check for negative values (shouldn't exist)
        checks = [
            ('fact_sessions', 'sessions', 0, None),
            ('fact_sessions', 'users', 0, None),
            ('fact_bank_conversions', 'loan_count', 0, None),
            ('fact_bank_conversions', 'loan_amount', 0, None),
            ('fact_bank_conversions', 'card_count', 0, None),
        ]
        
        for table, column, min_val, max_val in checks:
            conditions = []
            if min_val is not None:
                conditions.append(f"{column} < {min_val}")
            if max_val is not None:
                conditions.append(f"{column} > {max_val}")
            
            where_clause = " OR ".join(conditions) if conditions else "FALSE"
            
            sql = f"""
            SELECT COUNT(*) as violations
            FROM `{PROJECT_ID}.ineco_marts.{table}`
            WHERE {where_clause}
            """
            try:
                result = self.run_query(sql)
                passed = result.violations == 0
                self.log_result(
                    f"{table}.{column} range",
                    passed,
                    f"{result.violations} out-of-range values"
                )
            except Exception as e:
                self.log_result(f"{table}.{column} range", False, str(e))
    
    # ==================== CONSISTENCY TESTS ====================
    
    def test_consistency(self):
        """Check cross-table consistency"""
        print("\n🔗 CONSISTENCY TESTS")
        print("-" * 50)
        
        # Check channel_group values are consistent
        sql = """
        SELECT 
            (SELECT COUNT(DISTINCT channel_group) FROM `x-victor-477214-g0.ineco_marts.fact_sessions`) as sessions_channels,
            (SELECT COUNT(DISTINCT channel_group) FROM `x-victor-477214-g0.ineco_marts.fact_conversions`) as conversions_channels
        """
        try:
            result = self.run_query(sql)
            passed = result.sessions_channels == result.conversions_channels
            self.log_result(
                "Channel groups match (sessions vs conversions)",
                passed,
                f"Sessions: {result.sessions_channels}, Conversions: {result.conversions_channels}"
            )
        except Exception as e:
            self.log_result("Channel groups match", False, str(e))
        
        # Check bank data totals are reasonable
        sql = """
        SELECT 
            SUM(loan_count) as loans,
            SUM(card_count) as cards,
            SUM(deposit_count) as deposits
        FROM `x-victor-477214-g0.ineco_marts.fact_bank_conversions`
        """
        try:
            result = self.run_query(sql)
            passed = result.loans > 0 and result.cards >= 0 and result.deposits >= 0
            self.log_result(
                "Bank conversion totals",
                passed,
                f"Loans: {result.loans}, Cards: {result.cards}, Deposits: {result.deposits}"
            )
        except Exception as e:
            self.log_result("Bank conversion totals", False, str(e))
    
    # ==================== DUPLICATE TESTS ====================
    
    def test_duplicates(self):
        """Check for duplicate records"""
        print("\n🔄 DUPLICATE TESTS")
        print("-" * 50)
        
        # Check for duplicate bank conversions (by unique key)
        sql = """
        SELECT COUNT(*) as dupe_count
        FROM (
            SELECT event_date, client_code, COUNT(*) as cnt
            FROM `x-victor-477214-g0.ineco_raw.bank_conversions`
            GROUP BY event_date, client_code
            HAVING cnt > 1
        )
        """
        try:
            result = self.run_query(sql)
            # Some duplicates are expected (same client, multiple products on same day)
            passed = True  # Info only, not a failure
            self.log_result(
                "bank_conversions duplicate check",
                passed,
                f"{result.dupe_count} clients with multiple conversions same day (expected)"
            )
        except Exception as e:
            self.log_result("fact_sessions duplicates", False, str(e))
    
    def run_all_tests(self):
        """Run all data quality tests"""
        print("=" * 60)
        print("DATA QUALITY TEST SUITE")
        print(f"Run at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        
        self.test_row_counts()
        self.test_null_values()
        self.test_data_freshness()
        self.test_value_ranges()
        self.test_consistency()
        self.test_duplicates()
        
        # Summary
        print("\n" + "=" * 60)
        print("SUMMARY")
        print("=" * 60)
        
        total = len(self.results)
        passed = sum(1 for r in self.results if r['passed'])
        failed = total - passed
        
        print(f"Total tests: {total}")
        print(f"Passed: {passed} ✅")
        print(f"Failed: {failed} ❌")
        
        if self.failures:
            print(f"\nFailed tests:")
            for f in self.failures:
                print(f"  - {f}")
        
        print("\n" + "=" * 60)
        
        # Return exit code (0 = all passed, 1 = some failed)
        return 0 if failed == 0 else 1


def main():
    tester = DataQualityTester()
    exit_code = tester.run_all_tests()
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
