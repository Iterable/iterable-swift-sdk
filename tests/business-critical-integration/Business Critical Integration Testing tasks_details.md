# Business Critical Integration Testing - Complete AI Implementation Prompt

## Mission Statement
Build a comprehensive, production-ready integration testing framework for the Iterable Swift SDK that validates ALL business critical workflows end-to-end. This must be implemented as a single, complete solution that runs automatically on GitHub Actions, validates real API interactions, and catches regressions that could impact customers.

## Critical Success Requirements
- **ONE-SHOT IMPLEMENTATION**: This prompt must provide everything needed for complete implementation
- **GITHUB ACTIONS READY**: All tests must run in parallel on CI/CD
- **REAL BACKEND VALIDATION**: Must use actual Iterable API with server keys
- **ZERO MANUAL INTERVENTION**: Fully automated from setup to cleanup
- **PRODUCTION-GRADE**: Must handle edge cases, timeouts, and failures gracefully

## Background & Business Context
The Iterable Swift SDK is a mission-critical component used by thousands of apps for mobile marketing automation. Any regressions in core functionality directly impact customer revenue and user experience. Current unit tests are insufficient - we need end-to-end validation that the SDK works with real Iterable backend services.

## Complete Test Suite Requirements (All 4 Critical Scenarios)

### 1. [MOB-11463] Push Notification Integration Test
**BUSINESS IMPACT**: Failed push notifications = lost revenue and customer churn
**COMPREHENSIVE REQUIREMENTS**:
- ✅ Push notification configuration on iOS platform  
- ✅ Device receives push notification from backend
- ✅ Device permission management and validation
- ✅ CI uses backend server keys to send notifications
- ✅ Push notification display verification
- ✅ Push delivery metrics capture and validation
- ✅ Track push opens when notification is tapped
- ✅ Deep link button handling with SDK handlers
- ✅ APNs certificate validation (dev + production)
- ✅ Background app state handling
- ✅ Foreground notification behavior

### 2. [MOB-11464] In-App Message Integration Test  
**BUSINESS IMPACT**: Failed in-app messages = reduced engagement and conversions
**COMPREHENSIVE REQUIREMENTS**:
- ✅ Silent push notification delivery and processing
- ✅ In-app message display triggered by silent push
- ✅ In-app open metrics tracking and validation
- ✅ Deep linking from in-app messages
- ✅ SDK handler invocation for navigation
- ✅ Message trigger conditions (immediate, event, never)
- ✅ Message expiration handling
- ✅ Multiple message queue management
- ✅ Message dismissal and interaction tracking

### 3. [MOB-11465] Embedded Message Integration Test
**BUSINESS IMPACT**: Failed embedded messages = broken personalization features  
**COMPREHENSIVE REQUIREMENTS**:
- ✅ Project eligibility configuration and user list setup
- ✅ Eligible user message delivery verification
- ✅ Embedded message display in app views
- ✅ Embedded message metrics validation
- ✅ Deep linking from embedded content
- ✅ Silent push flow for embedded updates
- ✅ User eligibility state changes (ineligible → eligible)
- ✅ User profile dynamic updates affecting eligibility
- ✅ Button interactions and profile toggles

### 4. [MOB-11466] Deep Linking Integration Test
**BUSINESS IMPACT**: Broken deep links = poor user experience and attribution loss
**COMPREHENSIVE REQUIREMENTS**:
- ✅ SMS/Email deep link flow validation
- ✅ App launch with URL parameter handling
- ✅ Tracking and destination domain configuration
- ✅ iOS Associated Domains setup verification
- ✅ Universal Links functionality
- ✅ Deep link handler SDK invocation
- ✅ URL resolution and routing
- ✅ App-not-installed fallback behavior
- ✅ Asset links JSON validation
- ✅ Cross-platform link compatibility

## Technical Architecture & Requirements

### GitHub Actions CI/CD Integration (MANDATORY)
- **Parallel Execution**: All 4 test suites must run concurrently for speed
- **Cost Optimization**: Tests run on PR (optional) and pre-release (mandatory)
- **Emulator-First**: Use iOS Simulator for speed and reliability
- **Secret Management**: GitHub Secrets for API keys and certificates
- **Failure Handling**: Individual test failures don't block other tests
- **Reporting**: Detailed test reports with screenshots and logs
- **Caching**: Build artifacts and dependencies cached between runs

