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

# Check simulator
SIMULATOR_UUID_FILE="$INTEGRATION_ROOT/config/simulator-uuid.txt"
if [[ -f "$SIMULATOR_UUID_FILE" ]]; then
    SIMULATOR_UUID=$(cat "$SIMULATOR_UUID_FILE")
    echo_info "Using simulator: $SIMULATOR_UUID"
else
    echo_error "No simulator configured. Run setup-local-environment.sh first"
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

# Navigate to sample app
SAMPLE_APP_PATH="$PROJECT_ROOT/sample-apps/swift-sample-app"
cd "$SAMPLE_APP_PATH"

echo_info "Sample app location: $SAMPLE_APP_PATH"

# Clean build folder
echo_info "Cleaning build..."
xcodebuild clean -project swift-sample-app.xcodeproj -scheme swift-sample-app -sdk iphonesimulator

# Create integration test helpers
echo_info "Creating integration test helpers..."
create_integration_helpers() {
    cat > swift-sample-app/IntegrationTestHelper.swift << 'EOF'
import Foundation
import UIKit

class IntegrationTestHelper {
    static let shared = IntegrationTestHelper()
    
    private var isInTestMode = false
    
    private init() {}
    
    func enableTestMode() {
        isInTestMode = true
        print("🧪 Integration test mode enabled")
    }
    
    func isInTestMode() -> Bool {
        return isInTestMode || ProcessInfo.processInfo.environment["INTEGRATION_TEST_MODE"] == "1"
    }
    
    func setupIntegrationTestMode() {
        if isInTestMode() {
            print("🧪 Setting up integration test mode")
            // Configure app for testing
        }
    }
}

// Integration test enhanced functions
func enhancedApplicationDidFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    print("🧪 Enhanced app did finish launching")
    if IntegrationTestHelper.shared.isInTestMode() {
        IntegrationTestHelper.shared.setupIntegrationTestMode()
    }
}

func enhancedApplicationDidBecomeActive(_ application: UIApplication) {
    print("🧪 Enhanced app did become active")
}

func enhancedDidReceiveRemoteNotification(_ application: UIApplication, userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("🧪 Enhanced received remote notification: \(userInfo)")
    fetchCompletionHandler(.newData)
}

func enhancedContinueUserActivity(_ application: UIApplication, userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    print("🧪 Enhanced continue user activity: \(userActivity)")
    return true
}

func enhancedDidRegisterForRemoteNotifications(_ application: UIApplication, deviceToken: Data) {
    print("🧪 Enhanced registered for remote notifications")
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("🧪 Device token: \(tokenString)")
}

func setupIntegrationTestMode() {
    IntegrationTestHelper.shared.setupIntegrationTestMode()
}
EOF
}

create_integration_helpers

# Build the app
echo_header "Building Sample App"

BUILD_LOG="$INTEGRATION_ROOT/logs/build-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$INTEGRATION_ROOT/logs"

echo_info "Building for simulator: $SIMULATOR_UUID"
echo_info "Build log: $BUILD_LOG"

if xcodebuild build \
    -project swift-sample-app.xcodeproj \
    -scheme swift-sample-app \
    -sdk iphonesimulator \
    -destination "id=$SIMULATOR_UUID" \
    -configuration Debug \
    > "$BUILD_LOG" 2>&1; then
    
    echo_success "Build successful!"
    
    # Install and run the app
    echo_header "Installing and Running App"
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "swift-sample-app.app" -path "*/Debug-iphonesimulator/*" | head -1)
    
    if [[ -n "$APP_PATH" ]]; then
        echo_info "Installing app: $APP_PATH"
        xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"
        
        echo_info "Launching app..."
        xcrun simctl launch "$SIMULATOR_UUID" com.iterable.swift-sample-app
        
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