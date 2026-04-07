# Iterable Swift SDK - Architecture

## Overview

The Iterable Swift SDK provides iOS applications with push notifications, in-app messaging, inbox, embedded messaging, event tracking, and user management capabilities. It communicates with the Iterable API to deliver personalized marketing experiences.

## Directory Structure

```
swift-sdk/
  Core/           Public-facing protocols, models, and constants
  SDK/            Public API surface (IterableAPI, IterableConfig, etc.)
  Internal/       Implementation details (not exposed to consumers)
    api-client/   Network request creation and processing
    in-app/       In-app message fetching, display, and lifecycle
    Network/      Low-level networking (connectivity, monitoring)
    Utilities/    Dependency injection, helpers, keychain
  ui-components/
    uikit/        UIKit inbox and embedded message views
    swiftui/      SwiftUI wrappers for inbox views
  Resources/      CoreData model and other bundled resources

notification-extension/   Rich push notification service extension
tests/
  unit-tests/             Unit tests
  ui-tests/               UI automation tests
  endpoint-tests/         API endpoint integration tests
  common/                 Shared test utilities and mocks
sample-apps/              Example applications
```

## Key Components

### Public API Layer (`SDK/`)

- **IterableAPI** (`IterableAPI.swift`): Static facade for all SDK functionality. Consumers call methods like `IterableAPI.initialize()`, `IterableAPI.track()`, `IterableAPI.setEmail()`, etc.
- **IterableConfig** (`IterableConfig.swift`): Configuration object passed at initialization. Controls push registration, in-app behavior, auth, data region, and more.
- **IterableMessaging** (`IterableMessaging.swift`): In-app and inbox data models (messages, triggers, content types).

### Internal Implementation (`Internal/`)

- **InternalIterableAPI** (`InternalIterableAPI.swift`): Core implementation behind `IterableAPI`. Manages initialization, auth state, user identity (email/userId), and coordinates subsystems.

### Request Pipeline (`Internal/api-client/`)

Requests flow through a layered pipeline:

1. **IterableAPI** (public) calls **InternalIterableAPI**
2. **InternalIterableAPI** calls **RequestHandler**
3. **RequestHandler** delegates to either **OnlineRequestProcessor** (immediate network) or **OfflineRequestProcessor** (queued via CoreData)
4. **OnlineRequestProcessor** uses **ApiClient** which uses **RequestCreator** to build HTTP requests
5. **NetworkHelper** / **NetworkSession** execute the actual HTTP calls

Key files:
- `RequestHandler.swift`: Routes requests to online/offline processors
- `OnlineRequestProcessor.swift`: Sends requests immediately
- `RequestCreator.swift`: Builds URL requests with proper paths, headers, and bodies
- `ApiClient.swift` / `ApiClientProtocol.swift`: Typed API methods

### Authentication (`Internal/Auth*.swift`)

- **AuthManager**: Handles JWT token lifecycle, refresh, retry with configurable policy
- Tokens stored in Keychain via `IterableKeychain`
- Auth failures trigger delegate callbacks (`IterableAuthDelegate`)

### In-App Messaging (`Internal/in-app/`)

- **InAppManager**: Central coordinator. Fetches messages, merges with local state, decides when to show, handles clicks.
- **InAppFetcher**: Calls the API to get in-app messages
- **InAppDisplayer**: Resolves the top view controller and presents the HTML message
- **InAppPresenter**: Manages presentation timing (delay for webview load)
- **InAppPersistence**: Stores messages locally (file or in-memory based on config)
- **IterableHtmlMessageViewController**: WKWebView-based message renderer

### Inbox UI (`ui-components/`)

- **IterableInboxViewController**: UITableViewController subclass for inbox
- **IterableInboxNavigationViewController**: Navigation wrapper
- **InboxViewControllerViewModel**: MVVM view model driving the inbox
- **IterableInboxViewControllerViewDelegate**: Protocol for customizing display

### Embedded Messaging

- **IterableEmbeddedManager**: Manages embedded message lifecycle
- **EmbeddedMessagingProcessor** / **EmbeddedMessagingSerialization**: Processing and serialization

### Persistence

- **CoreData**: Used for offline task queue (`IterableTaskManagedObject`)
- **IterableUserDefaults**: Lightweight key-value storage for SDK state
- **IterableKeychain**: Secure storage for auth tokens

### Dependency Injection (`Internal/Utilities/`)

- **DependencyContainerProtocol**: Defines factory methods for all major subsystems
- **DependencyContainer**: Production implementation
- Enables test doubles via protocol conformance

### Networking

- **NetworkMonitor**: Wraps `NWPathMonitor` for connectivity changes
- **NetworkConnectivityManager** / **NetworkConnectivityChecker**: Higher-level connectivity abstractions
- **NetworkHelper**: HTTP request execution with retry and auth refresh

### Unknown User Tracking

- **UnknownUserManager**: Tracks events before a user is identified
- Supports merging unknown user data when identity is established

## Data Flow Examples

### SDK Initialization
```
App -> IterableAPI.initialize(apiKey, config)
    -> InternalIterableAPI.init(apiKey, config, dependencyContainer)
        -> AuthManager created
        -> RequestHandler created (online + optional offline processor)
        -> InAppManager created and started (fetches messages)
        -> EmbeddedManager created if enabled
```

### Sending a Track Event
```
App -> IterableAPI.track(event:)
    -> InternalIterableAPI.track(event:)
        -> RequestHandler.track(event:)
            -> OnlineRequestProcessor.track(event:)
                -> ApiClient.track(event:) [builds request via RequestCreator]
                    -> NetworkHelper.sendRequest() [HTTP POST]
```

### In-App Message Display
```
App foreground -> InAppManager.onAppEnteredForeground()
    -> scheduleSync()
        -> InAppFetcher.fetch() [API call]
        -> mergeMessages() [reconcile server + local]
        -> processAndShowMessage()
            -> MessagesProcessor.processMessages() [apply delegate, filters]
            -> InAppDisplayer.showInApp()
                -> InAppPresenter.show() [delayed presentation]
                    -> topViewController.present(htmlMessageVC)
```

## Threading Model

- Public API calls are expected on the main thread
- InAppManager uses dedicated serial queues: `UpdateQueue`, `ScheduleQueue`, `CallbackQueue`, `SyncQueue`
- CoreData operations use background contexts
- Network callbacks are dispatched appropriately

## Configuration

All SDK behavior is configured via `IterableConfig`:
- Push integration names and platform
- URL/action/in-app delegates
- Auth delegate and retry policy
- In-app display interval and sync interval
- Data region (US/EU)
- Feature flags (unknown user, embedded messaging, etc.)
