//
//  IterableAppIntegration.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 5/31/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications

@objc public class IterableAppIntegration : NSObject {
    /**
     * This method handles incoming Iterable notifications and actions for iOS < 10
     * Call it from your app delegate's application:didReceiveRemoteNotification:fetchCompletionHandler:.
     *
     * - parameter application: UIApplication singleton object
     * - parameter userInfo: Dictionary containing the notification data
     * - parameter completionHandler: Completion handler passed from the original call. Iterable will call the completion handler
     * automatically if you pass one. If you handle completionHandler in the app code, pass a nil value to this argument.
     */
    @objc public static func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult)->Void)?) {
        ITLog()
        switch application.applicationState {
        case .active:
            break
        case .background:
            break
        case .inactive:
            if #available(iOS 10, *) {
                // iOS 10+ notification actions are handled by userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:
            } else {
                performDefaultNotificationAction(userInfo, api: IterableAPI.instance)
            }
            break
        }
        
        completionHandler?(.noData)
    }
    
    /**
     * This method handles user actions on incoming Iterable notifications
     * Call it from your notification center delegate's userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:.
     *
     * - parameter center: `UNUserNotificationCenter` singleton object
     * - parameter response: Notification response containing the user action and notification data. Passed from the original call.
     * - parameter completionHandler: Completion handler passed from the original call. Iterable will call the completion handler
     * automatically if you pass one. If you handle completionHandler in the app code, pass a nil value to this argument.
     */
    @available(iOS 10.0, *)
    @objc public static func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: (()->Void)?) {
        ITLog()
        let userInfo = response.notification.request.content.userInfo
        guard let itbl = itblValue(fromUserInfo: userInfo) else {
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
        
        if let textInputResponse = response as? UNTextInputNotificationResponse {
            let userText = textInputResponse.userText
            dataFields[ITBL_KEY_USER_TEXT] = userText
            action?.userInput = userText
        }
        
        // Track push open
        if let _ = dataFields[ITBL_KEY_ACTION_IDENTIFIER] {
            IterableAPI.instance?.trackPushOpen(userInfo, dataFields: dataFields)
        }
        
        //Execute the action
        if let action = action {
            IterableActionRunner.executeAction(action)
        }

        completionHandler?()
    }

    
    @objc public static func performDefaultNotificationAction(_ userInfo:[AnyHashable : Any], api:IterableAPI?) {
        // Track push open
        let dataFields = [ITBL_KEY_ACTION_IDENTIFIER : ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID]
        api?.trackPushOpen(userInfo, dataFields: dataFields)
        
        guard let itbl = itblValue(fromUserInfo: userInfo) else {
            return
        }
        
        //Execute the action
        guard let actionConfig = itbl[ITBL_PAYLOAD_DEFAULT_ACTION] as? [AnyHashable : Any] else {
            return
        }
        guard let action = IterableAction.action(fromDictionary: actionConfig) else {
            return
        }
        IterableActionRunner.executeAction(action)
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
