#!/bin/bash

# Business Critical Integration Tests - Local Environment Setup
# This script configures your local macOS environment for running integration tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"
LOCAL_CONFIG_FILE="$CONFIG_DIR/local-config.json"

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
    
    # Store simulator UUID for later use
    echo "$SIMULATOR_UUID" > "$CONFIG_DIR/simulator-uuid.txt"
    echo_success "Simulator UUID saved: $SIMULATOR_UUID"
    
    # Boot the simulator
    echo_info "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UUID" 2>/dev/null || echo_info "Simulator already booted"
    
    # Wait for simulator to be ready
    sleep 3
    
    echo_success "iOS Simulator is ready"
}

configure_api_keys() {
    echo_header "Configuring API Keys and Credentials"
    
    # Check if config already exists
    if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
        echo_info "Local configuration already exists at: $LOCAL_CONFIG_FILE"
        read -p "Do you want to reconfigure? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Skipping API key configuration"
            return
        fi
    fi
    
    echo_info "Setting up local configuration..."
    echo_warning "You'll need your Iterable API credentials. If you don't have them:"
    echo_warning "1. Log into your Iterable account"
    echo_warning "2. Go to Settings > API Keys"
    echo_warning "3. Create a new API key with appropriate permissions"
    echo
    
    # Prompt for API key
    read -p "Enter your Iterable API Key: " API_KEY
    if [[ -z "$API_KEY" ]]; then
        echo_error "API Key is required"
        exit 1
    fi
    
    # Prompt for Server key (optional for some tests)
    read -p "Enter your Iterable Server Key (optional, press Enter to skip): " SERVER_KEY
    
    # Prompt for project ID
    read -p "Enter your Test Project ID (or press Enter for default): " PROJECT_ID
    if [[ -z "$PROJECT_ID" ]]; then
        PROJECT_ID="integration-test-project"
    fi
    
    # Prompt for test user email
    read -p "Enter test user email (or press Enter for default): " TEST_USER_EMAIL
    if [[ -z "$TEST_USER_EMAIL" ]]; then
        TEST_USER_EMAIL="integration-test@example.com"
    fi
    
    # Create local config file
    cat > "$LOCAL_CONFIG_FILE" << EOF
{
  "apiKey": "$API_KEY",
  "serverKey": "$SERVER_KEY",
  "projectId": "$PROJECT_ID",
  "testUserEmail": "$TEST_USER_EMAIL",
  "baseUrl": "https://api.iterable.com",
  "environment": "local",
  "simulator": {
    "deviceType": "iPhone 16 Pro",
    "osVersion": "latest"
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

setup_test_project() {
    echo_header "Setting Up Test Project Structure"
    
    # Create a simple Xcode project for local testing
    LOCAL_PROJECT_DIR="$SCRIPT_DIR/../LocalIntegrationTest"
    
    if [[ ! -d "$LOCAL_PROJECT_DIR" ]]; then
        mkdir -p "$LOCAL_PROJECT_DIR"
        
        # Create a basic Package.swift for the test project
        cat > "$LOCAL_PROJECT_DIR/Package.swift" << 'EOF'
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LocalIntegrationTest",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(path: "../../../")
    ],
    targets: [
        .target(
            name: "LocalIntegrationTest",
            dependencies: ["IterableSDK"],
            path: "Sources"
        ),
        .testTarget(
            name: "LocalIntegrationTestTests",
            dependencies: ["LocalIntegrationTest"],
            path: "Tests"
        )
    ]
)
EOF
        
        # Create source directories
        mkdir -p "$LOCAL_PROJECT_DIR/Sources/LocalIntegrationTest"
        mkdir -p "$LOCAL_PROJECT_DIR/Tests/LocalIntegrationTestTests"
        
        # Create a simple main file
        cat > "$LOCAL_PROJECT_DIR/Sources/LocalIntegrationTest/LocalIntegrationTest.swift" << 'EOF'
import Foundation
import IterableSDK

public class LocalIntegrationTest {
    public static func configure() {
        print("LocalIntegrationTest configured")
    }
}
EOF
        
        echo_success "Created local test project structure"
    else
        echo_info "Local test project already exists"
    fi
}

install_dependencies() {
    echo_header "Installing Dependencies"
    
    # Check if we're in the Swift SDK directory
    if [[ ! -f "$PROJECT_ROOT/Package.swift" ]]; then
        echo_error "Not in Swift SDK root directory. Please run from the swift-sdk project root."
        exit 1
    fi
    
    # Build the SDK first to ensure it compiles
    echo_info "Building Iterable Swift SDK..."
    cd "$PROJECT_ROOT"
    
    if swift build > /dev/null 2>&1; then
        echo_success "Swift SDK builds successfully"
    else
        echo_warning "Swift SDK build had issues, but continuing..."
    fi
    
    # Install any additional Python dependencies for backend validation
    if command -v python3 &> /dev/null; then
        echo_info "Installing Python dependencies for backend validation..."
        python3 -m pip install requests --user --quiet 2>/dev/null || echo_info "Python requests already installed or not available"
    fi
}

create_test_scripts() {
    echo_header "Creating Local Test Scripts"
    
    # Create a simple test runner script
    cat > "$SCRIPT_DIR/run-single-test.sh" << 'EOF'
#!/bin/bash

# Simple script to run a single integration test locally
TEST_TYPE="$1"
CONFIG_FILE="$(dirname "$0")/../config/local-config.json"

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
echo "📝 Next: Implement actual test execution for $TEST_TYPE"
EOF
    
    chmod +x "$SCRIPT_DIR/run-single-test.sh"
    echo_success "Created run-single-test.sh"
    
    # Create validation script
    cat > "$SCRIPT_DIR/validate-setup.sh" << 'EOF'
#!/bin/bash

# Validate local environment setup
CONFIG_FILE="$(dirname "$0")/../config/local-config.json"
SIMULATOR_FILE="$(dirname "$0")/../config/simulator-uuid.txt"

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
EOF
    
    chmod +x "$SCRIPT_DIR/validate-setup.sh"
    echo_success "Created validate-setup.sh"
}

main() {
    echo_header "Iterable Swift SDK - Local Integration Test Setup"
    echo_info "This script will configure your local development environment"
    echo_info "for running business critical integration tests."
    echo
    
    check_requirements
    setup_directories
    setup_ios_simulator
    configure_api_keys
    setup_test_project
    install_dependencies
    create_test_scripts
    
    echo_header "Setup Complete! 🎉"
    echo_success "Local environment is configured for integration testing"
    echo
    echo_info "Next steps:"
    echo_info "1. Run: ./scripts/validate-setup.sh"
    echo_info "2. Run: ./scripts/run-tests-locally.sh push"
    echo_info "3. Check reports in: ./reports/"
    echo
    echo_info "Configuration saved to: $LOCAL_CONFIG_FILE"
    echo_warning "Keep your API credentials secure!"
    echo
    echo_info "For help: ./scripts/run-tests-locally.sh --help"
}

# Run main function
main "$@"