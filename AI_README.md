# AI README - Iterable Swift SDK

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
./mac_agent_build.sh
```
- Validates compilation on iOS Simulator
- Shows build errors with context
- Requires macOS with Xcode

### 🧪 Running Tests  
```bash
./mac_agent_test.sh
```
- Runs full unit test suite
- Executes on iOS Simulator 
- Shows test failures and summary
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
1. Build first: `./mac_agent_build.sh`
2. Implement in `swift-sdk/Internal/` or `swift-sdk/SDK/`
3. Add tests in `tests/unit-tests/`
4. Verify: `./mac_agent_test.sh`

### Debugging Build Issues
- Build script shows compilation errors with file paths
- Check Xcode project references in `swift-sdk.xcodeproj/project.pbxproj`
- Verify file renames are reflected in project file

### Test Failures
- Test script shows specific failures with line numbers
- Mock classes available in `tests/common/`
- Update parameter names when refactoring APIs

## Requirements
- **macOS**: Required for Xcode builds
- **Xcode**: Latest stable version
- **Ruby**: For xcpretty (auto-installed)
- **iOS Simulator**: For testing

## Quick Start for AI Agents
1. Run `./mac_agent_build.sh` to verify project builds
2. Run `./mac_agent_test.sh` to check test health
3. Make changes to source files
4. Re-run both scripts to validate
5. Commit when both pass ✅

## Notes
- Always test builds after refactoring
- Parameter name changes require test file updates
- Project file (`*.pbxproj`) may need manual updates for file renames
- Sample apps demonstrate SDK usage patterns 
