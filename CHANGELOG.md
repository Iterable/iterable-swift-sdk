# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
#### Added
- nothing yet

#### Removed
- nothing yet

#### Changed
- nothing yet

#### Fixed
- nothing yet

## [6.0.2](https://github.com/Iterable/swift-sdk/releases/tag/6.0.1)
#### Added
- You can now set `logHandler` in IterableConfig.
- Now you don't have to call `IterableAPI.registerToken` on login/logout.


#### Fixed
- Don't show in-app message if one is already showing.


## [6.0.1](https://github.com/Iterable/swift-sdk/releases/tag/6.0.1)

#### Fixed
- Fixed issue that affects clients who are upgrading from Objective C Iterable SDK to Swift SDK. If you have attribution info stored in the previous Objective C SDK, it was not being deserialized in Swift SDK.

