[![License](https://img.shields.io/cocoapods/l/Iterable-iOS-SDK.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.com/Iterable/swift-sdk.svg?branch=master)](https://travis-ci.com/Iterable/swift-sdk)
[![pod](https://badge.fury.io/co/Iterable-iOS-SDK.svg)](https://cocoapods.org/pods/Iterable-iOS-SDK)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Iterable iOS SDK

The Iterable iOS SDK is a Swift implementation of an iOS client for Iterable, for iOS versions 9.0 and higher.

## Table of contents

- [Before starting](#before-starting)
- [Installation and Configuration](#installation-and-configuration)
- [Sample projects](#sample-projects)
- [Using the SDK](#using-the-sdk)
    - [Push notifications](#push-notifications)
    - [Deep links](#deep-links)
    - [In-app messages](#in-app-messages)
    - [Mobile inbox](#mobile-inbox)
    - [Custom events](#custom-events)
    - [User fields](#user-fields)
    - [Uninstall tracking](#uninstall-tracking)
- [Additional information](#additional-information)
- [License](#license)
- [Want to contribute?](#want-to-contribute)

## Before starting

Before starting with the SDK, you will need to set up Iterable push notifications for your app.

For more information, read Iterable's [Setting up iOS Push Notifications](https://support.iterable.com/hc/articles/115000315806) guide.

## Installation and Configuration

- [Installation and configuration of the iOS SDK](https://support.iterable.com/hc/articles/360035018152)

## Sample projects

This repository contains the following sample projects:

- [Swift sample project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app)
- [Objective-C sample project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/objc-sample-app)
- [Inbox Customization](https://github.com/Iterable/swift-sdk/tree/master/sample-apps/inbox-customization)

## Using the SDK

### Push notifications

- [Setting up iOS Push Notifications](https://support.iterable.com/hc/articles/115000315806)
- [Advanced iOS Push Notifications](https://support.iterable.com/hc/articles/360035451931)

### Deep links

A deep link is a URI that links to a specific location within your mobile 
app. The following sections describe how to work with deep links using
Iterable's iOS SDK.

- [Deep Links in Push Notifications](https://support.iterable.com/hc/articles/360035453971)
- [iOS Universal Links](https://support.iterable.com/hc/articles/360035496511)
- [Deferred deep linking](https://support.iterable.com/hc/articles/360035165872)

### In-app messages

- [In-App Messages on iOS](https://support.iterable.com/hc/articles/360035536791)

### Mobile Inbox

Apps using version 6.2.0 and later of this SDK can allow users to save in-app
messages to an inbox. This inbox displays a list of saved in-app messages and
allows users to read them at their convenience. The SDK provides a default user
interface for the inbox, which can be customized to match your brand's styles.

- [In-App Messages and Mobile Inbox](https://support.iterable.com/hc/articles/217517406)
- [Sending In-App Messages](https://support.iterable.com/hc/articles/360034903151)
- [Events for In-App Messages and Mobile Inbox](https://support.iterable.com/hc/articles/360038939972)
- [Setting up Mobile Inbox on iOS](https://support.iterable.com/hc/articles/360039137271)
- [Customizing Mobile Inbox on iOS](https://support.iterable.com/hc/articles/360039091471)

### Tracking custom events

- [Custom events](https://support.iterable.com/hc/articles/360035395671)
    
### User fields

- [Updating User Profiles](https://support.iterable.com/hc/articles/360035402611)
    
### Uninstall tracking

- [Uninstall tracking](https://support.iterable.com/hc/articles/205730229#uninstall)

## Additional information

For more information, read Iterable's [Mobile Developer Guides](https://support.iterable.com/hc/categories/360002288712).

## License

The MIT License

See [LICENSE](https://github.com/Iterable/swift-sdk/blob/master/LICENSE?raw=true)

## Want to contribute?

This library is open source, and we will look at pull requests!

See [CONTRIBUTING](CONTRIBUTING.md) for more information.
