#!/bin/bash

# This script builds the Iterable SDK Integration Tester app on macOS.
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

echo "Building Iterable SDK Integration Tester app and tests..."

# Check if clean build is requested
CLEAN_BUILD=false
if [[ "$1" == "--clean" || "$CI" == "1" ]]; then
    CLEAN_BUILD=true
    echo "🧹 Clean build requested - will clean before building"
fi

# Navigate to the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "🔍 Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR/integration-test-app"
echo "🔍 Current directory: $(pwd)"
echo "🔍 Contents of current directory:"
ls -la
echo "🔍 Looking for .xcodeproj files:"
find . -name "*.xcodeproj" -type d
echo "🔍 Checking if target project exists:"
if [[ -d "IterableSDK-Integration-Tester.xcodeproj" ]]; then
    echo "✅ Project file found: IterableSDK-Integration-Tester.xcodeproj"
    echo "🔍 Project file details:"
    ls -la "IterableSDK-Integration-Tester.xcodeproj"
else
    echo "❌ Project file NOT found: IterableSDK-Integration-Tester.xcodeproj"
    echo "Available items in current directory:"
    ls -la
    echo "🔍 All .xcodeproj directories in current path:"
    find . -maxdepth 2 -name "*.xcodeproj" -type d
    exit 1
fi

# Get simulator UUID from config
CONFIG_FILE="$PROJECT_DIR/integration-test-app/config/test-config.json"
SIMULATOR_UUID=""

if [[ -f "$CONFIG_FILE" ]] && command -v jq &> /dev/null; then
    SIMULATOR_UUID=$(jq -r '.simulator.simulatorUuid' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -n "$SIMULATOR_UUID" && "$SIMULATOR_UUID" != "null" ]]; then
        echo "🎯 Using simulator from config: $SIMULATOR_UUID"
    else
        echo "⚠️  No simulator UUID found in config, will use generic destination"
        SIMULATOR_UUID=""
    fi
fi

# Build destination parameter
if [[ -n "$SIMULATOR_UUID" ]]; then
    DESTINATION=(-destination "id=$SIMULATOR_UUID")
else
    # Fallback to generic iPhone simulator destination
    DESTINATION=(-destination "platform=iOS Simulator,name=iPhone 16 Pro")
fi

# Create temporary files for build outputs
MAIN_OUTPUT=$(mktemp)
TEST_OUTPUT=$(mktemp)

if [[ "$CLEAN_BUILD" == true ]]; then
    echo "🧹 Cleaning build directory..."
    xcodebuild \
        -project IterableSDK-Integration-Tester.xcodeproj \
        -scheme "IterableSDK-Integration-Tester" \
        -configuration Debug \
        -sdk iphonesimulator \
        "${DESTINATION[@]}" \
        clean > /dev/null 2>&1
    echo "✅ Clean completed"
fi

echo "📱 Building main app target..."

# Build the main app target first
xcodebuild \
    -project IterableSDK-Integration-Tester.xcodeproj \
    -scheme "IterableSDK-Integration-Tester" \
    -configuration Debug \
    -sdk iphonesimulator \
    "${DESTINATION[@]}" \
    build > $MAIN_OUTPUT 2>&1

MAIN_BUILD_STATUS=$?

if [ $MAIN_BUILD_STATUS -eq 0 ]; then
    echo "✅ Main app build succeeded!"
    
    echo "🧪 Building test target..."
    
    # Build the test target
    xcodebuild \
        -project IterableSDK-Integration-Tester.xcodeproj \
        -scheme "IterableSDK-Integration-Tester" \
        -configuration Debug \
        -sdk iphonesimulator \
        "${DESTINATION[@]}" \
        build-for-testing > $TEST_OUTPUT 2>&1
    
    TEST_BUILD_STATUS=$?
    
    if [ $TEST_BUILD_STATUS -eq 0 ]; then
        echo "✅ Test target build succeeded!"
        echo "🎉 All builds completed successfully!"
        BUILD_STATUS=0
    else
        echo "❌ Test target build failed with status $TEST_BUILD_STATUS"
        echo ""
        echo "🔍 Test build errors:"
        grep -E 'error:|fatal:' $TEST_OUTPUT | head -10
        echo ""
        echo "⚠️  Test build warnings:"
        grep -E 'warning:' $TEST_OUTPUT | head -5
        BUILD_STATUS=$TEST_BUILD_STATUS
    fi
else
    echo "❌ Main app build failed with status $MAIN_BUILD_STATUS"
    echo ""
    echo "🔍 Main app build errors:"
    grep -E 'error:|fatal:' $MAIN_OUTPUT | head -10
    echo ""
    echo "⚠️  Main app build warnings:"
    grep -E 'warning:' $MAIN_OUTPUT | head -5
    BUILD_STATUS=$MAIN_BUILD_STATUS
fi

# Remove the temporary files
rm $MAIN_OUTPUT $TEST_OUTPUT

exit $BUILD_STATUS 