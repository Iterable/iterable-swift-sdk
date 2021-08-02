//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

@available(iOSApplicationExtension, unavailable)
@objc public class IterableAppIntegration: NSObject {
    /**
     * This method handles incoming Iterable notifications and actions for iOS < 10.
     * This also handles 'silent push' notifications for all iOS versions.
     * Call it from your app delegate's application:didReceiveRemoteNotification:fetchCompletionHandler:.
     *
     * - parameter application: UIApplication singleton object
     * - parameter userInfo: Dictionary containing the notification data
     * - parameter completionHandler: Completion handler passed from the original call. Iterable will call the completion handler
     * automatically if you pass one. If you handle completionHandler in the app code, pass a nil value to this argument.
     */
    @objc
    public static func application(_ application: UIApplication,
                                   didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                   fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        ITBInfo()
        
        implementation?.application(application,
                                    didReceiveRemoteNotification: userInfo,
                                    fetchCompletionHandler: completionHandler)
    }
    
    /// This method handles user actions on incoming Iterable notifications
    /// Call it from your notification center delegate's `userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:`.
    /// - Parameters:
    ///     - center: `UNUserNotificationCenter` singleton object
    ///     - response: Notification response containing the user action and notification data. Passed from the original call.
    ///     - completionHandler: Completion handler passed from the original call. Iterable will call the completion handler automatically if you pass one. If you handle `completionHandler` in the app code, pass a `nil` value to this argument.
    @available(iOS 10.0, *)
    @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    public static func userNotificationCenter(_ center: UNUserNotificationCenter?,
                                              didReceive response: UNNotificationResponse,
                                              withCompletionHandler completionHandler: (() -> Void)?) {
        ITBInfo()
        
        if let implementation = implementation {
            implementation.userNotificationCenter(center,
                                                  didReceive: UserNotificationResponse(response: response),
                                                  withCompletionHandler: completionHandler)
        } else {
            InternalIterableAPI.pendingNotificationResponse = UserNotificationResponse(response: response)
        }
    }
    
    // MARK: - Private/Internal
    
    override private init() {
        super.init()
    }
    
    static var implementation: IterableAppIntegrationInternal?
}
