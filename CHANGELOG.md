# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [6.0.8](https://github.com/Iterable/swift-sdk/releases/tag/6.0.8)
#### Fixed
- set preferUserId to true when using updateUser using userId

## [6.0.8](https://github.com/Iterable/swift-sdk/releases/tag/6.0.8)
#### Fixed
- Carthage support with Xcode 10.2

## [6.0.7](https://github.com/Iterable/swift-sdk/releases/tag/6.0.7)
#### Fixed
- XCode 10.2 Warnings
- URL Query parameters encoding bug

## [6.0.6](https://github.com/Iterable/swift-sdk/releases/tag/6.0.6)
#### Added
- Update to Swift 4.2

## [6.0.5](https://github.com/Iterable/swift-sdk/releases/tag/6.0.5)
#### Fixed
- Carthage support

## [6.0.4](https://github.com/Iterable/swift-sdk/releases/tag/6.0.4)
#### Added
- More refactoring and tests.

#### Changed
- Now we do not call createUserForUserId when registering device. This is handled on the server side.

#### Fixed
- `destinationUrl` was not being returned correctly from the SDK when using custom schemes for inApp messages.


## [6.0.3](https://github.com/Iterable/swift-sdk/releases/tag/6.0.3)
#### Added
- Call createUserForUserId when registering a device with userId
- Refactoring and tests.


## [6.0.2](https://github.com/Iterable/swift-sdk/releases/tag/6.0.2)
#### Added
- You can now set `logHandler` in IterableConfig.
- Now you don't have to call `IterableAPI.registerToken` on login/logout.


#### Fixed
- Don't show in-app message if one is already showing.


## [6.0.1](https://github.com/Iterable/swift-sdk/releases/tag/6.0.1)

#### Fixed
- Fixed issue that affects clients who are upgrading from Objective C Iterable SDK to Swift SDK. If you have attribution info stored in the previous Objective C SDK, it was not being deserialized in Swift SDK.

## [Unreleased]
#### Added
- nothing yet

#### Removed
- nothing yet

#### Changed
- nothing yet

#### Fixed
- nothing yet

