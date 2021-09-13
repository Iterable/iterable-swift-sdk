import Foundation
import UIKit
import UserNotifications

import IterableSDK

/// Utility class to encapsulate Iterable specific code.
class IterableHelper {
    // Please replace with your API key
    #error("Please add your API Key here")
    private static let apiKey = ""
    
    static func initialize(launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        let config = IterableConfig()
        // urlDelegate and customActionDelegate must be strong references
        // otherwise they will be deallocated
        config.urlDelegate = urlDelegate
        config.customActionDelegate = customActionDelegate
        IterableAPI.initialize(apiKey: apiKey,
                               launchOptions: launchOptions,
                               config: config)
    }
    
    static func login(email: String) {
        IterableAPI.email = email
    }
    
    static func logout() {
        IterableAPI.email = nil
    }
    
    /// This is needed to hookup track push opens.
    /// This will also setup url handler, custom action handler to work with IterableSDK
    static func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    /// This is needed for silent push
    static func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        IterableAppIntegration.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    /// Pass deeplinks to iterable
    static func handle(universalLink url: URL) -> Bool {
        IterableAPI.handle(universalLink: url)
    }
    
    /// Pass the token to Iterable
    static func register(token: Data) {
        IterableAPI.register(token: token)
    }
    
    private static var urlDelegate = URLDelegate()
    private static var customActionDelegate = CustomActionDelegate()
}

class URLDelegate{}

extension URLDelegate: IterableURLDelegate {
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        DeepLinkHandler.handle(url: url)
    }
}

class CustomActionDelegate{}

extension CustomActionDelegate: IterableCustomActionDelegate {
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        true
    }
}
