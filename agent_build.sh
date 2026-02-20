#!/bin/bash

# This script is to be used by LLMs and AI agents to build the Iterable Swift SDK on macOS.
# It uses xcpretty to format the build output and only shows errors.
# It also checks if the build is successful and exits with the correct status.

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script requires macOS to run Xcode builds"
    exit 1
fi

# Make sure xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "xcpretty not found, installing via gem..."
    sudo gem install xcpretty
fi

echo "Building Iterable Swift SDK..."

# Create a temporary file for the build output
TEMP_OUTPUT=$(mktemp)

# Run the build and capture all output
xcodebuild \
    -project swift-sdk.xcodeproj \
    -scheme "swift-sdk" \
    -configuration Debug \
    -sdk iphonesimulator \
    build > $TEMP_OUTPUT 2>&1

# Check the exit status
BUILD_STATUS=$?

# Show errors and warnings if build failed
if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Iterable SDK build succeeded!"
else
    echo "❌ Iterable SDK build failed with status $BUILD_STATUS"
    echo ""
    echo "🔍 Build errors:"
    grep -E 'error:|fatal:' $TEMP_OUTPUT | head -10
    echo ""
    echo "⚠️  Build warnings:"
    grep -E 'warning:' $TEMP_OUTPUT | head -5
fi

# Remove the temporary file
rm $TEMP_OUTPUT

exit $BUILD_STATUS