# CLAUDE.md

🤖 **AI Agent Instructions**

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

### Listing All Available Tests

# List all available test suites
```bash
./agent_test.sh --list
```

### 🧪 Running Tests
```bash
# Run all tests
./agent_test.sh

# Run specific test suite
./agent_test.sh IterableApiCriteriaFetchTests

# Run specific unit test (dot notation - recommended)
./agent_test.sh "IterableApiCriteriaFetchTests.testForegroundCriteriaFetchWhenConditionsMet"

# Run any specific test with path
./agent_test.sh "unit-tests/IterableApiCriteriaFetchTests/testForegroundCriteriaFetchWhenConditionsMet"
```
- Executes on iOS Simulator with accurate pass/fail reporting
- Returns exit code 0 for success, 1 for failures
- Shows detailed test counts and failure information
- `--list` shows all test suites with test counts
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

## AI Agent Memory System

### 🧠 Update Instructions for AI Agents
**IMPORTANT**: When you discover something useful while working on this codebase, update this README to help future AI agents. Add learnings to the sections below.

### 📍 Code Location Map
- **Auth Logic**: `swift-sdk/Internal/AuthManager.swift` (main auth manager), `swift-sdk/Internal/Auth.swift` (auth models)
- **API Calls**: `swift-sdk/Internal/api-client/ApiClient.swift` (main client), `swift-sdk/Internal/Network/NetworkHelper.swift` (networking)
- **Models**: `swift-sdk/Core/Models/` (all data structures - CommerceItem, IterableInAppMessage, etc.)
- **Main Entry**: `swift-sdk/SDK/IterableAPI.swift` (public API), `swift-sdk/Internal/InternalIterableAPI.swift` (core implementation)
- **Request Handling**: `swift-sdk/Internal/api-client/Request/` (online/offline processors)

### 🛠️ Common Task Recipes

**Add New API Endpoint:**
1. Add path constant to `swift-sdk/Core/Constants.swift` in `Const.Path`
2. Add method to `ApiClientProtocol.swift` and implement in `ApiClient.swift`
3. Create request in `swift-sdk/Internal/api-client/Request/RequestCreator.swift`
4. Add to `RequestHandlerProtocol.swift` and `RequestHandler.swift`

**Modify Auth Logic:**
- Main logic: `swift-sdk/Internal/AuthManager.swift`
- Token storage: `swift-sdk/Internal/Utilities/Keychain/IterableKeychain.swift`
- Auth failures: Handle in `RequestProcessorUtil.swift`

**Add New Model:**
- Create in `swift-sdk/Core/Models/YourModel.swift`
- Make it `@objcMembers public class` for Objective-C compatibility
- Implement `Codable` if it needs JSON serialization

### 🐛 Common Failure Solutions

**"Test X failed"** → Check test file in `tests/unit-tests/` - often parameter name mismatches after refactoring

**"Build failed: file not found"** → Update `swift-sdk.xcodeproj/project.pbxproj` to include new/renamed files

**"Auth token issues"** → Check `AuthManager.swift` and ensure JWT format is correct in tests

**"Network request fails"** → Check endpoint in `Constants.swift` and request creation in `RequestCreator.swift`

## Notes
- Always test builds after refactoring
- Parameter name changes require test file updates
- Project file (`*.pbxproj`) may need manual updates for file renames
- Sample apps demonstrate SDK usage patterns