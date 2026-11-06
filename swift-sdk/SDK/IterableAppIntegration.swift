//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

@objc public class IterableAppIntegration: NSObject {
    /**
     * This method handles 'silent push' notifications.
     * Call it from your app delegate's `application:didReceiveRemoteNotification:fetchCompletionHandler:`.
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
        
        logIfProjectSwitchInProgress()
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
    @objc(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)
    public static func userNotificationCenter(_ center: UNUserNotificationCenter?,
                                              didReceive response: UNNotificationResponse,
                                              withCompletionHandler completionHandler: (() -> Void)?) {
        ITBInfo()
        
        logIfProjectSwitchInProgress()
        if let implementation = implementation {
            implementation.userNotificationCenter(center,
                                                  didReceive: UserNotificationResponse(response: response),
                                                  withCompletionHandler: completionHandler)
        } else {
            InternalIterableAPI.pendingNotificationResponse = UserNotificationResponse(response: response)
        }
    }
    
    // MARK: - Private/Internal
    
    /// Push is deliberately outside `ProjectSwitchGate`, matching Android: the payload carries
    /// the sending project's campaign, template and message IDs, so replaying it after the
    /// switch would attribute it to a project those IDs do not exist in, and holding the OS
    /// completion handler for the length of a switch risks the watchdog. Logged so support can
    /// tell a push handled by the outgoing project apart from a misrouted one.
    private static func logIfProjectSwitchInProgress() {
        guard ProjectSwitchGate.shared.isSwitchInProgress else { return }
        ITBInfo("Push received while switchProject is in progress. It is handled by the project the SDK is currently on, not the incoming one.")
    }
    
    override private init() {
        super.init()
    }
    
    static var implementation: InternalIterableAppIntegration?
}
