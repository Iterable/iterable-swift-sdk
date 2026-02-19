#!/bin/bash

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script requires macOS to run Xcode tests"
    exit 1
fi

# Parse command line arguments
FILTER=""
LIST_TESTS=false

if [[ $# -eq 1 ]]; then
    if [[ "$1" == "--list" ]]; then
        LIST_TESTS=true
    else
        FILTER="$1"
        echo "🎯 Running tests with filter: $FILTER"
    fi
elif [[ $# -gt 1 ]]; then
    echo "❌ Usage: $0 [filter|--list]"
    echo "   filter: Test suite name (e.g., 'IterableApiCriteriaFetchTests')"
    echo "           or specific test (e.g., 'IterableApiCriteriaFetchTests.testForegroundCriteriaFetchWhenConditionsMet')"
    echo "           or full path (e.g., 'unit-tests/IterableApiCriteriaFetchTests/testForegroundCriteriaFetchWhenConditionsMet')"
    echo "   --list: List all available test suites and tests"
    exit 1
fi

# Handle test listing
if [[ "$LIST_TESTS" == true ]]; then
    echo "📋 Listing available test suites..."

    # Use grep to extract test class names from source files
    echo "📦 Available Test Suites:"
    find tests/unit-tests -name "*.swift" -exec basename {} .swift \; | sort | while read test_file; do
        # Count test methods in each file
        test_count=$(grep -c "func test" "tests/unit-tests/$test_file.swift" 2>/dev/null || echo "0")
        echo "  • $test_file ($test_count tests)"
    done

    echo ""
    echo "🔍 Example Usage:"
    echo "  ./agent_test.sh AuthTests"
    echo "  ./agent_test.sh \"AuthTests.testAsyncAuthTokenRetrieval\""
    echo ""
    echo "💡 To see specific test methods in a suite, check the source file:"
    echo "  grep 'func test' tests/unit-tests/AuthTests.swift"

    exit 0
fi

# Make sure xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "xcpretty not found, installing via gem..."
    sudo gem install xcpretty
fi

echo "Running Iterable Swift SDK unit tests..."

# Create a temporary file for the test output
TEMP_OUTPUT=$(mktemp)

# Build the xcodebuild command
XCODEBUILD_CMD="xcodebuild test \
    -project swift-sdk.xcodeproj \
    -scheme swift-sdk \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
    -enableCodeCoverage YES \
    -skipPackagePluginValidation \
    CODE_SIGNING_REQUIRED=NO"

# Add filter if specified
if [[ -n "$FILTER" ]]; then
    # If filter contains a slash, use it as-is (already in unit-tests/TestSuite/testMethod format)
    if [[ "$FILTER" == *"/"* ]]; then
        XCODEBUILD_CMD="$XCODEBUILD_CMD -only-testing:$FILTER"
    # If filter contains a dot, convert TestSuite.testMethod to unit-tests/TestSuite/testMethod
    elif [[ "$FILTER" == *"."* ]]; then
        TEST_SUITE=$(echo "$FILTER" | cut -d'.' -f1)
        TEST_METHOD=$(echo "$FILTER" | cut -d'.' -f2)
        XCODEBUILD_CMD="$XCODEBUILD_CMD -only-testing:unit-tests/$TEST_SUITE/$TEST_METHOD"
    # Otherwise, assume it's just a test suite name and add the target
    else
        XCODEBUILD_CMD="$XCODEBUILD_CMD -only-testing:unit-tests/$FILTER"
    fi
fi

# Run the tests with xcpretty for clean output (incremental - skips rebuild if possible)
eval $XCODEBUILD_CMD 2>&1 | tee $TEMP_OUTPUT | xcpretty

# Check the exit status
TEST_STATUS=$?

# Parse the "Executed X test(s), with Y failure(s)" line
EXECUTED_LINE=$(grep "Executed.*test.*with.*failure" $TEMP_OUTPUT | tail -1)
if [[ -n "$EXECUTED_LINE" ]]; then
    TOTAL_TESTS=$(echo "$EXECUTED_LINE" | sed -n 's/.*Executed \([0-9][0-9]*\) test.*/\1/p')
    FAILED_TESTS=$(echo "$EXECUTED_LINE" | sed -n 's/.*with \([0-9][0-9]*\) failure.*/\1/p')

    # Ensure we have valid numbers
    if [[ -z "$TOTAL_TESTS" ]]; then TOTAL_TESTS=0; fi
    if [[ -z "$FAILED_TESTS" ]]; then FAILED_TESTS=0; fi

    PASSED_TESTS=$(($TOTAL_TESTS - $FAILED_TESTS))
else
    TOTAL_TESTS=0
    FAILED_TESTS=0
    PASSED_TESTS=0
fi

# Show test results
if [ "$FAILED_TESTS" -eq 0 ] && [ "$TOTAL_TESTS" -gt 0 ]; then
    echo "✅ All tests passed! ($TOTAL_TESTS tests)"
    FINAL_STATUS=0
elif [ "$FAILED_TESTS" -gt 0 ]; then
    echo "❌ Tests failed: $FAILED_TESTS failed, $PASSED_TESTS passed ($TOTAL_TESTS total)"
    FINAL_STATUS=1
else
    echo "⚠️  No test results found"
    FINAL_STATUS=$TEST_STATUS
fi

# Remove the temporary file
rm $TEMP_OUTPUT

exit $FINAL_STATUS