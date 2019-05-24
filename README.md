[![CocoaPods](https://img.shields.io/cocoapods/v/Iterable-iOS-SDK.svg?style=flat)](https://cocoapods.org/pods/Iterable-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/Iterable-iOS-SDK.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.com/Iterable/swift-sdk.svg?branch=master)](https://travis-ci.com/Iterable/swift-sdk)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Iterable iOS SDK

`Iterable-iOS-SDK` is a Swift implementation of an iOS client for Iterable, for iOS versions 9.0 and higher.

# Before Starting

Before you even start with the SDK, you will need to setup Iterable push notifications for your app. 

For more information, see [Getting Started Guide](https://support.iterable.com/hc/en-us/articles/115000315806-Setting-Up-iOS-Push-Notifications). 
 
# Automatic Installation (via CocoaPods)

Iterable supports [CocoaPods](https://cocoapods.org) for easy installation. 
If you don't have it yet, please refer to the CocoaPods 
[Getting Started](https://guides.cocoapods.org/using/getting-started.html) 
guide for installation instructions.

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

You you must include `use_frameworks!` in your **Podfile**, no matter 
whether your app is based on Swift or Objective-C. If you cannot use this in 
your project, install the SDK [manually](#manual-installation).

# Manual Installation

Attached to the release you will find two framework bundles. 

	IterableSDK.framework 
	IterableAppExtensions.framework
	
1. In XCode choose the target for your app. Now add IterableSDK.framework to the **embedded binaries** section. If you want to use Iterable Rich Notification Extension, you will have to add IterableAppExtensions.framework to the embedded binaries section as well.

	![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/embedded-binaries.png?raw=true)

2. If you want to use Iterable Rich Notifiation Extension, you will need to add IterableAppExtension.framework to **Linked Frameworks and Libraries** section of your **app extension** target (not app target). Please note that you will have to add the IterableAppExtension.framework bundle to **both** the app target (step 1) and app extension target (step 2) of your project. In the app target it goes in the 'Embedded Binaries' section and in app extension target it goes in the 'Linked Frameworks and Libraries' section.

	![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/app-extension-linked-framework.png?raw=true)

3. In build settings, set `Always Embed Swift Standard Libraries` setting to 'Yes'. This is required for Objective C projects.
	
	![Linking](https://github.com/Iterable/swift-sdk/blob/master/images/build-setting.png?raw=true)
 

# Initializing the SDK
**Note:** Sample projects are included in this repo.
 
- [Swift Sample Project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app?raw=true)
- [ObjC Sample Project](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/objc-sample-app?raw=true)


1. ##### Initialize the API with API key.
	In your app delegate, on application launch in `application:didFinishLaunchingWithOptions:` method, initialize the Iterable SDK:

	Swift:

	```swift
	let config = IterableConfig()
	config.pushIntegrationName = "<your-iterable-push-integration-name>"
	IterableAPI.initialize(apiKey: "<your-api-key>", launchOptions: launchOptions, config:config)
	```
	
	Objective-C:

	```objective-c
	IterableConfig *config = [[IterableConfig alloc] init];
	config.pushIntegrationName = @"<your-iterable-push-integration-name>";
	[IterableAPI initializeWithApiKey:@"<your-api-key>" launchOptions:launchOptions config:config]
	```
	
	See the Iterable guide on how to setup your Iterable push integration and obtain push integration name [here](https://support.iterable.com/hc/en-us/articles/115000315806-Setting-Up-iOS-Push-Notifications).	
	
2. ##### Set userId or email. 

	Once you know the email or userId of the user, set the value.
	> &#x26A0; Don't specify both email and userId in the same session, as they will be treated as different users by the SDK. Only use one type of identifier, email or userId, to identify the user.

	Swift:
	
	```swift
	IterableAPI.email = "user@example.com"
	```

	Objective-C:

	```objective-c
	IterableAPI.email = @"user@example.com";
	```
	
3. ##### Send Remote Notification Token to Iterable

	* See [Apple Notification Guide](https://developer.apple.com/documentation/usernotifications) regarding how to register for remote notifiations.
	* In your `AppDelegate`’s [application:didRegisterForRemoteNotificationsWithDeviceToken:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622958-application) method, send the token obtained to Iterable.

	Swift:
	
	```swift
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		IterableAPI.register(token: deviceToken)
	}
	```

	Objective-C:
	
	```objective-c
	- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
		[IterableAPI registerToken:deviceToken];
	}
	```
	See example in sample app delegate [here](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app/swift-sample-app/AppDelegate.swift).

Congratulations! You can now send remote push notifications to your device from Iterable! Please note that you can't send push notifications until you set the userId or email. Please see sample applications to see a reference implementation.

# Using the SDK

1. ##### Handle Push Notifications

	When the user taps on the push notification or one of the action buttons, the system calls `UNUserNotificationCenterDelegate`'s [userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:](https://developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate/1649501-usernotificationcenter?language=objc). Pass this call to **`IterableAppIntegration`** to track push open event and perform the associated action (see below for custom action and URL delegates).
	
	Swift:
	
	```swift
	public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
	}
	```

	Objective-C:
	
	```objective-c
	- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
		[IterableAppIntegration userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
	}
	```
	
2. ##### Deep Linking

	* Handling Links from Push Notifications
		
		Push notifications and action buttons may have `openUrl` actions attached to them. When a URL is specified, the SDK first calls `urlDelegate` specified in your `IterableConfig` object. You can use this delegate to handle `openUrl` actions the same way as you handle normal deep links. If the delegate is not set or if it returns `false` (the default), the SDK will open Safari with that URL. If you want to navigate to a UIViewController on receiving a deep link, you should do so in the `urlDelegate`. 
		
		In the code below, `DeepLinkHandler` is a custom handler which is reponsible for deep link navigation. You have to provide implementation for deep link navigation. Please see [sample application](https://github.com/Iterable/swift-sdk/blob/master/sample-apps/swift-sample-app?raw=true) for a reference implementation.
		
		Swift:
		
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
		
		Objective-C:
		
		```objective-c
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
		
	* Handling Email Links
		
		For Universal Links to work with link rewriting in emails, you need to set up apple-app-site-association file in the Iterable project. More instructions here: [Setting up iOS Universal Links](https://support.iterable.com/hc/en-us/articles/115000440206-Setting-up-iOS-Universal-Links).

		When an email link is clicked your `UIApplicationDelegate`'s [application:continueUserActivity:restorationHandler:](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application?language=swift) method is called. If you already have an Iterable `urlDelegate` defined (see *Handling Links from Push Notifications* section above), the same handler can be used for email deep links by calling `handleUniversalLink:`.

		Swift:
		
		```swift
		func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
			guard let url = userActivity.webpageURL else {
				return false
			}

			// This will track the click, retrieve the original URL and call `handleIterableURL:context:` with the original URL
			return IterableAPI.handle(universalLink: url)
		}
		```

		Objective-C:
		
		```objective-c
		- (BOOL)application:(UIApplication *)application continueUserActivity(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
			// This will track the click, retrieve the original URL and call `handleIterableURL:context:` with the original URL
			return [IterableAPI handleUniversalLink:userActivity.webpageURL];
		}
		```
		
		Alternatively, call `getAndTrackDeeplink` along with a callback to handle the original deeplink url. You can use this method for any incoming URLs, as it will execute the callback without changing the URL for non-Iterable URLs.

		Swift:
		
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

		Objective-C:
		
		```objective-c
		- (BOOL)application:(UIApplication *)application
				continueUserActivity(NSUserActivity *)userActivity 
				restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {

			[IterableAPI getAndTrackDeeplink:iterableLink callbackBlock:^(NSString* originalURL) {
				//Handle Original URL deeplink here
			}];

			return true;
		}
		```
		
3. ##### InApp Notifications
	To display the user's InApp notifications call `spawnInAppNotification` with a defined `ITEActionBlock` callback handler. When a user clicks a button on the notification, the defined handler is called and passed the action name defined in the InApp template.
	
	InApp opens and button clicks are automatically tracked when the notification is called via `spawnInAppNotification`. Using `spawnInAppNotification`, the notification is consumed and removed from the user's in-app messages queue. If you want to retain the messages on the queue, look at using `getInAppMessages` directly. If you use `getInAppMessages` you will need to manage the in-app opens manually in the callback handler.		
4. ##### Tracking Custom Events
	Custom events can be tracked using `IterableAPI.track(event:...)` calls.
	
5. ##### Updating User Fields
	User fields can be modified using `IterableAPI.updateUser` call. You also have `updateEmail` and `updateSubscriptions` methods.
	
6. ##### Disabling Push Notifications to a Device
	When a user logs out, you typically want to disable push notifications to that user/device. This can be accomplished by calling `disableDeviceForCurrentUser`. Please note that it will only attempt to disable the device if you have previously called `registerToken`.
	
	In order to re-enable push notifcations to that device, simply call `registerToken` as usual when the user logs back in.
	
7. ##### Uninstall Tracking
	Iterable will track uninstalls with no additional work by you. 

	This is implemented by sending a second push notification some time (currently, twelve hours) after the original campaign. If we receive feedback that the device's token is no longer valid, we assign an uninstall to the device, attributing it to the most recent campaign within twelve hours. A "real" campaign send (as opposed to the later "ghost" send) can also trigger recording an uninstall. In this case, if there was no previous campaign within the attribution period, an uninstall will still be tracked, but it will not be attributed to any campaign.

# Rich Push Notifications
Push notifications may contain media attachments with images, animated gifs or video, and action buttons. For this to work within your app, you need to create a Notification Service Extension. More instructions here: [Rich Push Notifications in iOS 10 and Android - Media Attachments](https://support.iterable.com/hc/en-us/articles/115003982203-Rich-Push-Notifications-in-iOS-10-and-Android-Media-Attachments).   
Iterable SDK provides an implementation that handles media attachments and action buttons. If you are calling Iterable SDK from Swift, all you need to do is inherit from it. If you are using Objective-C, you will have to delegate to the implementation provided. Please see example below: 
###### Podfile

```
// If the target name for the notification extension is 'MyAppNotificationExtension'
target 'MyAppNotificationExtension' do
	pod 'Iterable-iOS-AppExtensions'
end
```

###### Notification Service Extension

Swift:

```swift
import UserNotifications
import IterableAppExtensions

class NotificationService: ITBNotificationServiceExtension {
}
```

Objective-C: You can not inherit in case of Objective C. You will have to delegate like below.

```objective-c
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
	
# Additional Information

See our [setup guide](https://support.iterable.com/hc/en-us/articles/115000315806-Setting-Up-iOS-Push-Notifications) for more information.

Also see our [push notification setup FAQs](http://support.iterable.com/hc/en-us/articles/206791196-Push-Notification-Setup-FAQ-s).

# License

The MIT License

See [LICENSE](https://github.com/Iterable/swift-sdk/blob/master/LICENSE?raw=true)

## Want to Contribute?

This library is open source, and we will look at pull requests!

See [CONTRIBUTING](CONTRIBUTING.md) for more information.
