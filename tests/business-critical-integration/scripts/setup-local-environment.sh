#!/bin/bash

# Business Critical Integration Tests - Local Environment Setup
# This script configures your local macOS environment for running integration tests
#
# Usage: ./setup-local-environment.sh [PROJECT_ID] [SERVER_API_KEY] [MOBILE_API_KEY]
# If parameters are provided, the script will skip interactive prompts

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
PARAM_PROJECT_ID="$1"
PARAM_SERVER_KEY="$2"
PARAM_MOBILE_KEY="$3"

# Check if all parameters were provided and not empty
if [[ -n "$PARAM_PROJECT_ID" && -n "$PARAM_SERVER_KEY" && -n "$PARAM_MOBILE_KEY" ]]; then
    SKIP_INTERACTIVE=true
else
    SKIP_INTERACTIVE=false
fi

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

check_requirements() {
    echo_header "Checking System Requirements"
    
    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo_error "This script requires macOS"
        exit 1
    fi
    echo_success "Running on macOS $(sw_vers -productVersion)"
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        echo_error "Xcode is not installed. Please install Xcode from the App Store."
        exit 1
    fi
    
    XCODE_VERSION=$(xcodebuild -version | head -n 1 | cut -d ' ' -f 2)
    echo_success "Xcode $XCODE_VERSION is installed"
    
    # Check for iOS Simulator
    SIMULATOR_LIST=$(xcrun simctl list devices iPhone | grep -E "iPhone (14|15|16)" | head -1)
    if [[ -z "$SIMULATOR_LIST" ]]; then
        echo_warning "No recent iPhone simulator found. You may need to install iOS simulators."
        echo_info "Run: xcodebuild -downloadPlatform iOS"
    else
        echo_success "iOS Simulator available"
    fi
    
    # Check Swift
    if command -v swift &> /dev/null; then
        SWIFT_VERSION=$(swift --version | head -n 1)
        echo_success "Swift is available: $SWIFT_VERSION"
    fi
    
    # Check for required tools
    if ! command -v jq &> /dev/null; then
        echo_warning "jq is not installed. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install jq
            echo_success "jq installed"
        else
            echo_warning "Homebrew not found. Please install jq manually: brew install jq"
        fi
    else
        echo_success "jq is available"
    fi
    
    # Check Python 3
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        echo_success "$PYTHON_VERSION is available"
    else
        echo_warning "Python 3 not found. Some backend validation features may not work."
    fi
}

setup_directories() {
    echo_header "Setting Up Directory Structure"
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$SCRIPT_DIR/../reports"
    mkdir -p "$SCRIPT_DIR/../screenshots"
    mkdir -p "$SCRIPT_DIR/../logs"
    mkdir -p "$SCRIPT_DIR/../temp"
    
    echo_success "Created directory structure"
}

setup_ios_simulator() {
    echo_header "Setting Up iOS Simulator"
    
    # Find available iPhone simulators
    echo_info "Available iPhone simulators:"
    xcrun simctl list devices iPhone | grep -E "iPhone (14|15|16)" | head -5
    
    # Create a specific simulator for testing if needed
    SIMULATOR_NAME="Integration-Test-iPhone"
    DEVICE_TYPE="iPhone 16 Pro"
    RUNTIME="iOS-18-2"
    
    # Check if our test simulator already exists
    if xcrun simctl list devices | grep -q "$SIMULATOR_NAME"; then
        echo_success "Test simulator '$SIMULATOR_NAME' already exists"
        SIMULATOR_UUID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -o '[A-F0-9-]\{36\}')
    else
        echo_info "Creating test simulator: $SIMULATOR_NAME"
        # Try to create with latest iOS runtime
        AVAILABLE_RUNTIME=$(xcrun simctl list runtimes | grep "iOS" | tail -1 | awk '{print $NF}' | tr -d '()')
        if [[ -n "$AVAILABLE_RUNTIME" ]]; then
            SIMULATOR_UUID=$(xcrun simctl create "$SIMULATOR_NAME" "$DEVICE_TYPE" "$AVAILABLE_RUNTIME")
            echo_success "Created simulator: $SIMULATOR_UUID"
        else
            echo_warning "Could not create simulator. Using any available iPhone simulator."
            SIMULATOR_UUID=$(xcrun simctl list devices iPhone | grep -E "iPhone (14|15|16)" | head -1 | grep -o '[A-F0-9-]\{36\}')
        fi
    fi
    
    # Update JSON config with simulator UUID
    if command -v jq &> /dev/null; then
        jq --arg uuid "$SIMULATOR_UUID" '.simulator.simulatorUuid = $uuid' "$LOCAL_CONFIG_FILE" > "$LOCAL_CONFIG_FILE.tmp" && mv "$LOCAL_CONFIG_FILE.tmp" "$LOCAL_CONFIG_FILE"
        echo_success "Simulator UUID saved to JSON config: $SIMULATOR_UUID"
    else
        echo_warning "jq not available, cannot update JSON config with simulator UUID"
    fi
    
    # Boot the simulator
    echo_info "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || echo_info "Simulator already booted"
    
    # Wait for simulator to be ready
    sleep 3
    
    echo_success "iOS Simulator is ready"
}

