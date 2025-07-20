# AGENT README - Iterable Swift SDK

## Project Overview
This is the **Iterable Swift SDK** for iOS/macOS integration. The SDK provides:
- Push notification handling
- In-app messaging 
- Event tracking
- User management
- Unknown user tracking

## Key Architecture
- **Core SDK**: `swift-sdk/` - Main SDK implementation
- **Sample Apps**: `sample-apps/` - Example integrations
- **Tests**: `tests/` - Unit tests, UI tests, and integration tests
- **Notification Extension**: `notification-extension/` - Rich push support

## Development Workflow

### 🔨 Building the SDK
```bash
./agent_build.sh
```
- Validates compilation on iOS Simulator
- Shows build errors with context
- Requires macOS with Xcode

### 🧪 Running Tests  
```bash
# Run all tests
./agent_test.sh

# Run specific test suite
./agent_test.sh IterableApiCriteriaFetchTests

# Run specific test (dot notation - recommended)
./agent_test.sh "IterableApiCriteriaFetchTests.testForegroundCriteriaFetchWhenConditionsMet"

# Run specific test (full path)
./agent_test.sh "unit-tests/IterableApiCriteriaFetchTests/testForegroundCriteriaFetchWhenConditionsMet"
```
- Executes on iOS Simulator with accurate pass/fail reporting
- Returns exit code 0 for success, 1 for failures
- Shows detailed test counts and failure information
- Requires password for xcpretty installation (first run)

## Project Structure
```
swift-sdk/
├── swift-sdk/               # Main SDK source
│   ├── Core/               # Public APIs and models
│   ├── Internal/           # Internal implementation
│   ├── SDK/               # Main SDK entry points
│   └── ui-components/     # SwiftUI/UIKit components
├── tests/                 # Test suites
│   ├── unit-tests/        # Unit tests
│   ├── ui-tests/         # UI automation tests
│   └── endpoint-tests/   # API endpoint tests
├── sample-apps/          # Example applications
└── notification-extension/ # Push notification extension
```

## Key Classes
- **IterableAPI**: Main SDK interface
- **IterableConfig**: Configuration management
- **InternalIterableAPI**: Core implementation
- **UnknownUserManager**: Unknown user tracking
- **LocalStorage**: Data persistence

## Common Tasks

### Adding New Features
1. Build first: `./agent_build.sh`
2. Implement in `swift-sdk/Internal/` or `swift-sdk/SDK/`
3. Add tests in `tests/unit-tests/`
4. Verify: `./agent_test.sh` (all tests) or `./agent_test.sh YourTestSuite` (specific suite)

### Debugging Build Issues
- Build script shows compilation errors with file paths
- Check Xcode project references in `swift-sdk.xcodeproj/project.pbxproj`
- Verify file renames are reflected in project file

### Test Failures
- Test script shows specific failures with line numbers and detailed error messages
- Run failing tests individually: `./agent_test.sh "TestSuite.testMethod"`
- Mock classes available in `tests/common/`
- Update parameter names when refactoring APIs

## Requirements
- **macOS**: Required for Xcode builds
- **Xcode**: Latest stable version
- **Ruby**: For xcpretty (auto-installed)
- **iOS Simulator**: For testing

## Quick Start for AI Agents
1. Run `./agent_build.sh` to verify project builds
2. Run `./agent_test.sh` to check test health (or `./agent_test.sh TestSuite` for specific suite)
3. Make changes to source files
4. Re-run both scripts to validate
5. Debug failing tests: `./agent_test.sh "TestSuite.testMethod"`
6. Commit when both pass ✅

## Test Filtering Examples
```bash
# Debug specific failing tests
./agent_test.sh "IterableApiCriteriaFetchTests.testForegroundCriteriaFetchWhenConditionsMet"

# Run a problematic test suite
./agent_test.sh ValidateCustomEventUserUpdateAPITest

# Check auth-related tests
./agent_test.sh AuthTests
```

## Notes
- Always test builds after refactoring
- Parameter name changes require test file updates
- Project file (`*.pbxproj`) may need manual updates for file renames
- Sample apps demonstrate SDK usage patterns 