### Test Infrastructure
- **Platform**: iOS using XCTest framework + Xcode UI Tests
- **Test Vehicle**: Modified `swift-sample-app` with test hooks
- **Backend**: Dedicated Iterable project for integration testing
- **Environment**: Staging environment with real API endpoints
- **Authentication**: Server keys and API keys via GitHub Secrets
- **Device**: iOS Simulator (latest iOS version support)

### Complete Implementation Structure
```
/tests/business-critical-integration/
├── .github/
│   └── workflows/
│       ├── integration-tests.yml              # Main GitHub Actions workflow
│       ├── push-notification-test.yml         # Individual test workflows
│       ├── inapp-message-test.yml
│       ├── embedded-message-test.yml
│       └── deep-linking-test.yml
├── scripts/
│   ├── setup-test-environment.sh              # Environment preparation
│   ├── integration-test-push-notifications.sh # Test 1 script
│   ├── integration-test-inapp-messages.sh     # Test 2 script  
│   ├── integration-test-embedded-messages.sh  # Test 3 script
│   ├── integration-test-deep-linking.sh       # Test 4 script
│   ├── run-all-tests.sh                       # Master script
│   ├── cleanup-test-data.sh                   # Cleanup script
│   └── validate-backend-state.sh              # Backend validation
├── test-suite/
│   ├── IntegrationTestBase.swift              # Base test class
│   ├── PushNotificationIntegrationTests.swift # Test 1 implementation
│   ├── InAppMessageIntegrationTests.swift     # Test 2 implementation
│   ├── EmbeddedMessageIntegrationTests.swift  # Test 3 implementation
│   ├── DeepLinkingIntegrationTests.swift      # Test 4 implementation
│   └── TestValidationHelpers.swift
├── sample-app-modifications/
│   ├── IntegrationTestAppDelegate.swift       # Test-specific app delegate
│   ├── TestConfigurationManager.swift         # Dynamic config management
│   ├── APICallMonitor.swift                   # API call interception
│   └── DeepLinkTestHandler.swift              # Deep link test handling
├── backend-integration/
│   ├── IterableAPIClient.swift                # Backend validation client
│   ├── PushNotificationSender.swift          # Send test pushes
│   ├── CampaignManager.swift                  # Create test campaigns
│   └── MetricsValidator.swift                 # Validate tracking metrics
├── config/
│   ├── test-config-staging.json               # Staging environment config
│   ├── test-config-production.json            # Production environment config
│   ├── push-test-config.json                  # Push notification test data
│   ├── inapp-test-config.json                 # In-app message test data
│   ├── embedded-test-config.json              # Embedded message test data
│   ├── deeplink-test-config.json              # Deep link test data
│   └── api-endpoints.json                     # API endpoint definitions
├── utilities/
│   ├── APIValidationHelper.swift              # API response validation
│   ├── TestDataGenerator.swift                # Generate test data
│   ├── ScreenshotCapture.swift                # UI validation via screenshots
│   ├── LogParser.swift                        # Parse and validate logs
│   ├── RetryHelper.swift                      # Handle network retries
│   └── TestReporter.swift                     # Generate test reports
└── documentation/
    ├── INTEGRATION_TEST_SETUP.md              # Setup guide
    ├── GITHUB_ACTIONS_CONFIG.md               # CI/CD configuration
    ├── TROUBLESHOOTING.md                      # Common issues and fixes
    └── API_VALIDATION_GUIDE.md                # Backend validation guide
```

### GitHub Actions Workflow Requirements
Each workflow must:
1. **Setup**: Configure iOS environment, install dependencies, setup certificates
2. **Build**: Build modified sample app with test configuration
3. **Execute**: Run specific integration test suite with timeout handling
4. **Validate**: Verify backend state via API calls with retry logic
5. **Report**: Generate detailed reports with screenshots and logs
6. **Cleanup**: Clean up test data and temporary resources
7. **Parallel**: Run independently without blocking other tests

## Complete Implementation Guide (One-Shot Execution)

### Phase 1: GitHub Actions & CI/CD Setup (CRITICAL FIRST STEP)
**Create the complete GitHub Actions infrastructure:**

