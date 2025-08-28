//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

/// Protocol to provide dynamic control over in-app message display timing.
/// This delegate allows the application to determine at the exact moment 
/// whether an in-app message should be displayed, providing more granular
/// control than the static `isAutoDisplayPaused` property.
@objc public protocol IterableInAppDisplayDelegate {
    
    /// Called to determine if in-app messages should be automatically displayed at this moment.
    /// This method is called just before an in-app message would be shown, allowing the app
    /// to make a real-time decision based on current app state.
    ///
    /// - Parameter message: The in-app message that is about to be displayed
    /// - Returns: `true` if automatic display should be paused (message will not show), `false` if display should proceed
    ///
    /// - Note: This method is called in addition to other display checks. If this returns `true`,
    ///         the message will not be shown regardless of other conditions.
    /// - Note: If this delegate is not set, the default behavior uses the `isAutoDisplayPaused` property.
    @objc optional func isAutoDisplayPaused(for message: IterableInAppMessage) -> Bool
}

public enum IterableAPIMobileFrameworkType: String, Codable {
    case flutter = "flutter"
    case reactNative = "reactnative"
    case native = "native"
}

public struct IterableAPIMobileFrameworkInfo: Codable {
    public let frameworkType: IterableAPIMobileFrameworkType
    public let iterableSdkVersion: String?
    
    public init(frameworkType: IterableAPIMobileFrameworkType, iterableSdkVersion: String?) {
        self.frameworkType = frameworkType
        self.iterableSdkVersion = iterableSdkVersion
    }
}

/// Custom URL handling delegate
@objc public protocol IterableURLDelegate: AnyObject {
    /// Callback called for a deep link action. Return true to override default behavior
    /// - Parameters:
    ///     - url: The deep link URL
    ///     - context: Metadata containing the original action and the source: push or universal link.
    ///
    /// - Returns: `true` if the URL was handled to override default behavior.
    @objc(handleIterableURL:context:)
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool
}

/// Custom action handling delegate
@objc public protocol IterableCustomActionDelegate: AnyObject {
    
    /// Callback called for custom actions from push notifications
    /// - Parameters:
    ///     - action: `IterableAction` object containing action payload
    ///     - context: Metadata containing the original action and the source: push or universal link.
    ///
    /// - Returns: Boolean value. Reserved for future use.
    @objc(handleIterableCustomAction:context:)
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool
}

/// This protocol allows you to override default behavior when new in-app messages arrive.
@objc public protocol IterableInAppDelegate: AnyObject {
    /// This method is called when new in-app message is available.
    /// The default behavior is to `show` if you don't override this method.
    ///
    /// - Parameters:
    ///     - message: `IterableInAppMessage` object containing information regarding in-app to display
    ///
    /// - Returns:Return `show` to show the in-app or `skip` to skip this.
    @objc(onNewMessage:)
    func onNew(message: IterableInAppMessage) -> InAppShowResponse
}

/// The protocol for adjusting logging
@objc public protocol IterableLogDelegate: AnyObject {
    /// Log a message.
    /// - Parameters:
    ///     - level: The logging level
    ///     - message: The message to log. The message will include file, method and line of the call.
    @objc(log:message:)
    func log(level: LogLevel, message: String)
}

/// The delegate for getting the authentication token
@objc public protocol IterableAuthDelegate: AnyObject {
    @objc func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler)
    @objc func onAuthFailure(_ authFailure: AuthFailure)
}

/// The delegate for getting the UserId once unknown user session tracked
@objc public protocol IterableUnknownUserHandler: AnyObject {
    @objc func onUnknownUserCreated(userId: String)
}

/// Iterable Configuration Object. Use this when initializing the API.
@objcMembers
public class IterableConfig: NSObject {
    /// You don't have to set this variable. Set this value only if you are an existing Iterable customer who has already setup mobile integrations in Iterable Web UI.
    /// In that case, set this variable to the push integration name that you have set for `APNS` in Iterable Web UI.
    /// To view your existing integrations, navigate to Settings > Mobile Apps
    public var pushIntegrationName: String?
    
    /// You don't have to set this variable. Set this value only if you are an existing Iterable customer who has already setup mobile integrations in Iterable Web UI.
    /// In that case, set this variable to the push integration name that you have set for `APNS_SANDBOX` in Iterable Web UI.
    /// To view your existing integrations, navigate to Settings > Mobile Apps
    public var sandboxPushIntegrationName: String?
    
