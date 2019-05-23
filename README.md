[![CocoaPods](https://img.shields.io/cocoapods/v/Iterable-iOS-SDK.svg?style=flat)](https://cocoapods.org/pods/Iterable-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/Iterable-iOS-SDK.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.com/Iterable/swift-sdk.svg?branch=master)](https://travis-ci.com/Iterable/swift-sdk)

# Iterable iOS SDK

The Iterable iOS SDK is a Swift implementation of an iOS client for Iterable, for iOS versions 9.0 and higher.

## Before starting

Before you even start with the SDK, you will need to set up Iterable push notifications for your app.

For more information, read Iterable's [Setting up iOS Push Notifications](https://support.iterable.com/hc/articles/115000315806-Setting-Up-iOS-Push-Notifications) guide.
 
## Automatic installation (via CocoaPods)

Iterable supports [CocoaPods](https://cocoapods.org) for easy installation. If you don't have it yet, please refer to the CocoaPods [Getting Started](https://guides.cocoapods.org/using/getting-started.html) guide for installation instructions.

To install the Iterable Swift SDK using CocoaPods:

- Edit your project's **Podfile** and add the **Iterable-iOS-SDK** pod to 
your app target.
- If you'll be using media attachments on iOS push notifications, add the 
**Iterable-iOS-AppExtensions** pod to your project's extension target.

Example **Podfile**:

```ruby
platform :ios, '11.0'

# You must include the following line for both Objective-C and Swift
# projects. If you cannot use this option for your target, install
# the Iterable SDK in your project manually
use_frameworks!

target 'swift-sample-app' do
  pod 'Iterable-iOS-SDK'
end

target 'swift-sample-app-notification-extension' do
  pod 'Iterable-iOS-AppExtensions'
end
```

You you must include `use_frameworks!` in your **Podfile**, no matter if
your app is based on Swift or Objective-C. If you cannot use this in your 
project, install the SDK [manually](#manual-installation).

## Manual installation

Attached to the release you will find two framework bundles. 

```
IterableSDK.framework 
IterableAppExtensions.framework
```    
    
1. In Xcode, choose the target for your app. Now, add the **IterableSDK.framework** to the **Embedded Binaries** section. If you want to use an Iterable Rich Notification Extension, you will have to add **IterableAppExtensions.framework** to the embedded binaries section as well.

    ![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/embedded-binaries.png?raw=true)

2. If you want to use an Iterable Rich Notifiation Extension, you will need to add **IterableAppExtension.framework** to **Linked Frameworks and Libraries** section of your **app extension** target (not app target). Please note that you will have to add the **IterableAppExtension.framework** bundle to **both** the app target (step 1) and app extension target (step 2) of your project. In the app target, it goes in the **Embedded Binaries** section and in app extension target it goes in the **Linked Frameworks and Libraries** section.

    ![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/app-extension-linked-framework.png?raw=true)

3. In build settings, set **Always Embed Swift Standard Libraries** setting to **Yes**. This is necessary for both Swift and Objective-C projects.
    
    ![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/build-setting.png?raw=true)

## Sample projects

For sample projects, look at the following repositories:

- [Swift sample project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app?raw=true)
- [Objective-C sample project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/objc-sample-app?raw=true)

## Initializing the SDK

Follow these instructions to use the Iterable iOS SDK:

### 1. Import the IterableSDK module in your project

You need to import the **IterableSDK** module in order to use it. Import it in the top of your Swift or Obective-C files as shown below:

*Swift*

```swift
// In AppDelegate.swift file
// and any other file where you are using IterableSDK
import IterableSDK
```

*Objective-C*

```
// In AppDelegate.m file
// and any other file where you are using IterableSDK
@import IterableSDK;
```

### 2. Initialize the API with API key
    
In your app delegate, on application launch in the `application:didFinishLaunchingWithOptions:` method, initialize the Iterable SDK:
    
*Swift*
    
```swift
let config = IterableConfig()
config.pushIntegrationName = "<your-iterable-push-integration-name>"
IterableAPI.initialize(apiKey: "<your-api-key>", launchOptions: launchOptions, config:config)
```
    
*Objective-C*
    
```objc
IterableConfig *config = [[IterableConfig alloc] init];
config.pushIntegrationName = @"<your-iterable-push-integration-name>";
[IterableAPI initializeWithApiKey:@"<your-api-key>" launchOptions:launchOptions config:config]
```

For more information, read Iterable's [Setting up iOS Push Notifications](https://support.iterable.com/hc/articles/115000315806-Setting-Up-iOS-Push-Notifications) guide.
    
### 3. Set userId or email

Once you know the email or userId of the user, set the value.

> &#x26A0; Don't specify both email and userId in the same session, as they will be treated as different users by the SDK. Only use one type of identifier, email or userId, to identify the user.
*Swift*
    
```swift
IterableAPI.email = "user@example.com"
```

*Objective-C*

```objc
IterableAPI.email = @"user@example.com";
```
:::tip NOTE
Whenever the app sets `IterableAPI.email` or `IterableAPI.userId`, the SDK 
registers the device with Apple, retrieving a token that is stored
on the user's Iterable profile.
:::
    
## Using the SDK

### Push notifications

To work with push notifications, follow these steps:

1. Request authorization to receive push notifications

    iOS apps must request authorization to receive push notifications that
    will interact with the user (through alerts, sounds, or icon badging).

    To request authorization, Apple provides the [`requestAuthorization`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/1649527-requestauthorization)
    method on [`UNNotificationCenter`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter).

    Calling this method will prompt the user for permission to receive push
    notifications that involve user interaction.

    For example:

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

    For more information about setting iOS apps up to receive push 
    notifications, take a look at the following documents from Apple:
    
    - [UserNotifications framework](https://developer.apple.com/documentation/usernotifications)
    - [Asking Permission to Use Notifications](https://developer.apple.com/documentation/usernotifications/asking_permission_to_use_notifications)

2. Send a remote notification token to Iterable

    To send push notifications to your app, you will have to first send the application's remote notification token to Iterable.

    In your `AppDelegate`, in the [application:didRegisterForRemoteNotificationsWithDeviceToken:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application) method, send the token to Iterable.

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

3. Handle push notifications

    When the user taps on a push notification or one of its action buttons, the system calls the `UNUserNotificationCenterDelegate` object's [userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=swift). In this method, call `IterableAppIntegration` with the same parameters to track push open event and perform the associated action (see below for custom action and URL delegates).
        
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

    See the app delegate in the [example app](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app/swift-sample-app/AppDelegate.swift).

    Congratulations! You can now send remote push notifications to your device from Iterable. Please note that you can't send push notifications until you set the userId or email. Please see sample applications to see a reference implementation.

4. Handle rich push notifications

    Push notifications may contain media attachments with images, animated gifs or video, and action buttons. For this to work within your app, you must create a Notification Service Extension. For more information, read [Rich Push Notifications in iOS 10 and Android - Media Attachments](https://support.iterable.com/hc/articles/115003982203-Rich-Push-Notifications-in-iOS-10-and-Android-Media-Attachments).   

    The Iterable iOS SDK provides an implementation that handles media attachments and action buttons:

    - Include `Iterable-iOS-AppExtensions` in your **Podfile** as explained above.
    - Create a new target of type Notification Service Extension in your Xcode project.
    - If you are calling Iterable SDK from Swift, all you need to do is inherit the `NotificationService` class (auto generated by Xcode) from the `ITBNotificationServiceExtension` class. If you are using Objective-C, you will have to delegate to the provided implementation. See the example below:

    *Swift*

    ```swift
    import UserNotifications
    import IterableAppExtensions

    class NotificationService: ITBNotificationServiceExtension {
    }
    ```

    *Objective-C* 

    In Objective-C, use delegation instead of inheritance:

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

### Deep links

Deep linking allows a uniform resource identifier (URI) to link to a specific
location within your mobile app, rather than simply launching the app.

#### Handling links from push notifications

Push notifications and action buttons may have `openUrl` actions attached to them. When a URL is specified, the SDK first calls `urlDelegate` specified in your `IterableConfig` object. You can use this delegate to handle `openUrl` actions the same way as you handle normal deep links. If the delegate is not set or if it returns `false` (the default), the SDK will open Safari with that URL. If you want to navigate to a UIViewController on receiving a deep link, you should do so in the `urlDelegate`. 
   
In the code below, `DeepLinkHandler` is a custom handler which is reponsible for deep link navigation. You have to provide implementation for deep link navigation. Please see [sample application](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app?raw=true) for a reference implementation.
    
*Swift*
    
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    ...
    // Initialize Iterable API
    let config = IterableConfig()
    ...
    config.urlDelegate = self
    IterableAPI.initialize(apiKey: apiKey, launchOptions:launchOptions, config: config)
    ...
}

// Iterable URL Delegate. It will be called when you receive 
// an `openUrl` event from push notification.
func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
    return DeeplinkHandler.handle(url: url)
}
```
    
*Objective-C*
    
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ...
    // Initialize Iterable SDK
    IterableConfig *config = [[IterableConfig alloc] init];
    ...
    config.urlDelegate = self;
    [IterableAPI initializeWithApiKey:@"YOUR API KEY" launchOptions:launchOptions config:config];
    ...
}

- (BOOL)handleIterableURL:(NSURL *)url context:(IterableActionContext *)context {
    // Assuming you have a DeeplinkHandler class that handles all deep link URLs and navigates to the right place in the app
    return [DeeplinkHandler handleUrl:url];
}
```
    
#### Handling email links
    
For Universal Links to work with link rewriting in emails, you need to set up apple-app-site-association file in the Iterable project. More instructions here: [Setting up iOS Universal Links](https://support.iterable.com/hc/en-us/articles/115000440206-Setting-up-iOS-Universal-Links).

When an email link is clicked your `UIApplicationDelegate`'s [application:continueUserActivity:restorationHandler:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application?language=swift) method is called. If you already have an Iterable `urlDelegate` defined (see *Handling Links from Push Notifications* section above), the same handler can be used for email deep links by calling `handleUniversalLink:`.

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
    
Alternatively, call `getAndTrackDeeplink` along with a callback to handle the original deeplink url. You can use this method for any incoming URLs, as it will execute the callback without changing the URL for non-Iterable URLs.

*Swift*
    
```swift
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    guard let url = userActivity.webpageURL else {
    return false
    }

    IterableAPI.getAndTrack(deeplink: url) { (originalUrl) in
    // Handle original url deeplink here
    }
    return true
}
```

*Objective-C*

```objc
- (BOOL)application:(UIApplication *)application
    continueUserActivity(NSUserActivity *)userActivity 
    restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {

    [IterableAPI getAndTrackDeeplink:iterableLink callbackBlock:^(NSString* originalURL) {
    //Handle Original URL deeplink here
    }];

    return true;
}
```
    
### In-app messages

To display the user's in-app messages, call `spawnInAppNotification` with a defined `ITEActionBlock` callback handler. When a user clicks a button on the message, the defined handler is called and passed the action name defined in the in-app template.
    
In-app opens and button clicks are automatically tracked when the message is called via `spawnInAppNotification`. Using `spawnInAppNotification`, the message is consumed and removed from the user's in-app messages queue. If you want to retain the messages on the queue, look at using `getInAppMessages` directly. If you use `getInAppMessages` you will need to manage the in-app opens manually in the callback handler.    

### Custom events

Custom events can be tracked using `IterableAPI.track(event:...)` calls.
    
### User fields

User fields can be modified using `IterableAPI.updateUser` call. You also have `updateEmail` and `updateSubscriptions` methods.
    
### Disabling push notifications to a device

When a user logs out, you typically want to disable push notifications to that user/device. This can be accomplished by calling `disableDeviceForCurrentUser`. Please note that it will only attempt to disable the device if you have previously called `registerToken`.
    
In order to re-enable push notifcations to that device, simply call `registerToken` as usual when the user logs back in.
    
### Uninstall tracking

Iterable will track uninstalls with no additional work by you. 

This is implemented by sending a second push notification some time (currently, twelve hours) after the original campaign. If we receive feedback that the device's token is no longer valid, we assign an uninstall to the device, attributing it to the most recent campaign within twelve hours. A "real" campaign send (as opposed to the later "ghost" send) can also trigger recording an uninstall. In this case, if there was no previous campaign within the attribution period, an uninstall will still be tracked, but it will not be attributed to any campaign.
    
## Additional information

See our [setup guide](https://support.iterable.com/hc/en-us/articles/115000315806-Setting-Up-iOS-Push-Notifications) for more information.

Also see our [push notification setup FAQs](http://support.iterable.com/hc/en-us/articles/206791196-Push-Notification-Setup-FAQ-s).

## License

The MIT License

See [LICENSE](https://github.com/Iterable/swift-sdk/blob/master/LICENSE?raw=true)

## Want to contribute?

This library is open source, and we will look at pull requests!

See [CONTRIBUTING](CONTRIBUTING.md) for more information.
