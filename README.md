[![CocoaPods](https://img.shields.io/cocoapods/v/Iterable-iOS-SDK.svg?style=flat)](https://cocoapods.org/pods/Iterable-iOS-SDK)
[![License](https://img.shields.io/cocoapods/l/Iterable-iOS-SDK.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Docs](https://img.shields.io/cocoapods/metrics/doc-percent/Iterable-iOS-SDK.svg?style=flat)](http://cocoadocs.org/docsets/Iterable-iOS-SDK)
[![Build Status](https://travis-ci.com/Iterable/swift-sdk.svg?branch=master)](https://travis-ci.com/Iterable/swift-sdk)

# Iterable iOS SDK

`Iterable-iOS-SDK` is a Swift implementation of an iOS client for Iterable, for iOS versions 9.0 and higher.

# Setting up a push integration in Iterable

Before you even start with the SDK, you will need to 

1. Set your application up to receive push notifications, and 
2. Set up a push integration in Iterable. This allows Iterable to communicate on your behalf with Apple's Push Notification Service

If you haven't yet done so, you will need to enable push notifications for your application. This can be done by toggling `Push Notifications` under your target's `Capabilities` in Xcode. You can also do it directly in the app center on Apple's member center; go to `Identifiers -> App IDs -> select your app`. You should see `Push Notifications` under `Application Services`. Hit `Edit` and enable `Push Notifications`.

You will also need to generate an SSL certificate and private key for use with the push service. See the links at the end of this section for more information on how to do that.

Once you have your APNS certificates set up, go to `Integrations -> Mobile Push` in Iterable. When creating an integration, you will need to pick a name and a platform. The name is entirely up to you; it will be the `appName` when you use `registerToken` in our SDK. The platform can be `APNS` or `APNS_SANDBOX`; these correspond to the production and sandbox platforms. Your application will generate a different token depending on whether it is built using a development certificate or a distribution provisioning profile.

![Creating an integration in Iterable](http://support.iterable.com/hc/en-us/article_attachments/202957719/Screen_Shot_2015-07-30_at_3.15.56_PM.png)

For more information, see

* [Configuring Push Notifications](https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/AddingCapabilities/AddingCapabilities.html#//apple_ref/doc/uid/TP40012582-CH26-SW6)
* [Creating Certificates](https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/MaintainingCertificates/MaintainingCertificates.html#//apple_ref/doc/uid/TP40012582-CH31-SW32)
* [Amazon's Guide to Creating Certificates](http://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html)

Congratulations, you've configured your mobile application to receive push notifications! Now, let's set up the Iterable SDK...

# Automatic Installation (via CocoaPods)

Iterable supports [CocoaPods](https://cocoapods.org) for easy installation. If you don't have it yet, you can install it with `Ruby` by running:
```
$ sudo gem install cocoapods 
```

To include the Iterable SDK in your project, you need to add it to your `Podfile`. If you don't have a `Podfile` yet, you can create one by running:
```
$ pod init
```

To add the Iterable pod to your target, edit the `Podfile` and include this line under the target:
```
pod 'Iterable-iOS-SDK'
```

Now, you need to tell Cocoapods to install the dependencies:
```
$ pod install
```

Congratulations! You have now imported the Iterable SDK into your project! 


# Using the SDK
1. Initialize the API with API key. The only required parameter is `apiKey`. You may also like to set default configuration parameters.

	```
	IterableAPI.initialize(apiKey: "your-api-key", optionalParameters.....)
	```
  * Ideally, you will call this from inside `application:didFinishLaunchingWithOptions:` and pass in `launchOptions`. This will let the SDK automatically track a push open for you if the application was launched from a remote Iterable push notification. 
	
2. Once you know the email *(Preferred)* or userId of the user, set the value.

	```
	IterableAPI.email = 'user@example.com'
	```

# Additional Information

See our [setup guide](http://support.iterable.com/hc/en-us/articles/204780589-Push-Notification-Setup-iOS-and-Android-) for more information.

Also see our [push notification setup FAQs](http://support.iterable.com/hc/en-us/articles/206791196-Push-Notification-Setup-FAQ-s).

# License

The MIT License

See [LICENSE](https://github.com/Iterable/iterable-ios-sdk/blob/master/LICENSE)

## Want to Contribute?

This library is open source, and we will look at pull requests!

See [CONTRIBUTING](CONTRIBUTING.md) for more information.
