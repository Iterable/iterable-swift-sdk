#!/bin/bash

# Simple script to run a single integration test locally
TEST_TYPE="$1"
CONFIG_FILE="$(dirname "$0")/../config/test-config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Local config not found. Run setup-local-environment.sh first."
    exit 1
fi

echo "🧪 Running $TEST_TYPE integration test locally..."

# Extract simulator UUID
SIMULATOR_UUID=$(cat "$(dirname "$0")/../config/simulator-uuid.txt" 2>/dev/null || echo "")

if [[ -z "$SIMULATOR_UUID" ]]; then
    echo "❌ Simulator UUID not found. Run setup-local-environment.sh first."
    exit 1
fi

# Boot simulator if needed
xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || true

echo "✅ Test setup complete. Simulator: $SIMULATOR_UUID"

# Show available test types
show_help() {
    echo ""
    echo "🧪 Available Integration Tests:"
    echo ""
    echo "  push          - Push notification tests (device registration, delivery, tracking)"
    echo "  inapp         - In-app message tests (display, interaction, metrics)"  
    echo "  embedded      - Embedded message tests (eligibility, placement, metrics)"
    echo "  deeplink      - Deep linking tests (universal links, attribution)"
    echo "  all           - Run all integration tests"
    echo ""
    echo "Usage: $0 <test_type>"
    echo "Example: $0 push"
    echo ""
}

# Map test types to actual test class names
case "$TEST_TYPE" in
    "push")
        TEST_CLASS="PushNotificationIntegrationTests"
        echo "🚀 Running push notification integration tests..."
        ;;
    "inapp")
        TEST_CLASS="InAppMessageIntegrationTests"
        echo "🚀 Running in-app message integration tests..."
        ;;
    "embedded")
        TEST_CLASS="EmbeddedMessageIntegrationTests"
        echo "🚀 Running embedded message integration tests..."
        ;;
    "deeplink")
        TEST_CLASS="DeepLinkingIntegrationTests"
        echo "🚀 Running deep linking integration tests..."
        ;;
    "all")
        TEST_CLASS="all"
        echo "🚀 Running all integration tests..."
        ;;
    "help"|"-h"|"--help"|"")
        show_help
        exit 0
        ;;
    *)
        echo "❌ Unknown test type: $TEST_TYPE"
        show_help
        exit 1
        ;;
esac

# Navigate to integration test app directory
cd "$(dirname "$0")/../integration-test-app"

# Ensure the app is built and installed first
echo "📱 Building and installing app on simulator..."
xcodebuild build \
    -project IterableSDK-Integration-Tester.xcodeproj \
    -scheme IterableSDK-Integration-Tester \
    -destination "id=$SIMULATOR_UUID" \
    -configuration Debug \
    > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Failed to build app"
    exit 1
fi

echo "📲 Installing app on simulator..."
BUILD_DIR=$(xcodebuild -project IterableSDK-Integration-Tester.xcodeproj -scheme IterableSDK-Integration-Tester -configuration Debug -sdk iphonesimulator -showBuildSettings | grep "BUILT_PRODUCTS_DIR" | head -1 | cut -d'=' -f2 | xargs)
APP_PATH="$BUILD_DIR/IterableSDK-Integration-Tester.app"

xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH" > /dev/null 2>&1

# Check if xcpretty is available
if ! command -v xcpretty &> /dev/null; then
    echo "📦 xcpretty not found, installing via gem..."
    sudo gem install xcpretty
fi

# Run the actual tests using xcodebuild test with xcpretty
echo "🧪 Executing tests on simulator $SIMULATOR_UUID..."

# Create temporary files for raw and pretty output
RAW_OUTPUT=$(mktemp)
PRETTY_OUTPUT=$(mktemp)

if [ "$TEST_CLASS" = "all" ]; then
    # Run all tests without filter
    xcodebuild test \
        -project IterableSDK-Integration-Tester.xcodeproj \
        -scheme IterableSDK-Integration-Tester \
        -destination "id=$SIMULATOR_UUID" \
        > "$RAW_OUTPUT" 2>&1
else
    # Run specific test class
    xcodebuild test \
        -project IterableSDK-Integration-Tester.xcodeproj \
        -scheme IterableSDK-Integration-Tester \
        -destination "id=$SIMULATOR_UUID" \
        -only-testing "IterableSDK-Integration-TesterTests/$TEST_CLASS" \
        > "$RAW_OUTPUT" 2>&1
fi

TEST_EXIT_CODE=$?

# Process output with xcpretty and save both versions
cat "$RAW_OUTPUT" | xcpretty --color | tee "$PRETTY_OUTPUT"

# Save the raw output to logs
mkdir -p "../logs"
cp "$RAW_OUTPUT" "../logs/test-${TEST_TYPE}-$(date +%Y%m%d-%H%M%S)-raw.log"
cp "$PRETTY_OUTPUT" "../logs/test-${TEST_TYPE}-$(date +%Y%m%d-%H%M%S)-pretty.log"

# Clean up temp files
rm "$RAW_OUTPUT" "$PRETTY_OUTPUT"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ $TEST_TYPE tests completed successfully!"
else
    echo "❌ $TEST_TYPE tests failed with exit code $TEST_EXIT_CODE"
    exit $TEST_EXIT_CODE
fi
