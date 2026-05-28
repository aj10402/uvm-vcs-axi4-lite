#!/bin/bash

# AXI4-Lite UVM Testbench Regression Test Script
# Runs all test types and generates consolidated report

LOG_DIR="logs"
REPORT_FILE="$LOG_DIR/regression_report.txt"

# Create log directory
mkdir -p $LOG_DIR

echo "==========================================" > $REPORT_FILE
echo "AXI4-Lite UVM Regression Test Report" >> $REPORT_FILE
echo "==========================================" >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "Start Time: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Test configurations
TESTS=(
    "axi4_lite_write_read_test:Write-Read Pairing Test"
    "axi4_lite_partial_write_test:Partial Write (WSTRB) Test"
    "axi4_lite_stress_test:Stress Test (Random Transactions)"
    "axi4_lite_back_to_back_test:Back-to-Back Test"
    "axi4_lite_reset_test:Reset Behavior Test"
)

PASSED=0
FAILED=0
TOTAL=${#TESTS[@]}

echo "Running regression tests..."
echo ""

for test_config in "${TESTS[@]}"; do
    # Parse test name and description
    IFS=':' read -r test_name description <<< "$test_config"

    echo "=========================================="
    echo "Running: $description"
    echo "Test: $test_name"
    echo "=========================================="

    # Run the test
    ./simv +UVM_TESTNAME=$test_name -l $LOG_DIR/${test_name}.log

    # Check result
    if [ $? -eq 0 ]; then
        result="PASSED"
        ((PASSED++))
        echo "✅ $description: PASSED"
    else
        result="FAILED"
        ((FAILED++))
        echo "❌ $description: FAILED"
    fi

    # Log to report
    echo "Test: $description" >> $REPORT_FILE
    echo "Result: $result" >> $REPORT_FILE
    echo "Log File: $LOG_DIR/${test_name}.log" >> $REPORT_FILE
    echo "" >> $REPORT_FILE

    echo ""
done

# Generate summary
echo "==========================================" >> $REPORT_FILE
echo "REGRESSION SUMMARY" >> $REPORT_FILE
echo "==========================================" >> $REPORT_FILE
echo "Total Tests: $TOTAL" >> $REPORT_FILE
echo "Passed: $PASSED" >> $REPORT_FILE
echo "Failed: $FAILED" >> $REPORT_FILE
echo "Pass Rate: $((PASSED * 100 / TOTAL))%" >> $REPORT_FILE
echo "" >> $REPORT_FILE
echo "End Time: $(date)" >> $REPORT_FILE

# Print summary to console
echo "=========================================="
echo "REGRESSION SUMMARY"
echo "=========================================="
echo "Total Tests: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Pass Rate: $((PASSED * 100 / TOTAL))%"
echo ""
echo "Detailed report saved to: $REPORT_FILE"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed! Regression successful."
    exit 0
else
    echo "⚠️  Some tests failed. Check logs for details."
    exit 1
fi