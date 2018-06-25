//
//  IterableAppIntegrationInternal.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications


@available(iOS 10.0, *)
public protocol NotificationResponseProtocol {
    var userInfo: [AnyHashable : Any] {get}
    var actionIdentifier: String {get}
    var textInputResponse: UNTextInputNotificationResponse? {get}
}

@available(iOS 10.0, *)
struct UserNotificationResponse : NotificationResponseProtocol {
    var userInfo: [AnyHashable : Any] {
        return response.notification.request.content.userInfo
    }
    
    var actionIdentifier: String {
        return response.actionIdentifier
    }
    
    var textInputResponse: UNTextInputNotificationResponse? {
        return response as? UNTextInputNotificationResponse
    }
    
    private let response : UNNotificationResponse
    
    init(response: UNNotificationResponse) {
        self.response = response
    }
}

/// Abstraction of PushTacking
@objc public protocol PushTrackerProtocol : class {
    @objc func trackPushOpen(_ userInfo: [AnyHashable : Any])
    @objc func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?)
    @objc func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?)
    @objc func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?)
    @objc func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?)
}

/// Abstraction of applicationState
@objc public protocol ApplicationStateProviderProtocol : class {
    @objc var applicationState: UIApplicationState {get}
}

extension UIApplication : ApplicationStateProviderProtocol {
}

/// Abstraction of getting the current version
@objc public protocol VersionInfoProtocol: class {
    func isAvailableIOS10() -> Bool
}

class SystemVersionInfo : VersionInfoProtocol {
    func isAvailableIOS10() -> Bool {
        if #available(iOS 10, *) {
            return true
        } else {
            return false
        }
    }
}

struct IterableAppIntegrationInternal {
    private let tracker: PushTrackerProtocol
    private let actionRunner: ActionRunnerProtocol
    private let versionInfo: VersionInfoProtocol

    init(tracker: PushTrackerProtocol,
         actionRunner: ActionRunnerProtocol,
         versionInfo: VersionInfoProtocol) {
        self.tracker = tracker
        self.actionRunner = actionRunner
        self.versionInfo = versionInfo
    }
    
    /**
     * This method handles incoming Iterable notifications and actions for iOS < 10
     *
     * - parameter application: UIApplication singleton object
     * - parameter userInfo: Dictionary containing the notification data
     * - parameter completionHandler: Completion handler passed from the original call. Iterable will call the completion handler
     * automatically if you pass one. If you handle completionHandler in the app code, pass a nil value to this argument.
     */
    func application(_ application: ApplicationStateProviderProtocol, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult)->Void)?) {
        ITBInfo()
        switch application.applicationState {
        case .active:
            break
        case .background:
            break
        case .inactive:
            if versionInfo.isAvailableIOS10() {
                // iOS 10+ notification actions are handled by userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
            } else {
                performDefaultNotificationAction(userInfo)
            }
            break
        }
        
        completionHandler?(.noData)
    }
    
    /**
     * This method handles user actions on incoming Iterable notifications
     *
     * - parameter center: `UNUserNotificationCenter` singleton object
     * - parameter response: Notification response containing the user action and notification data. Passed from the original call.
     * - parameter completionHandler: Completion handler passed from the original call. Iterable will call the completion handler
     * automatically if you pass one. If you handle completionHandler in the app code, pass a nil value to this argument.
     */
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter?, didReceive response: NotificationResponseProtocol, withCompletionHandler completionHandler: (()->Void)?) {
        ITBInfo()
        let userInfo = response.userInfo
        guard let itbl = IterableAppIntegrationInternal.itblValue(fromUserInfo: userInfo) else {
            return
        }
        
        var dataFields = [AnyHashable : Any]()
        var action: IterableAction? = nil
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            dataFields[ITBL_KEY_ACTION_IDENTIFIER] = ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID
            guard let defaultActionConfig = itbl[ITBL_PAYLOAD_DEFAULT_ACTION] as? [AnyHashable : Any] else {
                return
            }
            action = IterableAction.action(fromDictionary: defaultActionConfig)
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // We don't track dismiss actions yet
        } else {
            dataFields[ITBL_KEY_ACTION_IDENTIFIER] = response.actionIdentifier
            if let buttons = itbl[ITBL_PAYLOAD_ACTION_BUTTONS] as? [[AnyHashable : Any]] {
                for button in buttons {
                    if let buttonIdentifier = button[ITBL_BUTTON_IDENTIFIER] as? String, buttonIdentifier == response.actionIdentifier {
                        if let actionConfig = button[ITBL_BUTTON_ACTION] as? [AnyHashable : Any] {
                            action = IterableAction.action(fromDictionary: actionConfig)
                            break
                        }
                    }
                }
            }
        }
        
        if let textInputResponse = response.textInputResponse {
            let userText = textInputResponse.userText
            dataFields[ITBL_KEY_USER_TEXT] = userText
            action?.userInput = userText
        }
        
        // Track push open
        if let _ = dataFields[ITBL_KEY_ACTION_IDENTIFIER] {
            tracker.trackPushOpen(userInfo, dataFields: dataFields)
        }
        
        //Execute the action
        if let action = action {
            actionRunner.execute(action: action)
        }
        
        completionHandler?()
    }
    
    
    func performDefaultNotificationAction(_ userInfo:[AnyHashable : Any]) {
        // Track push open
        let dataFields = [ITBL_KEY_ACTION_IDENTIFIER : ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID]
        tracker.trackPushOpen(userInfo, dataFields: dataFields)
        
        guard let itbl = IterableAppIntegrationInternal.itblValue(fromUserInfo: userInfo) else {
            return
        }
        
        //Execute the action
        guard let actionConfig = itbl[ITBL_PAYLOAD_DEFAULT_ACTION] as? [AnyHashable : Any] else {
            return
        }
        guard let action = IterableAction.action(fromDictionary: actionConfig) else {
            return
        }
        actionRunner.execute(action: action)
    }
    
    private static func itblValue(fromUserInfo userInfo: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        let itbl = userInfo[ITBL_PAYLOAD_METADATA] as? [AnyHashable : Any]
        
        #if DEBUG
        guard let value = itbl else {
            return nil
        }
        if value[ITBL_PAYLOAD_DEFAULT_ACTION] == nil && value[ITBL_PAYLOAD_ACTION_BUTTONS] == nil {
            return userInfo
        }
        #endif
        
        return itbl
    }

}
