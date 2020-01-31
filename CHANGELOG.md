# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## 6.1.5
#### Fixed
- Fixed in-apps where display types that were not `fullScreen` were not displaying properly or becoming unresponsive.

## 6.1.4
#### Fixed
- Fixed the function signature of the `updateSubscriptions` call (thanks, Conor!)
- Fixed `NoneLogDelegate` not being usable for `IterableConfig.logDelegate` (thanks, katebertelsen!)

## 6.1.3
#### Changed
- Converted a log message variable to be interpreted as an UTF8 String (thanks, chunkyguy!)
- Enabled BUILD_LIBRARY_FOR_DISTRIBUTION for better compatibility across development environments

## 6.1.2
#### Fixed
- Fixed a bug in token to hex conversion code.

## 6.1.1
#### Changed
- Use WKWebView instead of deprecated class UIWebView.
- Migrated all Objective C code to Swift.

## 6.1.0
#### Changed
- In this version we have changed the way we use in-app notifications. In-app messages are now being sent asynchronously and your code can control the order and time in which an in-app notification will be shown. There is no need to poll for new in-app messages. Please refer to the **in-app messages** section of README file for how to use in-app messages. If you are already using in-app messages, please refer to [migration guide](https://github.com/iterable/swift-sdk##migrating-from-a-version-prior-to-610) section of README file.

## 6.1.0-beta4
#### Changed
- Url scheme `iterable://` is reserved for Iterable internal actions. In an earlier beta version, the reserved url scheme was `itbl://` but we are not using that now. `itbl://` scheme is only there for backward compatibility and should not be used.
- Url scheme `action://` is for user custom actions.

## 6.1.0-beta3
#### Changed
- Increase number of in-app messages fetched from the server to 100.

## 6.1.0-beta2
#### Added
- Support for `action://your-custom-action-name` URL scheme for calling custom actions 
	- For example, to have `IterableCustomActionDelegate` call a custom `buyCoffee` action when a user taps on an in-app message's **Buy** button.
- Support for reserved `itbl://sdk-custom-action` scheme for SDK internal actions.
	- URL scheme `itbl://sdk-custom-action` is reserved for internal SDK actions. Do not use it for custom actions. 
	- For example, future versions of the SDK may allow buttons to call href `itbl://delete` to delete an in-app message.

#### Fixed
- Carthage support with Xcode 10.2
- XCode 10.2 Warnings
- URL Query parameters encoding bug

## 6.1.0-beta1
#### Added
- We have improved the in-app messaging implementation significantly. 
	- The SDK now maintains a local queue and keep it in sync with the server-side queue automatically.
	- Iterable servers now notify apps via silent push messages whenever the in-app message queue is updated.
	- In-app messages are shown by default whenever they arrive.
- It should be straightforward to migrate to the new implementation. There are, however, some breaking changes. Please see [migration guide](https://github.com/iterable/swift-sdk#Migrating-in-app-messages-from-the-previous-version-of-the-SDK) for more details.

#### Removed
- `spawnInAppNotification` call is removed. Please refer to migration guide mentioned above.

#### Changed
- You can now use `updateEmail` if the user is identified with either `email` or `userId`. Earlier you could only call `updateEmail` if the user was identified by `email`.
- The SDK now sets `notificationsEnabled` flag on the device to indicate whether notifications are enabled for your app.

#### Fixed
- nothing yet

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

