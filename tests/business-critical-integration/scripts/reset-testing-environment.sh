#!/bin/bash

# Business Critical Integration Tests - Reset Testing Environment
# This script resets the testing environment by:
# 1. Clearing simulator data (UUID from config file)
# 2. Optionally disabling registered devices from Iterable backend
#
# Usage: ./reset-testing-environment.sh [--disable-devices] [--no-confirm]
#   --disable-devices: Also disable all registered devices in Iterable backend
#   --no-confirm: Skip confirmation prompt (for automated usage)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../integration-test-app/config"
LOCAL_CONFIG_FILE="$CONFIG_DIR/test-config.json"

# Parse command line arguments
DISABLE_DEVICES=false
NO_CONFIRM=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --disable-devices)
            DISABLE_DEVICES=true
            shift
            ;;
        --no-confirm)
            NO_CONFIRM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--disable-devices] [--no-confirm]"
            echo "  --disable-devices  Also disable all registered devices in Iterable backend"
            echo "  --no-confirm       Skip confirmation prompt (for automated usage)"
            exit 0
            ;;
        *)
            echo_error "Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_dependencies() {
    echo_header "Checking Dependencies"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo_error "jq is required but not installed. Please install it first:"
        echo_info "  brew install jq"
        exit 1
    fi
    echo_success "jq is installed"
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo_error "curl is required but not available"
        exit 1
    fi
    echo_success "curl is available"
    
    # Check if xcrun is available (for simulator management)
    if ! command -v xcrun &> /dev/null; then
        echo_error "xcrun is required but not available. Make sure Xcode is installed."
        exit 1
    fi
    echo_success "xcrun is available"
}

load_configuration() {
    echo_header "Loading Configuration"
    
    if [[ ! -f "$LOCAL_CONFIG_FILE" ]]; then
        echo_error "Configuration file not found: $LOCAL_CONFIG_FILE"
        echo_info "Please run setup-local-environment.sh first"
        exit 1
    fi
    
    # Extract configuration values
    TEST_USER_EMAIL=$(jq -r '.testUserEmail' "$LOCAL_CONFIG_FILE")
    SERVER_KEY=$(jq -r '.serverApiKey' "$LOCAL_CONFIG_FILE")
    MOBILE_KEY=$(jq -r '.mobileApiKey' "$LOCAL_CONFIG_FILE")
    PROJECT_ID=$(jq -r '.projectId' "$LOCAL_CONFIG_FILE")
    SIMULATOR_UUID=$(jq -r '.simulator.simulatorUuid' "$LOCAL_CONFIG_FILE")
    
    # Validate configuration
    if [[ "$TEST_USER_EMAIL" == "null" || -z "$TEST_USER_EMAIL" ]]; then
        echo_error "testUserEmail not found in configuration"
        exit 1
    fi
    
    if [[ "$SERVER_KEY" == "null" || -z "$SERVER_KEY" ]]; then
        echo_error "serverApiKey not found in configuration"
        exit 1
    fi
    
    if [[ "$PROJECT_ID" == "null" || -z "$PROJECT_ID" ]]; then
        echo_error "projectId not found in configuration"
        exit 1
    fi
    
    if [[ "$DISABLE_DEVICES" == true ]]; then
        if [[ "$MOBILE_KEY" == "null" || -z "$MOBILE_KEY" ]]; then
            echo_error "mobileApiKey not found in configuration (required for --disable-devices)"
            exit 1
        fi
        echo_info "Using Mobile API Key for device operations"
    fi
    
    echo_success "Configuration loaded successfully"
    echo_info "Test User: $TEST_USER_EMAIL"
    echo_info "Project ID: $PROJECT_ID"
    if [[ "$DISABLE_DEVICES" == true ]]; then
        echo_info "Device disabling: ENABLED"
    else
        echo_info "Device disabling: DISABLED (use --disable-devices to enable)"
    fi
}

get_user_devices() {
    if [[ "$DISABLE_DEVICES" != true ]]; then
        echo_info "Skipping device fetch (--disable-devices not specified)"
        return 0
    fi
    
    echo_header "Fetching User Devices from Iterable"
    
    # URL encode the email
    ENCODED_EMAIL=$(printf %s "$TEST_USER_EMAIL" | jq -sRr @uri)
    
    echo_info "Fetching device information for: $TEST_USER_EMAIL"
    
    # Get user details from Iterable API
    USER_RESPONSE=$(curl -s -X GET "https://api.iterable.com/api/users/$ENCODED_EMAIL" \
        -H "Api-Key: $SERVER_KEY" \
        -H "Content-Type: application/json")
    
    # Check if the request was successful
    if ! echo "$USER_RESPONSE" | jq -e '.user' > /dev/null 2>&1; then
        echo_warning "User not found or no devices registered"
        echo_info "API Response: $USER_RESPONSE"
        return 0
    fi
    
    # Extract device tokens
    DEVICE_TOKENS=$(echo "$USER_RESPONSE" | jq -r '.user.dataFields.devices[]?.token // empty' 2>/dev/null)
    
    if [[ -z "$DEVICE_TOKENS" ]]; then
        echo_info "No devices found for user"
        return 0
    fi
    
    # Count devices
    DEVICE_COUNT=$(echo "$DEVICE_TOKENS" | wc -l | tr -d ' ')
    echo_success "Found $DEVICE_COUNT device(s) registered"
    
    # Display device information
    echo_info "Device details:"
    echo "$USER_RESPONSE" | jq -r '.user.dataFields.devices[]? | "  - Platform: \(.platform // "Unknown"), Token: \(.token[0:16])..., Enabled: \(.endpointEnabled // false)"' 2>/dev/null || echo_info "  Could not parse device details"
    
    return 0
}

