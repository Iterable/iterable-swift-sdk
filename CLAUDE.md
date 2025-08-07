# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Iterable Swift SDK** - a production mobile SDK for iOS that enables apps to integrate with Iterable's marketing automation platform. The SDK handles push notifications, in-app messages, embedded messages, deep linking, and user tracking for thousands of iOS applications.

## Common Development Commands

### Building the SDK
```bash
# Build the main SDK framework
xcodebuild build -project swift-sdk.xcodeproj -scheme swift-sdk -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Create XCFramework for distribution
fastlane build_xcframework output_dir:./build
```

### Testing
```bash
# Run full test suite with code coverage
xcodebuild test -project swift-sdk.xcodeproj -scheme swift-sdk -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' -enableCodeCoverage YES

# Run unit tests only
xcodebuild test -project swift-sdk.xcodeproj -scheme swift-sdk -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:unit-tests

# Run integration tests (requires API credentials)
./tests/endpoint-tests/scripts/run_test.sh

# CocoaPods validation
pod lib lint --allow-warnings
```

### Sample Apps
```bash
# Build and run Swift sample app
xcodebuild build -project sample-apps/swift-sample-app/swift-sample-app.xcodeproj -scheme swift-sample-app -sdk iphonesimulator

# Build inbox customization samples
xcodebuild build -project sample-apps/inbox-customization/inbox-customization.xcodeproj -scheme inbox-customization -sdk iphonesimulator
```

## Code Architecture

### Public API Structure
- **`SDK/IterableAPI.swift`** - Main SDK facade with static methods for initialization and core functionality
- **`SDK/IterableConfig.swift`** - Configuration object with delegate protocols for customization
- **`SDK/IterableAppIntegration.swift`** - Integration points for push notifications and app lifecycle
- **`SDK/IterableLogging.swift`** - Logging infrastructure
- **`SDK/IterableMessaging.swift`** - Messaging-related public APIs

### Core Internal Architecture
- **`Internal/api-client/`** - HTTP client layer with offline/online request processing
- **`Internal/in-app/`** - Complete in-app messaging system (fetch, display, persistence, tracking)
- **`Internal/Network/`** - Network session management and connectivity monitoring
- **`Internal/Utilities/`** - Core utilities including dependency injection, storage, and security

### Key Architectural Patterns
- **Protocol-oriented design** - Heavy use of protocols for abstraction and testability
- **Dependency injection** - Central IoC container in `DependencyContainer.swift`
- **Async/Future pattern** - Custom implementation in `Pending.swift` for consistent async handling
- **Task management** - Persistent task queue using Core Data for offline operation
- **Observer pattern** - Extensive NotificationCenter usage for decoupled communication

### Feature Organization
- **Push Notifications**: `IterableAppIntegration.swift`, `NotificationHelper.swift`, `APNSTypeChecker.swift`
- **In-App Messages**: Modular system in `Internal/in-app/` with separate concerns
- **Inbox**: UI components in `ui-components/` with both UIKit and SwiftUI implementations
- **Embedded Messages**: Separate from in-app, designed for app UI integration
- **Authentication**: `AuthManager.swift` with JWT token handling and Keychain storage

## Testing Infrastructure

### Test Suites
- **Unit tests** (`tests/unit-tests/`) - Core business logic with comprehensive mocks
- **UI tests** (`tests/ui-tests/`) - XCUITest-based UI interaction testing  
- **Inbox UI tests** (`tests/inbox-ui-tests/`) - Specialized inbox functionality testing
- **Offline events tests** (`tests/offline-events-tests/`) - Network and offline mode testing
- **Integration tests** (`tests/endpoint-tests/`) - End-to-end API testing with real backend

### Test Execution
- Uses XCTest framework with expectation-based async testing
- Comprehensive mock objects in `tests/common/` for external dependencies
- Code coverage enabled and reported to Codecov
- CI/CD runs on GitHub Actions with macOS-15 and latest Xcode

## Development Workflow

### Package Management
- **Swift Package Manager** - Primary distribution method via `Package.swift`
- **CocoaPods** - Legacy support via `.podspec` files
- **Fastlane** - Release automation and XCFramework creation

### Version Management
- iOS 10+ minimum deployment (Swift Package Manager)
- iOS 12+ minimum deployment (CocoaPods)
- Swift 5.3+ language requirement
- Xcode latest-stable for CI/CD

### Release Process
```bash
# Automated release via Fastlane
fastlane release_sdk

# Manual version bump
fastlane bump_release_version version:6.5.13

# Clean and validate
fastlane clean_and_lint
```

## Key SDK Concepts

### Initialization
```swift
// Standard initialization
IterableAPI.initialize(apiKey: "your-api-key")

// With configuration
let config = IterableConfig()
config.pushIntegrationName = "your-integration"
config.inAppDelegate = self
IterableAPI.initialize(apiKey: "your-api-key", config: config)
```

### User Management
- User identification via email or userId
- Profile updates and custom fields
- Commerce tracking with `CommerceItem` models

### Message Types
- **Push notifications** - Standard iOS push with custom payloads
- **In-app messages** - Full-screen overlays triggered by events or campaigns
- **Embedded messages** - Content embedded within app UI
- **Inbox messages** - Persistent message center functionality

### Deep Linking
- Universal Links support with associated domains
- Custom URL scheme handling
- Deep link attribution and tracking

## Important Files for SDK Development

### Core SDK Files
- `swift-sdk/SDK/IterableAPI.swift` - Main public interface
- `swift-sdk/Internal/InternalIterableAPI.swift` - Internal implementation
- `swift-sdk/Internal/api-client/ApiClient.swift` - Network client
- `swift-sdk/Internal/DependencyContainer.swift` - Dependency injection

### Configuration Files
- `Package.swift` - Swift Package Manager configuration
- `Iterable-iOS-SDK.podspec` - CocoaPods specification
- `fastlane/Fastfile` - Release automation scripts

### Sample Applications
- `sample-apps/swift-sample-app/` - Basic Swift integration example
- `sample-apps/objc-sample-app/` - Objective-C integration example
- `sample-apps/inbox-customization/` - Advanced inbox customization examples
- `sample-apps/swiftui-sample-app/` - SwiftUI integration example

## Testing Best Practices

- Use mocks from `tests/common/` for external dependencies
- Follow async testing patterns with `XCTestExpectation`
- Run full test suite before submitting changes
- Integration tests require API credentials via environment variables
- Maintain test isolation and avoid shared state between tests