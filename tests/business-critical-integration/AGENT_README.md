# Business Critical Integration Tests - CI Push Notification Strategy

## Overview
This project implements push notification integration tests that work seamlessly in both local and CI environments.

## CI Push Notification Strategy

### Problem
- CI servers use macOS virtualization which doesn't provide device tokens
- Without device tokens, apps can't register for APNS push notifications
- This breaks push notification integration tests in CI

### Solution Implemented
1. **Environment Detection**: Automatically detects CI environment via environment variables
2. **Mock Device Token**: Generates fake device tokens for CI testing 
3. **Simulated Push Notifications**: Uses `xcrun simctl push` to send fake pushes to simulator
4. **Local Testing Unchanged**: Real APNS pushes continue to work locally

## Technical Implementation

### Key Files Modified
- `AppDelegate+IntegrationTest.swift`: CI detection + mock device token generation
- `IntegrationTestBase.swift`: CI environment detection + simulated push capabilities
- `PushNotificationIntegrationTests.swift`: CI-aware push notification testing
- `run-tests.sh`: CI environment variable setup

### CI Environment Detection
- Checks for `CI=1`, `GITHUB_ACTIONS`, `JENKINS_URL`, `BUILDKITE` environment variables
- Automatically enables mock mode when detected

### Mock Device Token Generation
- Generates realistic 32-byte hex string tokens in CI
- Simulates `didRegisterForRemoteNotificationsWithDeviceToken` callback
- Maintains full Iterable SDK registration flow

### Simulated Push Notifications
- Uses `xcrun simctl push` command with temporary `.apns` payload files
- Supports both standard and deep link push notifications
- Validates same notification handling logic as real pushes
- **NEW**: Background push monitor in test runner automatically executes queued push commands
- Test creates persistent payload and command files in `/tmp/push_queue`
- Test runner monitors queue directory and executes `xcrun simctl` commands automatically

## Usage

### Local Testing (Default)
```bash
./scripts/run-tests.sh
```
- Uses real APNS push notifications
- Full end-to-end validation

### CI Testing
```bash
CI=1 ./scripts/run-tests.sh
```
- Uses mock device tokens
- Sends simulated push notifications
- Tests full push notification flow without network dependencies

## Push Notification Payloads

### Standard Push (CI)
```json
{
  "aps": {
    "alert": {
      "title": "Integration Test",
      "body": "This is an integration test simple push"
    },
    "badge": 1,
    "sound": "default"
  },
  "itbl": {
    "campaignId": 12345,
    "templateId": 67890,
    "isGhostPush": false
  }
}
```

### Deep Link Push (CI)
```json
{
  "aps": {
    "alert": {
      "title": "Deep Link Test", 
      "body": "This is a deep link push notification test"
    },
    "badge": 1,
    "sound": "default"
  },
  "itbl": {
    "campaignId": 12346,
    "templateId": 67891,
    "isGhostPush": false,
    "deepLinkURL": "tester://product?itemId=12345&category=shoes"
  }
}
```

## Screenshot Management

### Problem
- Screenshots were being saved to iOS simulator's Documents directory instead of project's screenshots folder
- Screenshots from test runs were not accessible for review or CI artifacts

### Solution
- Added `copy_screenshots_from_simulator()` function to run-tests.sh
- Automatically copies screenshots from simulator Documents to project screenshots folder after tests complete
- Clears previous screenshots from project directory before copying new ones
- Cleans up simulator screenshots after successful copy

### Implementation
- Parses screenshot directory path directly from test log files in reports directory
- Uses `find` to locate most recent `.log` file for parsing
- Falls back to searching simulator directories if log parsing fails
- Integrates into test completion flow before cleanup
- Fixed xcresulttool deprecation warning by adding `--legacy` flag

## Test Artifacts Organization

