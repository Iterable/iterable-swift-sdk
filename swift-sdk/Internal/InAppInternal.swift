//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum IterableInAppType : Int, Codable {
    case `default`
    case inbox
}

internal protocol IterableMessageProtocol {
    /// the in-app type
    var inAppType: IterableInAppType { get }
    
    /// the id for the inApp message
    var messageId: String { get }
    
    /// the campaign id for this message
    var campaignId: String { get }
    
    /// The content of the Message
    var content: IterableContent { get }
    
    /// when to expire this in-app, nil means do not expire
    var expiresAt: Date? { get }
    
    /// Custom Payload for this message.
    var customPayload: [AnyHashable : Any]? { get }

    /// Whether we have processed this message.
    /// Note: This is internal and not public
    var processed: Bool { get set }
    
    /// Mark this message to be removed from server queue.
    /// Note: This is internal and not public
    var consumed: Bool { get set }
}

extension IterableInAppMessage : IterableMessageProtocol {
    var inAppType : IterableInAppType { return .default }
}

extension IterableInboxMessage : IterableMessageProtocol {
    var inAppType : IterableInAppType { return .inbox }
}

/// Callbacks from the synchronizer
protocol InAppSynchronizerDelegate : class {
    func onInAppRemoved(messageId: String)
    func onInAppMessagesAvailable(messages: [IterableMessageProtocol])
}

///
protocol InAppSynchronizerProtocol {
    // These variables are used for callbacks
    var internalApi: IterableAPIInternal? {get set}
    var inAppSyncDelegate: InAppSynchronizerDelegate? {get set}
    
    // These methods are called on new messages arrive etc.
    func sync()
    func remove(messageId: String)
}

protocol IterableMessageDisplayerProtocol {
    func isShowingIterableMessage() -> Bool
    func show(iterableMessage: IterableMessageProtocol, withCallback callback: ITEActionBlock?) -> Bool
    func showSystemNotification(_ title: String,
                                       body: String,
                                       buttonLeft: String?,
                                       buttonRight: String?,
                                       callbackBlock: ITEActionBlock?)
}

class IterableMessageDisplayer : IterableMessageDisplayerProtocol {
    func isShowingIterableMessage() -> Bool {
        return IterableMessageDisplayer.isShowingIterableMessage()
    }
    
    /// Shows an inApp message and consumes it from server queue if the message is shown.
    /// - parameter message: The Iterable message to show
    /// - parameter callback: the code to execute when user clicks on a link or button on inApp message.
    /// - returns: A Bool indicating whether the inApp was opened.
    func show(iterableMessage: IterableMessageProtocol, withCallback callback: ITEActionBlock?) -> Bool {
        return IterableMessageDisplayer.show(iterableMessage: iterableMessage, withCallback: callback)
    }
    
    /**
     Displays a iOS system style notification with two buttons
     
     - parameters:
     - title:           The notification title
     - body:            The notification message body
     - buttonLeft:      The text of the left button
     - buttonRight:     The text of the right button
     - callbackBlock:   The callback to send after a button on the notification is clicked
     
     - remark:            passes the string of the button clicked to the callbackBlock
     */
    func showSystemNotification( _ title: String, body: String, buttonLeft: String?, buttonRight: String?, callbackBlock: ITEActionBlock?) {
        IterableMessageDisplayer.showSystemNotification(title, body: body, buttonLeft: buttonLeft, buttonRight: buttonRight, callbackBlock: callbackBlock)
    }
    
    /**
     Creates and shows a HTML InApp Notification with trackParameters, backgroundColor with callback handler
     
     - parameters:
     - htmlString:      The NSString containing the dialog HTML
     - trackParams:     The track params for the notification
     - callbackBlock:   The callback to send after a button on the notification is clicked
     - backgroundAlpha: The background alpha behind the notification
     - padding:         The padding around the notification
     - returns:
     true if IterableInAppHTMLViewController was shown.
     */
    @discardableResult static func showIterableHtmlMessage(_ htmlString: String,
                                                           trackParams: IterableNotificationMetadata? = nil,
                                                           backgroundAlpha: Double = 0,
                                                           padding: UIEdgeInsets = .zero,
                                                           callbackBlock: ITEActionBlock?
        ) -> Bool {
        guard let topViewController = getTopViewController() else {
            return false
        }
        if topViewController is IterableInAppHTMLViewController {
            ITBError("Skipping the in-app notification. Another notification is already being displayed.")
            return false
        }
        
        let baseNotification = IterableInAppHTMLViewController(data: htmlString)
        baseNotification.ITESetTrackParams(trackParams)
        baseNotification.ITESetCallback(callbackBlock)
        baseNotification.ITESetPadding(padding)
        
        topViewController.definesPresentationContext = true
        baseNotification.view.backgroundColor = UIColor(white: 0, alpha: CGFloat(backgroundAlpha))
        baseNotification.modalPresentationStyle = .overCurrentContext
        
        topViewController.present(baseNotification, animated: false)
        return true
    }
    
