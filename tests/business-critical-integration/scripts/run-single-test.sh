#!/bin/bash

# Simple script to run a single integration test locally
TEST_TYPE="$1"
CONFIG_FILE="$(dirname "$0")/../integration-test-app/config/test-config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Local config not found. Run setup-local-environment.sh first."
    exit 1
fi

echo "🧪 Running $TEST_TYPE integration test locally..."

# Extract simulator UUID
SIMULATOR_UUID=$(cat "$(dirname "$0")/../integration-test-app/config/simulator-uuid.txt" 2>/dev/null || echo "")

if [[ -z "$SIMULATOR_UUID" ]]; then
    echo "❌ Simulator UUID not found. Run setup-local-environment.sh first."
    exit 1
fi

# Boot simulator if needed
xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || true

echo "✅ Test setup complete. Simulator: $SIMULATOR_UUID"
echo "📝 Next: Implement actual test execution for $TEST_TYPE"