disable_user_devices() {
    if [[ "$DISABLE_DEVICES" != true ]]; then
        echo_info "Skipping device disable (--disable-devices not specified)"
        return 0
    fi
    
    echo_header "Disabling User Devices"
    
    if [[ -z "$DEVICE_TOKENS" ]]; then
        echo_info "No devices to disable"
        return 0
    fi
    
    DISABLED_COUNT=0
    FAILED_COUNT=0
    
    while IFS= read -r token; do
        if [[ -n "$token" ]]; then
            echo_info "Disabling device: ${token:0:16}..."
            
            DISABLE_RESPONSE=$(curl -s -X POST "https://api.iterable.com/api/users/disableDevice" \
                -H "Api-Key: $MOBILE_KEY" \
                -H "Content-Type: application/json" \
                -d "{
                    \"email\": \"$TEST_USER_EMAIL\",
                    \"token\": \"$token\"
                }")
            
            # Check if the disable request was successful
            if echo "$DISABLE_RESPONSE" | jq -e '.code == "Success"' > /dev/null 2>&1; then
                echo_success "Device disabled successfully"
                ((DISABLED_COUNT++))
            else
                echo_warning "Failed to disable device: $DISABLE_RESPONSE"
                ((FAILED_COUNT++))
            fi
        fi
    done <<< "$DEVICE_TOKENS"
    
    echo_success "Devices disabled: $DISABLED_COUNT"
    if [[ $FAILED_COUNT -gt 0 ]]; then
        echo_warning "Failed to disable: $FAILED_COUNT devices"
    fi
}

reset_simulator_data() {
    echo_header "Resetting Simulator Data"
    
    if [[ "$SIMULATOR_UUID" == "null" || -z "$SIMULATOR_UUID" ]]; then
        echo_warning "No simulator UUID configured, skipping simulator reset"
        return 0
    fi
    
    echo_info "Using simulator: $SIMULATOR_UUID"
    
    # Check if simulator exists
    if ! xcrun simctl list devices | grep -q "$SIMULATOR_UUID"; then
        echo_warning "Simulator $SIMULATOR_UUID not found, skipping simulator reset"
        return 0
    fi
    
    # Shutdown simulator if running
    echo_info "Shutting down simulator..."
    xcrun simctl shutdown "$SIMULATOR_UUID" 2>/dev/null || true
    
    # Reset simulator data
    echo_info "Erasing simulator data..."
    if xcrun simctl erase "$SIMULATOR_UUID"; then
        echo_success "Simulator data erased successfully"
    else
        echo_warning "Failed to erase simulator data"
    fi
}



verify_reset() {
    echo_header "Verifying Reset"
    
    echo_success "Simulator reset completed"
    
    if [[ "$DISABLE_DEVICES" == true ]]; then
        echo_info "Waiting for API changes to propagate..."
        sleep 3
        
        # Check if devices are still registered
        ENCODED_EMAIL=$(printf %s "$TEST_USER_EMAIL" | jq -sRr @uri)
        VERIFICATION_RESPONSE=$(curl -s -X GET "https://api.iterable.com/api/users/$ENCODED_EMAIL" \
            -H "Api-Key: $SERVER_KEY" \
            -H "Content-Type: application/json")
        
        if echo "$VERIFICATION_RESPONSE" | jq -e '.user.dataFields.devices[]?' > /dev/null 2>&1; then
            REMAINING_DEVICES=$(echo "$VERIFICATION_RESPONSE" | jq '[.user.dataFields.devices[]? | select(.endpointEnabled == true)] | length' 2>/dev/null || echo "0")
            if [[ "$REMAINING_DEVICES" -gt 0 ]]; then
                echo_warning "$REMAINING_DEVICES active device(s) still found - they may take time to be fully disabled"
            else
                echo_success "No active devices found - device reset successful"
            fi
        else
            echo_success "No devices found - device reset successful"
        fi
    else
        echo_info "Device verification skipped (--disable-devices not specified)"
    fi
}

main() {
    echo_header "Reset Testing Environment"
    echo_info "This script will reset the testing environment by:"
    echo_info "  1. Clearing simulator data (UUID from config file)"
    if [[ "$DISABLE_DEVICES" == true ]]; then
        echo_info "  2. Disabling all registered devices for integration test user"
        echo_info "  3. Ensuring clean state for testing"
    else
        echo_info "  2. Keeping backend devices intact (use --disable-devices to disable them)"
    fi
    echo ""
    
    # Ask for confirmation unless --no-confirm is specified
    if [[ "$NO_CONFIRM" != true ]]; then
        read -p "Are you sure you want to reset the testing environment? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Reset cancelled"
            exit 0
        fi
    else
        echo_info "Skipping confirmation (--no-confirm specified)"
    fi
    
    # Execute reset steps
    check_dependencies
    load_configuration
    get_user_devices
    disable_user_devices
    reset_simulator_data
    verify_reset
    
    echo_header "Reset Complete"
    echo_success "Testing environment has been reset successfully!"
    echo_success "✅ Simulator cleared of all data"
    if [[ "$DISABLE_DEVICES" == true ]]; then
        echo_success "✅ Integration test user devices disabled"
    else
        echo_info "ℹ️  Backend devices kept intact (use --disable-devices to disable them)"
    fi
    echo ""
    echo_info "Next steps:"
    echo_info "  1. Run: ./build-and-run.sh to install and test the app"
    if [[ "$DISABLE_DEVICES" == true ]]; then
        echo_info "  2. Device will register automatically when app launches"
    else
        echo_info "  2. App will connect to existing device registration (if any)"
    fi
}

# Execute main function
main "$@"