configure_api_keys() {
    echo_header "Configuring API Keys and Credentials"
    
    # If running non-interactively with parameters, use them directly
    if [[ "$SKIP_INTERACTIVE" == true ]]; then
        PROJECT_ID="$PARAM_PROJECT_ID"
        SERVER_KEY="$PARAM_SERVER_KEY"
        MOBILE_KEY="$PARAM_MOBILE_KEY"
        # Generate date-prefixed email for daily unique users
        DATE_PREFIX=$(date +"%Y-%m-%d")
        TEST_USER_EMAIL="${DATE_PREFIX}-integration-test-user@test.com"
        echo_info "Running in non-interactive mode with provided parameters"
        echo_info "Using provided parameters:"
        echo_info "Project ID: $PROJECT_ID"
        echo_info "Server API Key: ${SERVER_KEY:0:8}***"
        echo_info "Mobile API Key: ${MOBILE_KEY:0:8}***"
    else
        # Check if config already exists
        if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
            echo_info "Local configuration already exists at: $LOCAL_CONFIG_FILE"
            read -p "Do you want to reconfigure? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo_info "Skipping API key configuration"
                # Load existing config values
                if command -v jq &> /dev/null; then
                    PROJECT_ID=$(jq -r '.projectId' "$LOCAL_CONFIG_FILE")
                    SERVER_KEY=$(jq -r '.serverApiKey' "$LOCAL_CONFIG_FILE") 
                    MOBILE_KEY=$(jq -r '.mobileApiKey' "$LOCAL_CONFIG_FILE")
                    TEST_USER_EMAIL=$(jq -r '.testUserEmail' "$LOCAL_CONFIG_FILE")
                    echo_info "Loaded existing configuration"
                else
                    echo_warning "jq not available, cannot load existing config"
                fi
                return
            fi
        fi
    fi
    
    # Only show interactive prompts if not using command line parameters
    if [[ "$SKIP_INTERACTIVE" != true ]]; then
        echo_info "We need THREE things from you to get started:"
        echo_warning "1. 🏗️  PROJECT ID - your Iterable project identifier"
        echo_warning "2. 🔑 SERVER-SIDE API Key - for creating users and backend operations"
        echo_warning "3. 📱 MOBILE API Key - for Swift SDK integration testing"  
        echo
        echo_info "If you don't have these keys:"
        echo_info "• Log into your Iterable account"
        echo_info "• Go to [Settings > Project Settings](https://app.iterable.com/settings/project)" 
        echo_info "• Your Project ID is shown at the top"
        echo_info "• Click on the 'API Keys' in the integrations tab (https://app.iterable.com/settings/apiKeys)"
        echo_info "• Create API keys for both 'Server-side' and 'Mobile' types"
        echo_info "• For the mobile key, do not select JWT authentication"
        echo_info "• See the README in the business-critical-integration folder for more details"
        echo_info "• You can also use the setup-local-environment.sh script to get these values for you"
        echo
        
        # Get Project ID first
        read -p "📋 Enter your Iterable Project ID: " PROJECT_ID
        if [[ -z "$PROJECT_ID" ]]; then
            echo_error "Project ID is required"
            exit 1
        fi
        
        # Get Server-side key  
        read -p "🔑 Enter your SERVER-SIDE API Key (for user management): " SERVER_KEY
        if [[ -z "$SERVER_KEY" ]]; then
            echo_error "Server-side API Key is required"
            exit 1
        fi
        
        # Get Mobile key
        read -p "📱 Enter your MOBILE API Key (for SDK testing): " MOBILE_KEY
        if [[ -z "$MOBILE_KEY" ]]; then
            echo_error "Mobile API Key is required"
            exit 1
        fi
        
        # Set test user email with date prefix for daily unique users
        DATE_PREFIX=$(date +"%Y-%m-%d")
        TEST_USER_EMAIL="${DATE_PREFIX}-integration-test-user@test.com"
    fi
    
    # Create local config file
    cat > "$LOCAL_CONFIG_FILE" << EOF
{
  "mobileApiKey": "$MOBILE_KEY",
  "serverApiKey": "$SERVER_KEY",
  "projectId": "$PROJECT_ID",
  "testUserEmail": "$TEST_USER_EMAIL",
  "baseUrl": "https://api.iterable.com",
  "environment": "local",
  "simulator": {
    "deviceType": "iPhone 16 Pro",
    "osVersion": "latest",
    "simulatorUuid": ""
  },
  "testing": {
    "timeout": 60,
    "retryAttempts": 3,
    "enableMocks": false,
    "enableDebugLogging": true
  },
  "features": {
    "pushNotifications": true,
    "inAppMessages": true,
    "embeddedMessages": true,
    "deepLinking": true
  }
}
EOF
    
    # Set appropriate permissions
    chmod 600 "$LOCAL_CONFIG_FILE"
    
    echo_success "Local configuration saved to: $LOCAL_CONFIG_FILE"
    echo_warning "Keep this file secure - it contains your API credentials"
}