1. **Main Integration Test Workflow** (`/.github/workflows/integration-tests.yml`)
   - Matrix strategy for parallel execution of all 4 test suites
   - iOS Simulator setup with latest Xcode version
   - Environment variable management for API keys
   - Artifact collection for test reports and screenshots
   - Slack/email notifications on failure

2. **Individual Test Workflows** 
   - `push-notification-test.yml` - Dedicated push notification testing
   - `inapp-message-test.yml` - In-app message flow testing  
   - `embedded-message-test.yml` - Embedded message testing
   - `deep-linking-test.yml` - Deep link validation testing

3. **GitHub Secrets Configuration**
   - `ITERABLE_API_KEY` - Main API key for backend communication
   - `ITERABLE_SERVER_KEY` - Server key for push notification sending
   - `TEST_PROJECT_ID` - Dedicated test project identifier
   - `APNS_CERTIFICATE` - APNs certificate for push notifications
   - `TEST_USER_EMAIL` - Test user email for integration tests

### Phase 2: Sample App Modification & Test Infrastructure
**Transform swift-sample-app into a test-ready application:**

1. **Integration Test App Delegate** (`IntegrationTestAppDelegate.swift`)
   - Dynamic API key injection from environment variables
   - Test hook registration for validation points
   - API call monitoring and logging
   - Push notification permission handling

2. **Test Configuration Manager** (`TestConfigurationManager.swift`)
   - Load test configurations from JSON files
   - Environment-specific settings management
   - Test user profile setup
   - Campaign and message configuration

3. **API Call Monitor** (`APICallMonitor.swift`)
   - Intercept and log all SDK API calls
   - Validate request/response data
   - Track timing and success/failure rates
   - Generate API interaction reports

### Phase 3: Complete Test Suite Implementation

#### Test 1: Push Notification Integration (`PushNotificationIntegrationTests.swift`)
**End-to-end push notification workflow validation:**

```swift
class PushNotificationIntegrationTests: IntegrationTestBase {
    func testPushNotificationFullWorkflow() {
        // 1. Launch app and verify automatic device registration
        // 2. Validate registerDeviceToken API call with correct parameters
        // 3. Verify device token stored in Iterable backend via API
        // 4. Send test push notification using server key
        // 5. Validate push notification received and displayed
        // 6. Test push notification tap and deep link handling
        // 7. Verify push open tracking metrics in backend
        // 8. Test background vs foreground notification behavior
    }
    
    func testPushPermissionHandling() {
        // Test permission request flow and edge cases
    }
    
    func testPushNotificationButtons() {
        // Test action buttons and deep link handling
    }
}
```

#### Test 2: In-App Message Integration (`InAppMessageIntegrationTests.swift`)
**Complete in-app message lifecycle validation:**

```swift
class InAppMessageIntegrationTests: IntegrationTestBase {
    func testInAppMessageSilentPushFlow() {
        // 1. Configure in-app campaign in backend
        // 2. Send silent push to trigger message fetch
        // 3. Verify silent push processing and message retrieval
        // 4. Validate in-app message display timing and content
        // 5. Test message interaction (tap, dismiss, buttons)
        // 6. Verify in-app open metrics tracked correctly
        // 7. Test deep link navigation from in-app message
        // 8. Validate message expiration and cleanup
    }
    
    func testMultipleInAppMessages() {
        // Test message queue and display priority
    }
    
    func testInAppMessageTriggers() {
        // Test immediate, event, and never trigger types
    }
}
```

#### Test 3: Embedded Message Integration (`EmbeddedMessageIntegrationTests.swift`)
**Embedded message eligibility and display validation:**

```swift
class EmbeddedMessageIntegrationTests: IntegrationTestBase {
    func testEmbeddedMessageEligibilityFlow() {
        // 1. Setup user profile with ineligible state
        // 2. Configure embedded message campaign with eligibility rules
        // 3. Update user profile to become eligible
        // 4. Verify silent push triggers embedded message update
        // 5. Validate embedded message appears in designated view
        // 6. Test embedded message metrics tracking
        // 7. Test deep link functionality from embedded content
        // 8. Toggle user eligibility and verify message removal
    }
    
    func testEmbeddedMessageUserProfileUpdates() {
        // Test dynamic profile changes affecting eligibility
    }
    
    func testEmbeddedMessageInteractions() {
        // Test button clicks and navigation
    }
}
```

