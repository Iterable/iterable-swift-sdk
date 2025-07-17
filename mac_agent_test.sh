#!/bin/bash

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script requires macOS to run Xcode tests"
    exit 1
fi

# Make sure xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "xcpretty not found, installing via gem..."
    sudo gem install xcpretty
fi

echo "Running Iterable Swift SDK unit tests..."

# Create a temporary file for the test output
TEMP_OUTPUT=$(mktemp)

# Run the tests and capture all output
xcodebuild test \
    -project swift-sdk.xcodeproj \
    -scheme swift-sdk \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
    -enableCodeCoverage YES \
    CODE_SIGNING_REQUIRED=NO > $TEMP_OUTPUT 2>&1

# Check the exit status
TEST_STATUS=$?

# Show test results
if [ $TEST_STATUS -eq 0 ]; then
    echo "✅ All tests passed!"
    echo ""
    echo "📊 Test Summary:"
    grep -E 'Test Suite|tests passed|tests failed|Executed' $TEMP_OUTPUT | tail -10
else
    echo "❌ Tests failed with status $TEST_STATUS"
    echo ""
    echo "🔍 Test failures:"
    grep -E 'error:|failed:|FAILED' $TEMP_OUTPUT | head -10
    echo ""
    echo "📊 Test Summary:"
    grep -E 'Test Suite|tests passed|tests failed|Executed' $TEMP_OUTPUT | tail -5
fi

# Remove the temporary file
rm $TEMP_OUTPUT

exit $TEST_STATUS 