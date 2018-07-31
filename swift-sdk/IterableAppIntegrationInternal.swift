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
    @objc var lastPushPayload: [AnyHashable : Any]? {get}
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
    private let versionInfo: VersionInfoProtocol
    private let contextToUrlHandler: ((IterableActionContext) -> UrlHandler)?
    private let contextToCustomActionHandler: ((IterableActionContext) -> CustomActionHandler)?
    private let urlOpener: UrlOpenerProtocol

    init(tracker: PushTrackerProtocol,
         versionInfo: VersionInfoProtocol,
         contextToUrlHandler: ((IterableActionContext) -> UrlHandler)?,
         contextToCustomActionHandler: ((IterableActionContext) -> CustomActionHandler)?,
         urlOpener: UrlOpenerProtocol) {
        self.tracker = tracker
        self.versionInfo = versionInfo
        self.contextToUrlHandler = contextToUrlHandler
        self.contextToCustomActionHandler = contextToCustomActionHandler
        self.urlOpener = urlOpener
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
        // Ignore the notification if we've already processed it from launchOptions while initializing SDK
        guard !alreadyTracked(userInfo: userInfo) else {
            completionHandler?()
            return
        }
        guard let itbl = IterableAppIntegrationInternal.itblValue(fromUserInfo: userInfo) else {
            completionHandler?()
            return
        }

        let dataFields = IterableAppIntegrationInternal.createIterableDataFields(actionIdentifier: response.actionIdentifier, userText: response.textInputResponse?.userText)
        let action = IterableAppIntegrationInternal.createIterableAction(actionIdentifier: response.actionIdentifier, userText: response.textInputResponse?.userText, userInfo: userInfo, iterableElement: itbl)

        // Track push open
        if let _ = dataFields[ITBL_KEY_ACTION_IDENTIFIER] {
            tracker.trackPushOpen(userInfo, dataFields: dataFields)
        }
        
        //Execute the action
        if let action = action {
            let context = IterableActionContext(action: action, source: .push)
            IterableActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: contextToUrlHandler?(context),
                                         customActionHandler: contextToCustomActionHandler?(context),
                                         urlOpener: urlOpener)
        }

        completionHandler?()
    }

    @available(iOS 10.0, *)
    private static func createIterableAction(actionIdentifier: String, userText: String?, userInfo: [AnyHashable : Any], iterableElement itbl: [AnyHashable : Any]) -> IterableAction? {
        var action: IterableAction? = nil
        
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            // default
            if let defaultActionConfig = itbl[ITBL_PAYLOAD_DEFAULT_ACTION] as? [AnyHashable : Any] {
                action = IterableAction.action(fromDictionary: defaultActionConfig)
            } else {
                action = IterableAppIntegrationInternal.legacyDefaultActionFromPayload(userInfo: userInfo)
            }
        } else if actionIdentifier == UNNotificationDismissActionIdentifier {
            // We don't track dismiss actions yet
        } else {
            // Action Buttons
            if let actionConfig = findButtonActionConfig(actionIdentifier: actionIdentifier, iterableElement: itbl) {
                action = IterableAction.action(fromDictionary: actionConfig)
            }
        }
        
        if let userText = userText {
            action?.userInput = userText
        }

        return action
    }
    
    private static func findButtonActionConfig(actionIdentifier: String, iterableElement itbl: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        guard let buttons = itbl[ITBL_PAYLOAD_ACTION_BUTTONS] as? [[AnyHashable : Any]] else {
            return nil
        }
        let foundButton = buttons.first { (button) -> Bool in
            guard let buttonIdentifier = button[ITBL_BUTTON_IDENTIFIER] as? String else {
                return false
            }
            return buttonIdentifier == actionIdentifier
        }
        
        return foundButton?[ITBL_BUTTON_ACTION] as? [AnyHashable : Any]
    }
    
    @available(iOS 10.0, *)
    private static func createIterableDataFields(actionIdentifier: String, userText: String?) -> [AnyHashable : Any] {
        var dataFields = [AnyHashable : Any]()
        
        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            dataFields[ITBL_KEY_ACTION_IDENTIFIER] = ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID
        } else if actionIdentifier == UNNotificationDismissActionIdentifier {
            // We don't track dismiss actions yet
        } else {
            dataFields[ITBL_KEY_ACTION_IDENTIFIER] = actionIdentifier
        }
        
        if let userText = userText {
            dataFields[ITBL_KEY_USER_TEXT] = userText
        }

        return dataFields
    }
    
    func performDefaultNotificationAction(_ userInfo:[AnyHashable : Any]) {
        // Ignore the notification if we've already processed it from launchOptions while initializing SDK
        guard !alreadyTracked(userInfo: userInfo) else{
            return
        }
        
        // Track push open
        let dataFields = [ITBL_KEY_ACTION_IDENTIFIER : ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID]
        tracker.trackPushOpen(userInfo, dataFields: dataFields)
        
        guard let itbl = IterableAppIntegrationInternal.itblValue(fromUserInfo: userInfo) else {
            return
        }

        //Execute the action

        let action: IterableAction?
        if let actionConfig = itbl[ITBL_PAYLOAD_DEFAULT_ACTION] as? [AnyHashable : Any] {
            action = IterableAction.action(fromDictionary: actionConfig)
        } else {
            action = IterableAppIntegrationInternal.legacyDefaultActionFromPayload(userInfo: userInfo)
        }

        if let action = action {
            let context = IterableActionContext(action: action, source: .push)
            IterableActionRunner.execute(action: action,
                                         context: context,
                                         urlHandler: contextToUrlHandler?(context),
                                         customActionHandler: contextToCustomActionHandler?(context),
                                         urlOpener: urlOpener)
        }
    }
    
    private func alreadyTracked(userInfo: [AnyHashable : Any]) -> Bool {
        guard let lastPushPayload = tracker.lastPushPayload else {
            return false
        }
        return NSDictionary(dictionary: lastPushPayload).isEqual(to: userInfo)
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

    private static func legacyDefaultActionFromPayload(userInfo: [AnyHashable : Any]) -> IterableAction? {
        if let deeplinkUrl = userInfo[ITBConsts.Payload.deeplinkUrl] as? String {
            return IterableAction.actionOpenUrl(fromUrlString: deeplinkUrl)
        } else {
            return nil
        }
    }
}