#### Test 4: Deep Linking Integration (`DeepLinkingIntegrationTests.swift`) 
**Universal links and deep link handling validation:**

```swift
class DeepLinkingIntegrationTests: IntegrationTestBase {
    func testUniversalLinkFlow() {
        // 1. Configure associated domains and asset links
        // 2. Test app launch via SMS/email deep link
        // 3. Verify URL parameter parsing and handling
        // 4. Validate deep link handler SDK invocation
        // 5. Test navigation to correct app section
        // 6. Verify tracking and attribution data
        // 7. Test app-not-installed fallback behavior
        // 8. Validate cross-platform link compatibility
    }
    
    func testDeepLinkFromPushNotification() {
        // Test deep links embedded in push notifications
    }
    
    func testDeepLinkFromInAppMessage() {
        // Test deep links from in-app message content
    }
}
```

### Phase 4: Backend Integration & Validation
**Real Iterable API interaction and validation:**

1. **Iterable API Client** (`IterableAPIClient.swift`)
   - Complete API wrapper for backend validation
   - Device registration verification
   - Campaign and message management
   - Metrics and analytics validation
   - User profile management

2. **Push Notification Sender** (`PushNotificationSender.swift`)
   - Send test push notifications using server keys
   - Support for different notification types
   - Batch notification sending
   - Delivery confirmation tracking

3. **Metrics Validator** (`MetricsValidator.swift`)
   - Validate all tracking events reach backend
   - Verify event timing and data accuracy
   - Check conversion and engagement metrics
   - Generate metrics validation reports

### Phase 5: Automated Execution Scripts
**Complete shell script automation:**

1. **Master Test Runner** (`run-all-tests.sh`)
   - Execute all 4 test suites in parallel
   - Aggregate results and generate master report
   - Handle individual test failures gracefully
   - Clean up all test data on completion

2. **Individual Test Scripts**
   - Each test has dedicated execution script
   - Environment setup and configuration
   - Test execution with proper error handling
   - Backend validation and cleanup

## Complete Deliverables Checklist (All Must Be Implemented)

### 1. GitHub Actions Workflows (5 files)
- [ ] `/.github/workflows/integration-tests.yml` - Master workflow with parallel execution matrix
- [ ] `/.github/workflows/push-notification-test.yml` - Push notification test workflow
- [ ] `/.github/workflows/inapp-message-test.yml` - In-app message test workflow  
- [ ] `/.github/workflows/embedded-message-test.yml` - Embedded message test workflow
- [ ] `/.github/workflows/deep-linking-test.yml` - Deep linking test workflow

### 2. Executable Test Scripts (7 files)
- [ ] `run-all-tests.sh` - Master script executing all tests in parallel
- [ ] `setup-test-environment.sh` - Complete environment preparation
- [ ] `integration-test-push-notifications.sh` - Push notification test execution
- [ ] `integration-test-inapp-messages.sh` - In-app message test execution
- [ ] `integration-test-embedded-messages.sh` - Embedded message test execution
- [ ] `integration-test-deep-linking.sh` - Deep linking test execution
- [ ] `cleanup-test-data.sh` - Comprehensive test data cleanup

### 3. Complete Test Suite Implementation (6 files)
- [ ] `IntegrationTestBase.swift` - Base class with common functionality
- [ ] `PushNotificationIntegrationTests.swift` - Complete push notification test suite
- [ ] `InAppMessageIntegrationTests.swift` - Complete in-app message test suite
- [ ] `EmbeddedMessageIntegrationTests.swift` - Complete embedded message test suite
- [ ] `DeepLinkingIntegrationTests.swift` - Complete deep linking test suite
- [ ] `TestValidationHelpers.swift` - Shared validation utilities

### 4. Sample App Modifications (4 files)
- [ ] `IntegrationTestAppDelegate.swift` - Test-ready app delegate
- [ ] `TestConfigurationManager.swift` - Dynamic configuration management
- [ ] `APICallMonitor.swift` - API call interception and validation
- [ ] `DeepLinkTestHandler.swift` - Deep link test handling

### 5. Backend Integration Layer (4 files)
- [ ] `IterableAPIClient.swift` - Complete backend validation client
- [ ] `PushNotificationSender.swift` - Test push notification sender
- [ ] `CampaignManager.swift` - Test campaign management
- [ ] `MetricsValidator.swift` - Comprehensive metrics validation

