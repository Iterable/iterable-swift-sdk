#!/bin/bash
set -e

# This script processes XCResult files into GitHub Check-friendly format
# Usage: ./process-test-results.sh <xcresult_path> <test_type> <output_dir> [open_in_browser]
# Example: ./process-test-results.sh TestResults.xcresult "Unit Tests" ./reports true

XCRESULT_PATH="$1"
TEST_TYPE="$2"
OUTPUT_DIR="${3:-.}"
OPEN_IN_BROWSER="${4:-false}"

if [ -z "$XCRESULT_PATH" ] || [ -z "$TEST_TYPE" ]; then
  echo "Usage: $0 <xcresult_path> <test_type> [output_dir] [open_in_browser]"
  echo "Example: $0 TestResults.xcresult \"Unit Tests\" ./reports true"
  exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "Warning: jq not found, will use fallback method for parsing JSON"
  USE_JQ=false
else
  USE_JQ=true
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Process XCResult into HTML file and JSON summary
if [ "$OPEN_IN_BROWSER" = "true" ]; then
  python scripts/process_xcresult.py --path "$XCRESULT_PATH" --output "$OUTPUT_DIR/test-results.html" --summary-json "$OUTPUT_DIR/test-summary.json" --open-in-browser
else
  python scripts/process_xcresult.py --path "$XCRESULT_PATH" --output "$OUTPUT_DIR/test-results.html" --summary-json "$OUTPUT_DIR/test-summary.json"
fi

# Split the HTML into summary and details for GitHub Checks
# First 10000 chars for summary, rest for details
cat "$OUTPUT_DIR/test-results.html" | head -c 10000 > "$OUTPUT_DIR/report-summary.html"
cat "$OUTPUT_DIR/test-results.html" > "$OUTPUT_DIR/report-detail.html"

# Create a simple markdown summary for the job summary
echo "# $TEST_TYPE Results Summary" > "$OUTPUT_DIR/report-summary.md"
echo "$TEST_TYPE run completed. See GitHub Checks for full HTML report." >> "$OUTPUT_DIR/report-summary.md"

# Extract test statistics from JSON summary
echo "## Test Statistics" >> "$OUTPUT_DIR/report-summary.md"

# Read values from JSON
if [ "$USE_JQ" = true ]; then
  # Use jq if available
  TOTAL_TESTS=$(jq -r '.total_tests' "$OUTPUT_DIR/test-summary.json")
  PASSED_TESTS=$(jq -r '.passed_tests' "$OUTPUT_DIR/test-summary.json")
  FAILED_TESTS=$(jq -r '.failed_tests' "$OUTPUT_DIR/test-summary.json")
  SKIPPED_TESTS=$(jq -r '.skipped_tests' "$OUTPUT_DIR/test-summary.json")
  SUCCESS_RATE=$(jq -r '.success_rate' "$OUTPUT_DIR/test-summary.json")
else
  # Fallback to grep
  TOTAL_TESTS=$(grep -o '"total_tests":[0-9]*' "$OUTPUT_DIR/test-summary.json" | grep -o '[0-9]*')
  PASSED_TESTS=$(grep -o '"passed_tests":[0-9]*' "$OUTPUT_DIR/test-summary.json" | grep -o '[0-9]*')
  FAILED_TESTS=$(grep -o '"failed_tests":[0-9]*' "$OUTPUT_DIR/test-summary.json" | grep -o '[0-9]*')
  SKIPPED_TESTS=$(grep -o '"skipped_tests":[0-9]*' "$OUTPUT_DIR/test-summary.json" | grep -o '[0-9]*')
  SUCCESS_RATE=$(grep -o '"success_rate":[0-9.]*' "$OUTPUT_DIR/test-summary.json" | grep -o '[0-9.]*')
fi

# Output statistics to markdown
echo "* Total Tests: $TOTAL_TESTS" >> "$OUTPUT_DIR/report-summary.md"
echo "* Tests Passed: $PASSED_TESTS" >> "$OUTPUT_DIR/report-summary.md"
echo "* Tests Failed: $FAILED_TESTS" >> "$OUTPUT_DIR/report-summary.md"
if [ "$SKIPPED_TESTS" -gt 0 ]; then
  echo "* Tests Skipped: $SKIPPED_TESTS" >> "$OUTPUT_DIR/report-summary.md"
fi
echo "* Success Rate: ${SUCCESS_RATE}%" >> "$OUTPUT_DIR/report-summary.md"

# Include a link to the full report
echo "" >> "$OUTPUT_DIR/report-summary.md"
echo "For complete details, see the Check Run or download the test-results artifact." >> "$OUTPUT_DIR/report-summary.md"

echo "Test results processed successfully:"
echo "- Total tests: $TOTAL_TESTS"
echo "- Passed tests: $PASSED_TESTS"
echo "- Failed tests: $FAILED_TESTS"
if [ "$SKIPPED_TESTS" -gt 0 ]; then
  echo "- Skipped tests: $SKIPPED_TESTS"
fi
echo "- Success rate: ${SUCCESS_RATE}%" 