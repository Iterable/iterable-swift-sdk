#!/bin/bash

set -e

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_error() { echo -e "${RED}❌ $1${NC}"; }
echo_success() { echo -e "${GREEN}✅ $1${NC}"; }
echo_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
echo_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
echo_header() { echo -e "${BLUE}============================================\n$1\n============================================${NC}"; }

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INTEGRATION_ROOT="$SCRIPT_DIR/.."

echo_header "Build and Run Integration Test App"

# Check simulator from JSON config
CONFIG_FILE="$INTEGRATION_ROOT/integration-test-app/config/test-config.json"
if [[ -f "$CONFIG_FILE" ]] && command -v jq &> /dev/null; then
    SIMULATOR_UUID=$(jq -r '.simulator.simulatorUuid' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -n "$SIMULATOR_UUID" && "$SIMULATOR_UUID" != "null" ]]; then
        echo_info "Using simulator from JSON config: $SIMULATOR_UUID"
    else
        echo_warning "No simulator UUID in JSON config, looking for 'Integration-Test-iPhone' simulator..."
        SIMULATOR_UUID=$(xcrun simctl list devices | grep "Integration-Test-iPhone" | head -1 | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')
        
        if [[ -n "$SIMULATOR_UUID" ]]; then
            echo_success "Found Integration-Test-iPhone simulator: $SIMULATOR_UUID"
            # Update JSON config with simulator UUID
            jq --arg uuid "$SIMULATOR_UUID" '.simulator.simulatorUuid = $uuid' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
            echo_info "Updated JSON config with simulator UUID"
        else
            echo_error "No Integration-Test-iPhone simulator found. Available simulators:"
            xcrun simctl list devices | grep iPhone | head -5
            echo_info "Create one with: xcrun simctl create 'Integration-Test-iPhone' com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro com.apple.CoreSimulator.SimRuntime.iOS-18-1"
            exit 1
        fi
    fi
else
    echo_error "JSON config file not found or jq not available"
    exit 1
fi

# Check if simulator is running
if ! xcrun simctl list devices | grep "$SIMULATOR_UUID" | grep -q "Booted"; then
    echo_info "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UUID"
    sleep 5
fi

# Open simulator visually
echo_info "Opening iOS Simulator..."
open -a Simulator

# Navigate to integration test app
INTEGRATION_APP_PATH="$INTEGRATION_ROOT/integration-test-app"
cd "$INTEGRATION_APP_PATH"

echo_info "Integration test app location: $INTEGRATION_APP_PATH"

# Clean build folder
echo_info "Cleaning build..."
xcodebuild clean -project IterableSDK-Integration-Tester.xcodeproj -scheme IterableSDK-Integration-Tester -sdk iphonesimulator

# Integration test app has all helpers built-in
echo_info "Using built-in integration test setup..."

# Build the app
echo_header "Building Integration Test App"

BUILD_LOG="$INTEGRATION_ROOT/logs/build-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$INTEGRATION_ROOT/logs"

echo_info "Building for simulator: $SIMULATOR_UUID"
echo_info "Build log: $BUILD_LOG"

if xcodebuild build \
    -project IterableSDK-Integration-Tester.xcodeproj \
    -scheme IterableSDK-Integration-Tester \
    -sdk iphonesimulator \
    -destination "id=$SIMULATOR_UUID" \
    -configuration Debug \
    > "$BUILD_LOG" 2>&1; then
    
    echo_success "Build successful!"
    
    # Install and run the app
    echo_header "Installing and Running App"
    
    # Find the built app using xcodebuild -showBuildSettings
    BUILD_DIR=$(xcodebuild -project IterableSDK-Integration-Tester.xcodeproj -scheme IterableSDK-Integration-Tester -configuration Debug -sdk iphonesimulator -showBuildSettings | grep "BUILT_PRODUCTS_DIR" | head -1 | cut -d'=' -f2 | xargs)
    APP_PATH="$BUILD_DIR/IterableSDK-Integration-Tester.app"
    
    if [[ -n "$APP_PATH" ]]; then
        echo_info "Installing app: $APP_PATH"
        xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"
        
        echo_info "Launching app..."
        xcrun simctl launch "$SIMULATOR_UUID" com.sumeru.IterableSDK-Integration-Tester
        
        echo_success "App launched successfully!"
        echo_info "You should now see the app running in the iOS Simulator"
        
        # Show some helpful commands
        echo_header "Next Steps"
        echo_info "The app is now running in the simulator"
        echo_info "You can interact with it manually or run automated tests"
        echo_info ""
        echo_info "Useful commands:"
        echo_info "• Send a test push notification"
        echo_info "• Test notification permissions"
        echo_info "• Validate device token registration"
        
    else
        echo_error "Could not find built app"
        exit 1
    fi
    
else
    echo_error "Build failed!"
    echo_warning "Check the build log for details: $BUILD_LOG"
    echo_header "Build Errors"
    
    # Show specific build errors
    grep -A 2 -B 2 "error:" "$BUILD_LOG" | head -20
    
    exit 1
fi

echo_header "Build and Run Complete 🎉"
echo_success "Integration test app is running in iOS Simulator" 