### 6. Configuration Files (6 files)
- [ ] `test-config-staging.json` - Staging environment configuration
- [ ] `push-test-config.json` - Push notification test data
- [ ] `inapp-test-config.json` - In-app message test data
- [ ] `embedded-test-config.json` - Embedded message test data
- [ ] `deeplink-test-config.json` - Deep linking test data
- [ ] `api-endpoints.json` - Complete API endpoint definitions

### 7. Utility Classes (6 files)
- [ ] `APIValidationHelper.swift` - API response validation utilities
- [ ] `TestDataGenerator.swift` - Dynamic test data generation
- [ ] `ScreenshotCapture.swift` - UI validation via screenshots
- [ ] `LogParser.swift` - Log parsing and validation
- [ ] `RetryHelper.swift` - Network retry logic
- [ ] `TestReporter.swift` - Comprehensive test reporting

### 8. Documentation (4 files)
- [ ] `INTEGRATION_TEST_SETUP.md` - Complete setup guide
- [ ] `GITHUB_ACTIONS_CONFIG.md` - CI/CD configuration guide
- [ ] `TROUBLESHOOTING.md` - Common issues and solutions
- [ ] `API_VALIDATION_GUIDE.md` - Backend validation procedures

## Comprehensive Success Criteria (ALL Must Pass)

### Push Notification Integration Test (MOB-11463)
- [ ] App launches and automatically registers device token
- [ ] Device registration API call monitored and validated
- [ ] Backend confirms device token stored correctly via API query
- [ ] Test push notification sent using GitHub Actions secrets
- [ ] Push notification received and displayed on simulator
- [ ] Push notification tap tracked and deep links processed
- [ ] Push open metrics validated in backend
- [ ] Permission handling tested and validated
- [ ] Background vs foreground notification behavior verified

### In-App Message Integration Test (MOB-11464)
- [ ] Silent push notification triggers in-app message fetch
- [ ] In-app message displayed with correct timing and content
- [ ] In-app message interactions (tap, dismiss, buttons) tracked
- [ ] Deep linking from in-app messages works correctly
- [ ] In-app open metrics validated in backend
- [ ] Message expiration and cleanup verified
- [ ] Multiple message queue management tested
- [ ] Trigger conditions (immediate, event, never) validated

### Embedded Message Integration Test (MOB-11465)
- [ ] User eligibility rules configured and tested
- [ ] Silent push triggers embedded message updates
- [ ] Embedded messages display in correct app views
- [ ] User profile changes affect message eligibility
- [ ] Embedded message metrics tracked correctly
- [ ] Deep linking from embedded content works
- [ ] User eligibility state transitions tested
- [ ] Button interactions and profile toggles validated

### Deep Linking Integration Test (MOB-11466)
- [ ] Universal links configured and tested
- [ ] App launches correctly via SMS/email deep links
- [ ] URL parameters parsed and handled correctly
- [ ] Deep link handlers invoked properly
- [ ] Navigation to correct app sections verified
- [ ] Tracking and attribution data captured
- [ ] App-not-installed fallback behavior tested
- [ ] Asset links and associated domains validated

### GitHub Actions & CI/CD Requirements
- [ ] All 4 test suites run in parallel successfully
- [ ] Tests execute reliably in iOS Simulator environment
- [ ] GitHub Secrets properly configured and used
- [ ] Test failures don't block other parallel tests
- [ ] Detailed test reports generated with screenshots
- [ ] All test data cleaned up after execution
- [ ] Notifications sent on test failures
- [ ] Build artifacts cached for performance

### Backend Validation Requirements
- [ ] All API interactions validated both client and server-side
- [ ] Device registration confirmed via backend API queries
- [ ] Push notifications sent and delivery confirmed
- [ ] Campaign and message configuration verified
- [ ] All tracking metrics validated in real-time
- [ ] User profile changes reflected in backend
- [ ] Test data isolation and cleanup verified

### Automation & Reliability Requirements
- [ ] Tests run completely without manual intervention
- [ ] Proper error handling and retry logic implemented
- [ ] Clear pass/fail reporting with detailed error information
- [ ] Tests handle network latency and API rate limiting
- [ ] Secrets and credentials managed securely
- [ ] Performance optimized with caching and parallelization

## Technical Constraints & Requirements

