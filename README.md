[![License](https://img.shields.io/cocoapods/l/Iterable-iOS-SDK.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.com/Iterable/swift-sdk.svg?branch=master)](https://travis-ci.com/Iterable/swift-sdk)
[![pod](https://badge.fury.io/co/Iterable-iOS-SDK.svg)](https://cocoapods.org/pods/Iterable-iOS-SDK)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Iterable iOS SDK

The Iterable iOS SDK is a Swift implementation of an iOS client for Iterable, for iOS versions 9.0 and higher.

## Table of contents

- [Before starting](#before-starting)
- [Installation](#installation)
    - [Swift Package Manager](#swift-package-manager)
    - [CocoaPods](#cocoapods)
    - [Carthage](#carthage)
    - [Manual Installation](#manual-installation)
    - [Beta versions](#beta-versions)
- [Migrating from a version prior to 6.1.0](#migrating-from-a-version-prior-to-610)
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
- [Want to Contribute?](#want-to-contribute)

## Before starting

Before starting with the SDK, you will need to set up Iterable push notifications for your app.

For more information, read Iterable's [Setting up iOS Push Notifications](https://support.iterable.com/hc/articles/115000315806) guide.

## Installation

To install this SDK, use [Swift Package Manager](https://swift.org/package-manager/) (through Xcode or command line),  [CocoaPods](https://cocoapods.org/), [Carthage](https://github.com/Carthage/Carthage), or install it manually.

### Swift Package Manager

In Xcode 11, Apple integrated the Swift Package Manager into Xcode—an
intuitive, easy way to add dependencies to your project.

1. To include Iterable's SDK, navigate in Xcode to **File** >
**Swift Packages** > **Add Package Dependency**.

2. Enter `https://github.com/iterable/swift-sdk` as the package repository URL.

3. Select the version of the SDK you'd like to install (the default settings
will be set to the latest stable version).

4. Select **IterableSDK**. If necessary for your use case, also select
**IterableAppExtensions**.

5. Click **Finish**.

### CocoaPods 

To use CocoaPods to install Iterable's iOS SDK, first [install CocoaPods](https://guides.cocoapods.org/using/getting-started.html).
Then, follow these steps:

1. If your project does not yet have a **Podfile**, create one.

    - In the terminal, navigate to the directory containing your project's
    .xcodeproj file 
    - Run the following command:

        ```
        pod init
        ```

2. Edit your project's **Podfile**.

    - Add the **Iterable-iOS-SDK** pod to your projec's app target. 

    - If your app will receive push notifications containing media
    attachments (images, etc.), add the **Iterable-iOS-AppExtensions** pod to 
    your project's Notification Service Extension target.

    After these changes, your **Podfile** should look similar to the 
    following:

    ```ruby
    platform :ios, '11.0'

    use_frameworks!

    target 'swift-sample-app' do
        pod 'Iterable-iOS-SDK'
    end

    target 'swift-sample-app-notification-extension' do
        pod 'Iterable-iOS-AppExtensions'
    end
    ```

    You must include `use_frameworks!` in your **Podfile**, no matter if
    your app is based on Swift or Objective-C. If your project cannot use 
    this option, install the SDK [manually](#manual-installation).

3. In the terminal, run the following command to install the SDK (and app 
extensions, if necessary):

    ```
    pod install
    ```

    This will create an .xcworkspace file. To open your project in Xcode,
    use this file instead of the .xcodeproj file.

For more information, take a look at the [CocoaPods](https://cocoapods.org/)
documentation.

### Carthage

To use Carthage to install the SDK, first [install Carthage](https://github.com/Carthage/Carthage#installing-carthage). 
Then, follow these steps:

1. If it does not yet exist, create a file named **Cartfile** in the same 
directory as your Xcode project.

2. Edit **Cartfile**, adding the following line:

    ```
    github "Iterable/swift-sdk"
    ```

3. In the terminal, in the same directory as your **Cartfile**, run the 
following command:

    ```
    carthage update
    ```

4. In Xcode, navigate to the **Build Phases** section for your app's target.
Click the **+** icon and select **New Run Script Phase**. A **Run Script** 
section will appear.

5. In the **Run Script** section, below the **Shell** input, add the 
following command: 

    ```
    /usr/local/bin/carthage copy-frameworks
    ```

6. In the **Input Files** section, click **+** and add the following path:

    ```
    $(SRCROOT)/Carthage/Build/iOS/IterableSDK.framework
    ```

7. In the **Output Files** section, add the path to the copied framework:

    ```
    $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/IterableSDK.framework
    ```

8. Add **&lt;Xcode project directory&gt;/Carthage/Build/iOS/IterableSDK.framework** 
to your Xcode project by dragging it into the Xcode Project Navigator.
When prompted by Xcode, add the framework to your app's target.

9. If your app will be using push notifications that contain media
attachments (images, etc.), repeat steps 6 through 8, substituting
**IterableAppExtensions.framework** for **IterableSDK.framework**. In step 8, 
add **IterableAppExtensions.framework** to your project's Notification
Service Extension target (instead of the app target).

For more information, take a look at the [Carthage](https://github.com/Carthage/Carthage)
documentation.

### Manual installation

Attached to the release, you will find two framework bundles: 
**IterableSDK.framework** and **IterableAppExtensions.framework**.
    
1. In Xcode, choose the target for your app. Now, add the **IterableSDK.framework** to the **Embedded Binaries** section. If you want to use an Iterable Rich Notification Extension, you will have to add **IterableAppExtensions.framework** to the embedded binaries section as well.

    ![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/embedded-binaries.png?raw=true)

2. If you want to use an Iterable Rich Notification Extension, you will need to add **IterableAppExtension.framework** to **Linked Frameworks and Libraries** section of your **app extension** target (not app target). Please note that you will have to add the **IterableAppExtension.framework** bundle to **both** the app target (step 1) and app extension target (step 2) of your project. In the app target, it goes in the **Embedded Binaries** section and in app extension target it goes in the **Linked Frameworks and Libraries** section.

    ![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/app-extension-linked-framework.png?raw=true)

3. In build settings, set **Always Embed Swift Standard Libraries** setting to **Yes**. This is necessary for both Swift and Objective-C projects.
    
    ![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/build-setting.png?raw=true)

### Beta versions

> &#x26A0; **IMPORTANT**
> Beta versions of this SDK are subject to Iterable's 
> [Beta Mobile SDK Terms of Service](https://support.iterable.com/hc/articles/360034753412).

To install a beta version of Iterable's iOS SDK, use CocoaPods or Carthage:

- CocoaPods

    Beta versions of the SDK are not pushed as normal releases to CocoaPods.
    Instead, point CocoaPods to the git tag associated with a specific build.
    For example, the following **Podfile** entry looks for the SDK build
    tagged with `6.2.0-beta1`:

    ```
    pod 'Iterable-iOS-SDK', :git => 'https://github.com/Iterable/swift-sdk.git', :tag => '6.2.0-beta1'
    ```

- Carthage

    Like CocoaPods, Carthage can install an SDK build associated with a
    specific git tag. For example, the following **Cartfile** entry looks for
    an SDK build tagged with `6.2.0-beta1`:

    ```
    github "Iterable/swift-sdk" ~> 6.2.0-beta1
    ```

## Migrating from a version prior to 6.1.0

- Versions 6.1.0+ of the SDK require Xcode 10.2 or higher.

- In-app messages: `spawnInAppNotification`

    - `spawnInAppNotification` is no longer needed and will fail to compile.
    The SDK now displays in-app messages automatically. For more information,
    see [In-app messages](#in-app-messages).

    - There is no need to poll the server for new messages.

- In-app messages: handling manually

    - To control when in-app messages display (rather than displaying them
    automatically), set `IterableConfig.inAppDelegate` (an 
    `IterableInAppDelegate` object). From its `onNew` method, return `.skip`.

    - To get the queue of available in-app messages, call
    `IterableApi.inAppManager.getMessages()`. Then, call
    `IterableApi.inAppManager.show(message)` to show a specific message.

    - For more details, see [In-app messages](#in-app-messages).

- In-app messages: custom actions

   - This version of the SDK reserves the `iterable://` URL scheme for
    Iterable-defined actions handled by the SDK and the `action://` URL
    scheme for custom actions handled by the mobile application's custom
    action handler. For more details, see 
    [Handling in-app message buttons and links](#handling-in-app-message-buttons-and-links).

    - If you are currently using the `itbl://` URL scheme for custom actions,
    the SDK will still pass these actions to the custom action handler.
    However, support for this URL scheme will eventually be removed (timeline
    TBD), so it is best to move to the `action://` URL scheme as it's 
    possible to do so.

- Consolidated deep link URL handling

    - By default, the SDK handles deep links with the the URL delegate
    assigned to `IterableConfig`. Follow the instructions in 
    [Deep Links](#deep-links) to migrate any existing URL handling code 
    to this new API.

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

When the user taps on a push notification or one of its action buttons, the
system calls the `UNUserNotificationCenterDelegate` object's
[userNotificationCenter(_:didReceive:withCompletionHandler:)](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=swift)
method. 

From this method, call the `userNotificationCenter(_:didReceive:withCompletionHandler:)`
method on `IterableAppIntegration`. This tracks a push open event and 
performs the associated action.

*Swift*
    
```swift
public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
}
```

*Objective-C*
    
```objc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [IterableAppIntegration userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}
```

For more information, see the app delegate in the [example app](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app/swift-sample-app/AppDelegate.swift).

### Deep links

A deep link is a URI that links to a specific location within your mobile 
app. The following sections describe how to work with deep links using
Iterable's iOS SDK.

#### Push notification deep links
    
Push notifications and action buttons may have `openUrl` actions attached to them. When a URL is specified, the SDK first calls the `urlDelegate` object specified on your `IterableConfig` object. You can use this delegate to handle `openUrl` actions the same way as you handle normal deep links. If the delegate is not set or if it returns `false` (the default), the SDK will open the URL with Safari. If, upon receiving a deep link, you want to navigate to a specific view controller in your app, do so in the `urlDelegate`. 
    
In the code below, `DeepLinkHandler` is a custom handler which is reponsible for deep link navigation. You have to provide an implementation for deep link navigation. Please see the [sample application](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app/swift-sample-app/DeeplinkHandler.swift) for a reference implementation for `DeepLinkHandler`.
    
*Swift*
    
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // ...
    // Initialize Iterable API
    let config = IterableConfig()
    // ...
    config.urlDelegate = self
    IterableAPI.initialize(apiKey: apiKey, launchOptions: launchOptions, config: config)
    // ...
}

// Iterable URL Delegate. It will be called when you receive 
// an `openUrl` event from push notification.
func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
    return DeepLinkHandler.handle(url: url)
}
```
    
*Objective-C*
    
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ...
    // Initialize Iterable SDK
    IterableConfig *config = [[IterableConfig alloc] init];
    // ...
    config.urlDelegate = self;
    [IterableAPI initializeWithApiKey:@"YOUR API KEY" launchOptions:launchOptions config:config];
    // ...
}
    
- (BOOL)handleIterableURL:(NSURL *)url context:(IterableActionContext *)context {
    // Assuming you have a DeepLinkHandler class that handles all deep link URLs and navigates to the right place in the app
    return [DeepLinkHandler handleUrl:url];
}
```
        
#### Email deep links
    
For Universal Links to work with email link rewriting, 
[set up an **apple-app-site-association** file](https://support.iterable.com/hc/articles/115000440206)
in your Iterable project.

When a user clicks a link in an email, the SDK will call the
[application(_:continue:restorationHandler:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application?language=swift)
method of your `UIApplicationDelegate`. If you already have an Iterable
`urlDelegate` defined (see [Handling Links from Push Notifications](#push-notification-deep-links), 
the same handler can be used for email deep links by calling 
`handle(universalLink:)`).

*Swift*
    
```swift
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    guard let url = userActivity.webpageURL else {
        return false
    }

    // This will track the click, retrieve the original URL and call `handleIterableURL:context:` with the original URL
    return IterableAPI.handle(universalLink: url)
}
```

*Objective-C*
    
```objc
- (BOOL)application:(UIApplication *)application continueUserActivity(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
    // This will track the click, retrieve the original URL and call `handleIterableURL:context:` with the original URL
    return [IterableAPI handleUniversalLink:userActivity.webpageURL];
}
```

#### Deferred deep linking

[Deferred deep linking](https://en.wikipedia.org/wiki/Deferred_deep_linking) allows a user who does not have a specific app installed to:

 - Click on a deep link that would normally open content in that app.
 - Install the app from the App Store.
 - Open the app and immediately see the content referenced by the link.
 
As the name implies, the deep link is _deferred_ until the app has been installed. 

After tapping a deep link in an email from an Iterable campaign, users without the associated app will be directed to the App Store to install it. If the app uses the Iterable iOS SDK and has deferred deep linking enabled, the content associated with the deep link will load on first launch.

Set `IterableConfig.checkForDeferredDeeplink` to `true` to enable deferred
deep linking with the Iterable iOS SDK.

### In-app messages

In-app messages are handled via silent push messages from the server. When your application receives a silent push, call the Iterable iOS SDK in your app delegate, as follows:

*Swift*

```swift
// In AppDelegate.swift
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    IterableAppIntegration.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
}
```

*Objective-C*

```objc
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [IterableAppIntegration application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}
```

#### Default behavior

By default, when an in-app message arrives from the server, the SDK automatically shows it if the app is in the foreground. If an in-app message is already showing when the new message arrives, the new in-app message will be shown 30 seconds after the currently displayed in-app message closes (see [how to change this default value](#changing-the-display-interval-between-in-app-messages)). Once an in-app message is shown, it will be "consumed" from the server queue and removed from the local queue as well. There is no need to write any code to get this default behavior. 

#### Overriding whether to show or skip a particular in-app message

An incoming in-app message triggers a call to the `onNew` method of `IterableConfig.inAppDelegate` (an object of type `IterableInAppDelegate`). To override the default behavior, set `IterableConfig.inAppDelegate` to a custom class that overrides the `onNew` method. `onNew` should return `.show` to show the incoming in-app message or `.skip` to skip showing it.

*Swift*

```swift
class YourCustomInAppDelegate : IterableInAppDelegate {
    func onNew(message: IterableInAppMessage) -> InAppShowResponse {
        // perform custom processing

        // ...
        
        return .show // or .skip
    }
}
    
// ...
    
let config = IterableConfig()
config.inAppDelegate = YourCustomInAppDelegate()
IterableAPI.initialize(apiKey: "YOUR API KEY",  launchOptions: nil, config: config)
```

*Objective-C*

```objc
// Implement this method in your custom class that implements IterableInAppDelegate
// This will most likely be the global AppDelegate class.
- (enum InAppShowResponse)onNewMessage:(IterableInAppMessage * _Nonnull)message {
    // perform custom processing
    
    // ...
    
    return InAppShowResponseShow; // or InAppShowResponseSkip
}

// ...
    
// Now set this custom class in IterableConfig
IterableConfig *config = [[IterableConfig alloc] init];
config.inAppDelegate = self; // or other class implementing the protocol
[IterableAPI initializeWithApiKey:@"YOUR API KEY" launchOptions:launchOptions config:config];
```

#### Getting the local queue of in-app messages

Until they are consumed by the app, all in-app messages that arrive from the server are stored in a local queue. To access this local queue, use the read-only `IterableAPI.inAppManager` property (an object which conforms to the `InAppManager` protocol). By default, all in-app messages in the local queue will be consumed and removed from this queue. To keep in-app messages around after they are shown, override the default behavior (as described above).
    
*Swift*
    
```swift
// Get the in-app messages list
let messages = IterableAPI.inAppManager.getMessages()
    
// Show an in-app message 
IterableAPI.inAppManager.show(message: message)
    
// Show an in-app message without consuming, i.e., not removing it from the queue
IterableAPI.inAppManager.show(message: message, consume: false)
    
```    
    
*Objective-C*
    
```objc
// Get the in-app messages list
NSArray *messages = [IterableAPI.inAppManager getMessages];
    
// Show an in-app message 
[IterableAPI.inAppManager showMessage:message];
    
// Show an in-app message without consuming, i.e., not removing it from the queue
[IterableAPI.inAppManager showMessage:message consume:NO callbackBlock:nil];
    
```    

#### Handling in-app message buttons and links

The SDK handles in-app message buttons and links as follows:

- If the URL of the button or link uses the `action://` URL scheme, the SDK
passes the action to `IterableConfig.customActionDelegate.handle()`. If 
`customActionDelegate` (an `IterableCustomActionDelegate` object) has not 
been set, the action will not be handled.

    - For the time being, the SDK will treat `itbl://` URLs the same way as
    `action://` URLs. However, this behavior will eventually be deprecated
    (timeline TBD), so it's best to migrate to the `action://` URL scheme
    as it's possible to do so.

- The `iterable://` URL scheme is reserved for action names predefined by
the SDK. If the URL of the button or link uses an `iterable://` URL known
to the SDK, it will be handled automatically and will not be passed to the
custom action handler.

    - The SDK does not yet recognize any `iterable://` actions, but may
    do so in the future.

- The SDK passes all other URLs to `IterableConfig.urlDelegate.handle()`. If
`urlDelegate` (an `IterableUrlDelegate` object) has not been set, or if it 
returns `false` for the provided URL, the URL will be opened by the system 
(using a web browser or other application, as applicable).

Take a look at [this sample code](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app/swift-sample-app/AppDelegate.swift) 
for a demonstration of how to implement and use the `IterableURLDelegate` and `IterableCustomActionDelegate` protocols.

The following code demonstrates how to assign a `urlDelegate` and
`customActionDelegate` to an `IterableConfig` object:

```swift
let config = IterableConfig()
config.urlDelegate = YourCustomUrlDelegate()
config.customActionDelegate = YourCustomActionDelegate()
```
    
#### Changing the display interval between in-app messages

To customize the time delay between successive in-app messages (default value of 30 seconds), set `IterableConfig.inAppDisplayInterval` to an appropriate value (in seconds).

### Mobile Inbox

Apps using version 6.2.0 and later of this SDK can allow users to save in-app
messages to an inbox. This inbox displays a list of saved in-app messages and
allows users to read them at their convenience. The SDK provides a default user
interface for the inbox, which can be customized to match your brand's styles.

To learn more about Mobile Inbox, how to customize it, and events related to
its usage, read:

- [In-App Messages and Mobile Inbox](https://support.iterable.com/hc/articles/217517406)
- [Sending In-App Messages](https://support.iterable.com/hc/articles/360034903151)
- [Events for In-App Messages and Mobile Inbox](https://support.iterable.com/hc/articles/360038939972)
- [Setting up Mobile Inbox on iOS](https://support.iterable.com/hc/articles/360039137271)
- [Customizing Mobile Inbox on iOS](https://support.iterable.com/hc/articles/360039091471)

### Custom events

To track custom events, use the following methods on `IterableAPI`:

- `track(event:)`
- `track(event:dataFields:)`
- `track(event:dataFields:onSuccess:onFailure:)`
    
### User fields

To update an Iterable's user profile fields, use the following methods on
`IterableAPI`:

- `updateUser(_:mergeNestedObjects:onSuccess:onFailure:)` 
- `updateEmail(_:onSuccess:onFailure:)`
- `updateSubscriptions(_:unsubscribedChannelIds:unsubscribedMessageTypeIds:)`
    
### Uninstall tracking

Iterable will track uninstalls with no additional work by you. 

To do this, Iterable sends a silent push notification some time (currently, 12 hours) after a campaign has been sent. Based on this silent push notification, if Iterable receives feedback that the device token is no longer valid, it assigns an uninstall to the device based on the prior campaign. Similarly, if a "real" campaign uncovers an invalid device token, it will also check for a prior (within 12 hours) campaign to mark as the cause for the uninstall. If there was no recent campaign, Iterable still tracks the uninstall, but does not attribute it to a campaign.

> &#x26A0; **IMPORTANT**
> Apple has changed the way device tokens expire, so they may take up to 8 days to detect if they are invalid. This does mean that uninstall tracking may not be accurately attributable to campaigns sent within that period of time.

## Additional information

For more information, read Iterable's [Mobile Developer Guides](https://support.iterable.com/hc/categories/360002288712).

## License

The MIT License

See [LICENSE](https://github.com/Iterable/swift-sdk/blob/master/LICENSE?raw=true)

## Want to contribute?

This library is open source, and we will look at pull requests!

See [CONTRIBUTING](CONTRIBUTING.md) for more information.
