#!/bin/bash

# Validate local environment setup
CONFIG_FILE="$(dirname "$0")/../integration-test-app/config/test-config.json"
SIMULATOR_FILE="$(dirname "$0")/../integration-test-app/config/simulator-uuid.txt"

echo "🔍 Validating local environment setup..."

# Check config file
if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ Configuration file exists"
    if command -v jq &> /dev/null; then
        API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
        if [[ "$API_KEY" != "null" && -n "$API_KEY" ]]; then
            echo "✅ API key configured"
        else
            echo "❌ API key not configured"
        fi
    fi
else
    echo "❌ Configuration file missing"
fi

# Check simulator
if [[ -f "$SIMULATOR_FILE" ]]; then
    SIMULATOR_UUID=$(cat "$SIMULATOR_FILE")
    if xcrun simctl list devices | grep -q "$SIMULATOR_UUID"; then
        echo "✅ Test simulator exists: $SIMULATOR_UUID"
    else
        echo "❌ Test simulator not found"
    fi
else
    echo "❌ Simulator configuration missing"
fi

# Check Xcode
if command -v xcodebuild &> /dev/null; then
    echo "✅ Xcode available"
else
    echo "❌ Xcode not found"
fi

echo "🎯 Local environment validation complete"