### Non-Negotiable Requirements
- **ZERO CHANGES** to core SDK functionality - tests must work with existing SDK
- **PRODUCTION SAFETY** - all tests must use dedicated test environment
- **COST CONSCIOUS** - optimize for GitHub Actions minutes and API calls
- **SECURITY FIRST** - all secrets managed via GitHub Secrets, no hardcoded credentials
- **BACKWARD COMPATIBLE** - must work with current iOS SDK architecture

### Performance & Reliability Constraints
- **Parallel Execution** - all 4 test suites must run concurrently (max 15 mins total)
- **Network Resilience** - handle API rate limiting, timeouts, and retries
- **Resource Management** - proper cleanup of test data and simulator resources
- **Error Isolation** - individual test failures must not affect other tests
- **Deterministic Results** - tests must be reliable and repeatable

### CI/CD Integration Requirements
- **GitHub Actions Native** - designed specifically for GitHub Actions environment
- **Artifact Management** - proper collection and storage of test reports
- **Notification Integration** - failure alerts via Slack/email
- **Caching Strategy** - optimize build times with dependency caching
- **Matrix Strategy** - support for multiple iOS versions and Xcode versions

## Implementation Execution Plan (Start Here)

### Step 1: Environment Setup (First 30 mins)
1. **Create complete directory structure** as specified above
2. **Setup GitHub Secrets** with all required API keys and certificates
3. **Create base configuration files** with staging environment details
4. **Initialize GitHub Actions workflows** with proper matrix strategy

### Step 2: Core Infrastructure (Next 60 mins)
1. **Implement IntegrationTestBase.swift** with common test functionality
2. **Create sample app modifications** for test hooks and monitoring
3. **Build backend integration layer** for API validation
4. **Setup utility classes** for screenshots, logging, and reporting

### Step 3: Test Suite Implementation (Next 120 mins)
1. **Push Notification Test** - highest priority, implement completely first
2. **In-App Message Test** - second priority, full workflow validation
3. **Embedded Message Test** - third priority, eligibility and display
4. **Deep Linking Test** - fourth priority, universal links and navigation

### Step 4: Automation Scripts (Next 60 mins)
1. **Individual test scripts** for each test suite
2. **Master runner script** for parallel execution
3. **Environment setup and cleanup scripts**
4. **Backend validation and metrics verification**

### Step 5: Documentation & Validation (Final 30 mins)
1. **Complete setup documentation** with step-by-step instructions
2. **Troubleshooting guide** for common issues
3. **Final validation** that all deliverables are complete
4. **Test the complete workflow** end-to-end

## Critical Implementation Notes

### GitHub Actions Secrets Required
```yaml
ITERABLE_API_KEY: "your-api-key-here"
ITERABLE_SERVER_KEY: "your-server-key-here"  
TEST_PROJECT_ID: "your-test-project-id"
APNS_CERTIFICATE: "base64-encoded-certificate"
TEST_USER_EMAIL: "test-user@example.com"
SLACK_WEBHOOK_URL: "for-notifications"
```

### Sample App Test Configuration
The modified sample app must:
- Accept API keys via environment variables
- Include test hooks for validation points
- Monitor and log all SDK API calls
- Handle push notification permissions automatically
- Support deep link testing scenarios

### Backend Validation Strategy
All tests must validate both:
1. **Client-side behavior** - SDK API calls, UI interactions, navigation
2. **Server-side state** - backend confirms data received, stored, processed

### Success Validation Approach
Each test must verify:
- ✅ **Immediate success** - SDK calls succeed, UI behaves correctly
- ✅ **Backend confirmation** - API queries confirm data reached backend
- ✅ **Metrics validation** - tracking events appear in analytics
- ✅ **End-to-end flow** - complete user journey works as expected

## Final Implementation Checklist
Before considering this task complete, verify:
- [ ] All 36 deliverable files created and functional
- [ ] All 4 test suites pass completely in isolation
- [ ] All tests run successfully in parallel on GitHub Actions  
- [ ] All backend validation confirms proper data flow
- [ ] All test data cleaned up properly after execution
- [ ] All documentation complete and accurate
- [ ] All error scenarios handled gracefully
- [ ] All secrets and credentials properly secured

**This framework will provide bulletproof confidence that the Iterable Swift SDK works correctly in production scenarios and will catch any regressions that could impact customer revenue or user experience.** 