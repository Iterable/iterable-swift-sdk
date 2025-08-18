#!/bin/bash

# Validate local environment setup
CONFIG_FILE="$(dirname "$0")/../integration-test-app/config/test-config.json"

echo "🔍 Validating local environment setup..."

# Check config file
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ Configuration file exists"
    if command -v jq &> /dev/null; then
        API_KEY=$(jq -r '.mobileApiKey' "$CONFIG_FILE")
        if [[ "$API_KEY" != "null" && -n "$API_KEY" ]]; then
            echo "✅ API key configured"
        else
            echo "❌ API key not configured"
        fi
        
        # Check simulator UUID from JSON
        SIMULATOR_UUID=$(jq -r '.simulator.simulatorUuid' "$CONFIG_FILE")
        if [[ "$SIMULATOR_UUID" != "null" && -n "$SIMULATOR_UUID" ]]; then
            if xcrun simctl list devices | grep -q "$SIMULATOR_UUID"; then
                echo "✅ Test simulator exists: $SIMULATOR_UUID"
            else
                echo "❌ Test simulator not found: $SIMULATOR_UUID"
            fi
        else
            echo "❌ Simulator UUID not configured in JSON"
        fi
    else
        echo "❌ jq command not found - cannot validate JSON config"
    fi
else
    echo "❌ Configuration file missing"
fi

# Check Xcode
if command -v xcodebuild &> /dev/null; then
    echo "✅ Xcode available"
else
    echo "❌ Xcode not found"
fi

# Check Xcode project
PROJECT_DIR="$(dirname "$0")/../integration-test-app"
PROJECT_FILE="$PROJECT_DIR/IterableSDK-Integration-Tester.xcodeproj"
FULL_PROJECT_PATH="$(cd "$PROJECT_DIR" && pwd)/IterableSDK-Integration-Tester.xcodeproj"

if [[ -d "$PROJECT_FILE" ]]; then
    echo "✅ Xcode project exists"
    echo "📁 Project path: $FULL_PROJECT_PATH"
    
    # Try to load the project and list targets
    echo "🔍 Validating Xcode project can be loaded..."
    cd "$PROJECT_DIR"
    
    if xcodebuild -list -project IterableSDK-Integration-Tester.xcodeproj &> /dev/null; then
        echo "✅ Xcode project loads successfully"
        
        # Show available targets and schemes
        echo "📋 Available targets and schemes:"
        xcodebuild -list -project IterableSDK-Integration-Tester.xcodeproj
    else
        echo "❌ Xcode project failed to load"
        echo "🔍 Project location: $FULL_PROJECT_PATH"
        echo "🔍 Directory contents:"
        ls -la "$PROJECT_DIR/"
    fi
else
    echo "❌ Xcode project not found"
    echo "🔍 Expected location: $FULL_PROJECT_PATH"
    echo "🔍 Directory contents:"
    ls -la "$PROJECT_DIR/" 2>/dev/null || echo "Directory does not exist"
fi

echo "🎯 Local environment validation complete"