    /// The APNS (Apple Push Notification Service) environment for the current build of the app.
    /// Possible values: `production`, `sandbox`, `auto`
    /// Defaults to `auto` and detects the APNS environment automatically
    public var pushPlatform: PushServicePlatform = .auto
    
    /// Handles Iterable actions of type `openUrl`
    public weak var urlDelegate: IterableURLDelegate?
    
    /// How to handle IterableActions which are other than `openUrl`
    public weak var customActionDelegate: IterableCustomActionDelegate?
    
    /// Implement this protocol to enable token-based authentication with the Iterable SDK
    public weak var authDelegate: IterableAuthDelegate?

    /// Implement this protocol to get userId once the userId set for Unknown User
    public weak var unknownUserHandler: IterableUnknownUserHandler?


    /// When set to `true`, IterableSDK will automatically register and deregister
    /// notification tokens.
    public var autoPushRegistration = true
    
    /// When set to true, it will check for deferred deep links on first time app launch
    /// after installation from the App Store.
    @available(*, deprecated, message: "This flag is no longer supported and will be removed in a future version.")
    public var checkForDeferredDeeplink = false
    
    /// Implement the protocol `IterableLogDelegate` and set it here to change logging.
    ///
    /// Out of the box you have the following:
    /// 1. `DefaultLogDelegate`. It will use OsLog for .error, console for .info and no logging for debug.
    /// 2. `NoneLogDelegate`. No logging messages will be output.
    /// 3. `AllLogDelegate`. This will log everything to console.
    ///
    /// The default value is `DefaultLogDelegate`.
    /// It will log everything >= minLogLevel
    public var logDelegate: IterableLogDelegate = DefaultLogDelegate()
    
    /// Implement this protocol to override default in-app behavior.
    /// By default, every single in-app will be shown as soon as it is available.
    /// If more than 1 in-app is available, we show the first.
    public var inAppDelegate: IterableInAppDelegate = DefaultInAppDelegate()
    
    /// Implement this protocol to provide dynamic control over when in-app messages can be displayed.
    /// This delegate allows real-time decision making about display timing, providing more granular
    /// control than the static `isAutoDisplayPaused` property. If not set, the SDK will fall back
    /// to using the `isAutoDisplayPaused` property.
    public var inAppDisplayDelegate: IterableInAppDisplayDelegate?
    
    /// How many seconds to wait before showing the next in-app, if there are more than one present
    public var inAppDisplayInterval: Double = 30.0
    
    /// the number of seconds before expiration of the current auth token to get a new auth token
    /// will only apply if token-based authentication is enabled, and the current auth token has
    /// an expiration date field in it
    public var expiringAuthTokenRefreshPeriod: TimeInterval = 60.0
    
    /// Retry policy for JWT Refresh.
    public var retryPolicy: RetryPolicy = RetryPolicy(maxRetry: 10, retryInterval: 6, retryBackoff: .linear)
    
    /// We allow navigation only to urls with `https` protocol (for deep links within your app or external links).
    /// If you want to allow other protocols, such as,  `http`, `tel` etc., please add them to the list below
    public var allowedProtocols: [String] = []
    
    /// Set whether the SDK should store in-apps only in memory, or in file storage
    public var useInMemoryStorageForInApps = false
    
    /// Sets data region which determines data center and endpoints used by the SDK
    public var dataRegion: String = IterableDataRegion.US
    
    /// When set to `true`, IterableSDK will track all events when users are not logged into the application.
    public var enableUnknownUserActivation = true
    
    /// Enables fetching of unknown user criteria on foreground when set to `true`
    /// By default, the SDK will fetch unknown user criteria on foreground.
    public var enableForegroundCriteriaFetch = true
    
    /// Allows for fetching embedded messages.
    public var enableEmbeddedMessaging = false

    // How many events can be stored in the local storage. By default limt is 100.
    public var eventThresholdLimit: Int = 100
    
    public var identityResolution: IterableIdentityResolution = IterableIdentityResolution(replayOnVisitorToKnown: true, mergeOnUnknownUserToKnown: true)
    
    /// The type of mobile framework we are using.
    public var mobileFrameworkInfo: IterableAPIMobileFrameworkInfo?
}