create_test_user() {
    echo_header "Setting Up Test User"
    
    echo_info "Working with test user: $TEST_USER_EMAIL"
    echo_info "Project ID: $PROJECT_ID"
    
    # First, check if user already exists
    echo_info "Checking if test user exists..."
    USER_CHECK=$(curl -s -X GET "https://api.iterable.com/api/users/getByEmail?email=$TEST_USER_EMAIL" \
        -H "Api-Key: $SERVER_KEY")
    
    if echo "$USER_CHECK" | jq -e '.user' > /dev/null 2>&1; then
        echo_success "✅ Test user already present: $TEST_USER_EMAIL"
        echo_info "📄 Current user data from Iterable API:"
        echo "$USER_CHECK" | jq '.'
        
        # Update user with latest fields to ensure consistency
        echo_info "Updating user with latest test configuration..."
    else
        echo_info "🆕 Test user not found, creating new user..."
    fi
    
    # Create/Update test user via API using server-side key
    echo_info "📡 Sending user update request..."
    RESPONSE=$(curl -s -X POST "https://api.iterable.com/api/users/update" \
        -H "Api-Key: $SERVER_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "'$TEST_USER_EMAIL'",
            "dataFields": {
                "firstName": "Integration",
                "lastName": "TestUser", 
                "testUser": true,
                "createdForTesting": true,
                "platform": "iOS",
                "sdkVersion": "integration-tests",
                "purpose": "Swift SDK Integration Testing",
                "projectId": "'$PROJECT_ID'",
                "lastUpdated": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
            }
        }')
    
    echo_info "📄 Full API Response:"
    echo "$RESPONSE" | jq '.'
    
    # Check if request was successful and provide appropriate messaging
    if echo "$RESPONSE" | jq -e '.code == "Success"' > /dev/null 2>&1; then
        RESPONSE_MSG=$(echo "$RESPONSE" | jq -r '.msg' 2>/dev/null)
        if echo "$RESPONSE_MSG" | grep -q "New fields created"; then
            echo_success "✅ Test user created successfully"
        else
            echo_success "✅ Test user updated successfully" 
        fi
        echo_info "Details: $RESPONSE_MSG"
    else
        echo_warning "⚠️  API request completed with issues:"
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.msg' 2>/dev/null || echo "$RESPONSE")
        echo_warning "$ERROR_MSG"
        echo_info "Continuing - this may be normal for existing users"
    fi
    
    echo
    echo_info "🎯 Test user ready: $TEST_USER_EMAIL"
    echo_info "Use this email for all integration tests"
}


show_usage() {
    echo "Usage: $0 [PROJECT_ID] [SERVER_API_KEY] [MOBILE_API_KEY]"
    echo "       $0 --help"
    echo
    echo "Parameters:"
    echo "  PROJECT_ID      Your Iterable project identifier"
    echo "  SERVER_API_KEY  Server-side API key for user management"
    echo "  MOBILE_API_KEY  Mobile API key for SDK testing"
    echo
    echo "Examples:"
    echo "  $0                                    # Interactive mode"
    echo "  $0 12345 server_key mobile_key       # Non-interactive mode"
    echo "  $0 --help                            # Show this help"
}

main() {
    # Check for help flag
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    echo_header "Iterable Swift SDK - Local Integration Test Setup"
    echo_info "This script will configure your local development environment"
    echo_info "for running business critical integration tests."
    echo
    
    # Debug: Show what parameters were received
    echo_info "Parameters received: PROJECT_ID='$PARAM_PROJECT_ID', SERVER_KEY_LENGTH=${#PARAM_SERVER_KEY}, MOBILE_KEY_LENGTH=${#PARAM_MOBILE_KEY}"
    if [[ "$SKIP_INTERACTIVE" == true ]]; then
        echo_info "All parameters provided - running in non-interactive mode"
    else
        echo_info "Missing parameters - running in interactive mode"
    fi
    
    # Setup directory structure FIRST
    setup_directories
    
    # Get credentials and configure API keys
    configure_api_keys
    
    check_requirements
    setup_ios_simulator
        
    create_test_user
    
    echo_header "Setup Complete! 🎉"
    echo_success "Local environment is configured for integration testing"
    echo
    echo_info "Next steps:"
    echo_info "1. Run: ./scripts/validate-setup.sh"
    echo_info "2. Run: ./scripts/run-tests.sh push"
    echo_info "3. Check reports in: ./reports/"
    echo
    echo_info "Configuration saved to: $LOCAL_CONFIG_FILE"
    echo_warning "Keep your API credentials secure!"
    echo
    echo_info "Script usage: ./scripts/setup-local-environment.sh --help"
    echo_info "Test runner help: ./scripts/run-tests.sh --help"
}

# Run main function
main "$@"