### Directory Structure
- **📁 reports/**: XCTest result bundles (.xcresult) and test reports (.log files for screenshot parsing)
- **📁 logs/**: Complete test execution logs with full output 
- **📁 screenshots/**: Test screenshots automatically copied from simulator
- **📁 scripts/**: Test execution and utility scripts

### File Naming Convention
- Timestamp format: `YYYYMMDD-HHMMSS`
- Test class name converted to lowercase
- Examples:
  - `pushnotificationintegrationtests-20250829-131349.xcresult`
  - `pushnotificationintegrationtests-20250829-131349.log`

## CI Network Validation Strategy

### Mock Device Token Handling
- **CI Environment**: Skips 200 status code validation for `registerDeviceToken` API calls
- **Reason**: Mock device tokens in CI may return unpredictable backend responses
- **Local Environment**: Full validation including 200 status codes continues as normal
- **Detection**: Uses existing `isRunningInCI` environment detection

## Daily Test User Creation

### Enhancement
- **Date-Prefixed Email Generation**: Test user emails now include current date prefix for daily unique users
- **Format**: `YYYY-MM-DD-integration-test-user@test.com` (e.g., `2025-01-07-integration-test-user@test.com`)
- **Automatic**: Both interactive and non-interactive modes generate date-prefixed emails
- **Benefits**: Enables fresh test users daily, avoiding conflicts with previous test data

### Implementation
- Modified `setup-local-environment.sh` to add `$(date +"%Y-%m-%d")` prefix to test emails
- Works in both interactive and non-interactive setup modes
- Updates JSON configuration automatically with date-prefixed email
- Maintains backward compatibility with existing test infrastructure

## Deep Link Integration Tests (SDK-292)

### Overview
Comprehensive deep link routing test infrastructure for validating URL delegate and custom action delegate callbacks.

### What's Tested
1. **URL Delegate Registration & Callbacks**
   - Delegate registration during SDK initialization
   - URL parameter extraction and validation
   - `tester://` scheme handling for test deep links
   
2. **Custom Action Delegate Registration & Callbacks**
   - Delegate registration and method invocation
   - Custom action type and data parameter validation
   
3. **Deep Link Integration Flows**
   - Deep link routing from push notifications
   - Deep link routing from in-app messages
   - Deep link routing from embedded messages
   
4. **Alert-Based Validation**
   - Alert content validation for deep link callbacks
   - Expected vs actual URL comparison
   - Multiple alert sequence handling

### Key Files
- `DeepLinkingIntegrationTests.swift`: Main test suite with 8 comprehensive test methods
- `DeepLinkHelpers.swift`: Alert validation, URL extraction, and comparison utilities  
- `MockDelegates.swift`: Mock URL and custom action delegates with verification helpers
- `AppDelegate.swift`: Production delegates implementation (lines 334-392)
- `AppDelegate+IntegrationTest.swift`: Delegate wiring during SDK init (lines 79-80)

### Test Infrastructure
- **Mock Delegates**: Full verification support with call history tracking
- **Alert Helpers**: `AlertExpectation` for declarative alert validation
- **URL Validation**: Component-by-component URL comparison utilities
- **CI Support**: Uses simulated push notifications for deep link testing

### Running Deep Link Tests

#### Local Testing
```bash
./scripts/run-tests.sh deeplink
```

#### CI Testing  
```bash
CI=1 ./scripts/run-tests.sh deeplink
```

### GitHub Actions Workflow
- **File**: `.github/workflows/bcit-integration-test-deep-linking.yml`
- **Triggers**: PR labels (`bcit`, `bcit-deeplink`), workflow_dispatch, release branches
- **Timeout**: 30 minutes
- **Artifacts**: Test results, screenshots, logs (7-day retention)

### Current Scope (Pre-Custom Domain)
- ✅ Delegate registration and callback validation
- ✅ Alert-based deep link verification  
- ✅ Integration with push, in-app, and embedded messages
- ✅ URL parameter and context validation
- ⏸️ Wrapped link testing (requires custom domains)
- ⏸️ External source simulation (requires custom domains)

### Future Enhancements
Once custom domains are configured:
1. Wrapped universal link testing
2. External source simulation (Reminders, Notes, Messages)
3. End-to-end click tracking validation
4. Cross-platform attribution testing

## Benefits
- ✅ Push notification tests run successfully in CI
- ✅ No changes to existing local testing workflow  
- ✅ Tests complete push flow including device registration
- ✅ Supports both standard and deep link push notifications
- ✅ Maintains payload format compatibility for future changes
- ✅ Screenshots automatically copied to project directory for review and CI artifacts
- ✅ Complete test artifacts organized in dedicated directories
- ✅ XCTest results saved for detailed analysis and CI integration
- ✅ Smart network validation that adapts to CI vs local environments
- ✅ **NEW**: Automated push execution via background monitor eliminates manual intervention
- ✅ **NEW**: Enhanced logging provides comprehensive visibility into push simulation process
- ✅ **NEW**: Robust file-based communication between iOS test and macOS test runner
- ✅ **NEW**: Daily test user creation with date-prefixed emails for fresh testing environment
- ✅ **NEW**: Deep link routing test framework with comprehensive delegate validation
- ✅ **NEW**: Alert-based verification system for non-domain-dependent deep link testing