    private static func showSystemNotification(_ title: String,
                                       body: String,
                                       buttonLeft: String?,
                                       buttonRight: String?,
                                       callbackBlock: ITEActionBlock?) {
        guard let topViewController = getTopViewController() else {
            return
        }
        
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        
        if let buttonLeft = buttonLeft {
            addAlertActionButton(alertController: alertController, keyString: buttonLeft, callbackBlock: callbackBlock)
        }
        if let buttonRight = buttonRight {
            addAlertActionButton(alertController: alertController, keyString: buttonRight, callbackBlock: callbackBlock)
        }
        
        topViewController.show(alertController, sender: self)
    }
    
    fileprivate static func isShowingIterableMessage() -> Bool {
        guard Thread.isMainThread else {
            ITBError("Must be called from main thread")
            return false
        }
        guard let topViewController = getTopViewController() else {
            return false
        }
        
        return topViewController is IterableInAppHTMLViewController
    }
    
    private static func getTopViewController() -> UIViewController? {
        guard let rootViewController = IterableUtil.rootViewController else {
            return nil
        }
        var topViewController = rootViewController
        while (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController!
        }
        return topViewController
    }
    
    @discardableResult fileprivate static func show(iterableMessage: IterableMessageProtocol, withCallback callback:ITEActionBlock?) -> Bool {
        guard let content = iterableMessage.content as? IterableHtmlContent else {
            ITBError("Invalid content type")
            return false
        }
        
        let notificationMetadata = IterableNotificationMetadata.metadata(fromInAppOptions: iterableMessage.messageId)
        
        return showIterableHtmlMessage(content.html,
                                                   trackParams: notificationMetadata,
                                                   backgroundAlpha: content.backgroundAlpha,
                                                   padding: content.edgeInsets,
                                                   callbackBlock: callback)
    }

    /**
     Creates and adds an alert action button to an alertController
     
     - parameter alertController:  The alert controller to add the button to
     - parameter keyString:        the text of the button
     - parameter callbackBlock:    the callback to send after a button on the notification is clicked
     
     - remarks:            passes the string of the button clicked to the callbackBlock
     */
    private static func addAlertActionButton(alertController: UIAlertController, keyString: String, callbackBlock: ITEActionBlock?) {
        let button = UIAlertAction(title: keyString, style: .default) { (action) in
            alertController.dismiss(animated: false)
            callbackBlock?(keyString)
        }
        alertController.addAction(button)
    }
}

extension IterableInAppTriggerType {
    static let defaultTriggerType = IterableInAppTriggerType.immediate // default is what is chosen by default
    static let undefinedTriggerType = IterableInAppTriggerType.never // undefined is what we select if payload has new trigger type
}

class InAppSilentPushSynchronizer : InAppSynchronizerProtocol {
    weak var internalApi: IterableAPIInternal?
    weak var inAppSyncDelegate: InAppSynchronizerDelegate?
    
    init() {
        ITBInfo()
    }
    
    func sync() {
        ITBInfo()
        guard let internalApi = self.internalApi else {
            ITBError("Invalid state: expected InternalApi")
            return
        }
        
        InAppHelper.getInAppMessagesFromServer(internalApi: internalApi, number: numMessages).onSuccess {
            if $0.count > 0 {
                self.inAppSyncDelegate?.onInAppMessagesAvailable(messages: $0)
            }
            }.onError {
                ITBError($0.localizedDescription)
        }
    }
    
    func remove(messageId: String) {
        ITBInfo()
        inAppSyncDelegate?.onInAppRemoved(messageId: messageId)
    }
    
    deinit {
        ITBInfo()
    }
    
    // how many messages to fetch
    private let numMessages = 10
}
