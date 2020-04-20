[![License](https://img.shields.io/cocoapods/l/Iterable-iOS-SDK.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.com/Iterable/swift-sdk.svg?branch=master)](https://travis-ci.com/Iterable/swift-sdk)
[![pod](https://badge.fury.io/co/Iterable-iOS-SDK.svg)](https://cocoapods.org/pods/Iterable-iOS-SDK)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Iterable iOS SDK

The Iterable iOS SDK is a Swift implementation of an iOS client for Iterable, for iOS versions 9.0 and higher.

## Table of contents

- [Before starting](#before-starting)
- [Installation](#installation)
- [Sample projects](#sample-projects)
- [Configuring the SDK](#configuring-the-sdk)
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

## Installation

- [Installation and setup of the iOS SDK](https://support.iterable.com/hc/articles/360035018152)

## Sample projects

This repository contains the following sample projects:

- [Swift sample project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app)
- [Objective-C sample project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/objc-sample-app)
- [Inbox Customization](https://github.com/Iterable/swift-sdk/tree/master/sample-apps/inbox-customization)

## Configuring the SDK

Follow these instructions to configure the Iterable iOS SDK:

### 1. Import the IterableSDK module

To use the **IterableSDK** module, import it at the top of your Objective-C
or Swift files:

*Swift*

```swift
// In AppDelegate.swift file
// and any other file where you are using IterableSDK
import IterableSDK
```

*Objective-C*

```objc
// In AppDelegate.m file
// and any other file where you are using IterableSDK
@import IterableSDK;
```

### 2. Set an API key
    
In the `application:didFinishLaunchingWithOptions:` method of your app 
delegate, call `initialize(apiKey:launchOptions:config:)`, passing in your 
Iterable API key:
    
*Swift*
    
```swift
let config = IterableConfig()
IterableAPI.initialize(apiKey: "<your-api-key>", launchOptions: launchOptions, config: config)
```
    
*Objective-C*
    
```objc
IterableConfig *config = [[IterableConfig alloc] init];
[IterableAPI initializeWithApiKey:@"<your-api-key>" launchOptions:launchOptions config:config]
```

> &#x26A0; In prior versions of the SDK, it was necessary to explicitly set the 
> `IterableAPI.pushIntegrationName` property. This property now defaults to 
> the bundle ID of the app, so it's no longer necessary modify it unless you're
> using a custom integration name (different from the bundle ID). To view your 
> existing integrations, navigate to **Settings > Mobile Apps**.

### 3. Set a userId or email

Once you have an email address or user ID for your app's current user, set
`IterableAPI.email` or `IterableAPI.userId`. For example:

> &#x26A0; Don't specify both `email` and `userId` in the same session, as they will be treated as different users by the SDK. Only use one type of identifier, `email` or `userId`, to identify the user.

*Swift*
    
```swift
IterableAPI.email = "user@example.com"
```

*Objective-C*

```objc
IterableAPI.email = @"user@example.com";
```

Your app will not be able to receive push notifications until you set 
one of these values.

### 4. Fetch a device token from Apple

For Iterable to send push notifications to an iOS device, it must know the
unique token assigned to that device by Apple.

Iterable uses silent push notifications to tell iOS apps when to fetch
new in-app messages from the server. Because of this, your app must register
for remote notifications with Apple even if you do not plan to send it any
push notifications.

`IterableConfig.autoPushRegistration` determines whether or not the SDK will:

- Automatically register for a device token when the the SDK is given a new 
email address or user ID.
- Disable the device token for the previous user when a new user logs in.

If `IterableConfig.autoPushRegistration` is `true` (the default value):

- Setting `IterableAPI.email` or `IterableAPI.userId` causes the SDK to 
automatically call the [`registerForRemoteNotifications()`](https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications)
method on `UIApplication` and pass the resulting device token to the
[`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application)
method on the app delegate.

If `IterableConfig.autoPushRegistration` is `false`:

- After setting `IterableAPI.email` or `IterableAPI.userId`, you must 
manually call the [`registerForRemoteNotifications()`](https://developer.apple.com/documentation/uikit/uiapplication/1623078-registerforremotenotifications)
method on `UIApplication`. This will fetch the device token from Apple and 
pass it to the [`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application)
method on the app delegate.

### 5. Send the device token to Iterable

To send the device token to Iterable and save it on the current user's
profile, call `IterableAPI.register(token:)` from the 
[`application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application)
method on `UIApplicationDelegate`. For example:

*Swift*
        
```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    IterableAPI.register(token: deviceToken)
}
```
    
*Objective-C*
        
```objc
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [IterableAPI registerToken:deviceToken];
}
```

### 6. (Optional) Request authorization to display push notifications

If you are planning to send push notifications to your app, complete the 
steps in this section.

iOS apps must receive user permission to display push notification alerts,
play push notification sounds, or update icon badges based on push 
notifications. If you are planning to send these types of push notifications,
call Apple's [`requestAuthorization`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/1649527-requestauthorization)
method on [`UNNotificationCenter`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter). 
to prompt the user for these permissions.

*Swift*

```swift
UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .badge, .sound]) { (success, error) in
    // ...
}
```

*Objective-C*

```objc
UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
[center requestAuthorizationWithOptions: (UNAuthorizationOptionAlert + UNAuthorizationOptionBadge + UNAuthorizationOptionSound)
   completionHandler:^(BOOL granted, NSError * _Nullable error) {
   // ...
}];
```

For more information, take a look at the following documents from Apple:

- [UserNotifications framework](https://developer.apple.com/documentation/usernotifications)
- [Asking Permission to Use Notifications](https://developer.apple.com/documentation/usernotifications/asking_permission_to_use_notifications)

### 7. (Optional) Configure support for rich push notifications

For push notifications to contain images, animated GIFs, video, or action
buttons, you must create a Notification Service Extension.

The Iterable iOS SDK provides a Notification Service Extension implementation 
that handles media attachments and action buttons. To use it:

- Include **Iterable-iOS-AppExtensions** in your **Podfile**, as explained 
above.
- Create a new target of type **Notification Service Extension** in your 
Xcode project.
- If you are calling Iterable SDK from Swift, edit the `NotificationService`
class (auto-generated by Xcode) so that it extends 
`ITBNotificationServiceExtension`.
- If you are using Objective-C, use delegation instead of inheritance.

For example:

*Swift*

With Swift, use inheritance:

```swift
import UserNotifications
import IterableAppExtensions

class NotificationService: ITBNotificationServiceExtension {
    // ...
}
```

*Objective-C* 

With Objective-C, use delegation:

```objc
// File: NotificationService.m 
#import "NotificationService.h"

@import IterableAppExtensions;

@interface NotificationService ()

@property (nonatomic, strong) ITBNotificationServiceExtension *baseExtension;
@end

@implementation NotificationService
- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.baseExtension = [[ITBNotificationServiceExtension alloc] init];
    [self.baseExtension didReceiveNotificationRequest:request withContentHandler:contentHandler];
}

- (void)serviceExtensionTimeWillExpire {
    [self.baseExtension serviceExtensionTimeWillExpire];
}
@end

```

### 6. Disable push notifications when necessary

When a new user logs in to your app on the same device that a previous user
had been using, you'll typically want to disable push notifications to the
previous user (for that app/device combination only). 

If `IterableConfig.autoPushRegistration` is `true` (the default value), the 
SDK automatically disables push notifications to the previous user when you 
provide a new value for `IterableAPI.email` or `IterableAPI.userId`.

If `IterableConfig.autoPushRegistration` is `false`, or if you need to
disable push notifications for a user before a new user logs in to your app,
manually call `IterableAPI.disableDeviceForCurrentUser()`. This method only 
works if you have previously called `IterableAPI.register(token:)`.

If the previous user logs back in later, call `IterableAPI.register(token:)` 
to again register that user for push notifications on that app/device
combination.

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
