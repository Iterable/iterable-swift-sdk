//
//  Created by David Truong on 9/14/16.
//  Ported to Swift by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//
// Utility Methods for inApp

import UIKit

protocol InAppSynchronizerDelegate : class {
    func onInAppContentAvailable(contents: [IterableInAppContent])
}

protocol InAppSynchronizerProtocol {
    var networkSession: NetworkSessionProtocol? {get set}
    var inAppSyncDelegate: InAppSynchronizerDelegate? {get set}
}

struct DefaultInAppSynchronizer : InAppSynchronizerProtocol {
    var networkSession: NetworkSessionProtocol?
    var inAppSyncDelegate: InAppSynchronizerDelegate?
}

// This is Internal Struct, no public methods
struct InAppHelper {
    /**
     Creates and shows a HTML InApp Notification with trackParameters, backgroundColor with callback handler
     
     - parameters:
     - content:         Details about the inApp such as html, backgroundAlpha etc.
     - callbackBlock:   The callback to send after a button on the notification is clicked
     - returns:
     true if IterableInAppHTMLViewController was shown.
     */
    @discardableResult static func showInApp(content: IterableInAppContent,
                                             callbackBlock: ITEActionBlock?
        ) -> Bool {
        let notificationMetadata = IterableNotificationMetadata.metadata(fromInAppOptions: content.messageId)
        return showIterableNotificationHTML(content.html,
                                            trackParams: notificationMetadata,
                                            backgroundAlpha: content.backgroundAlpha,
                                            padding: content.edgeInsets,
                                            callbackBlock: callbackBlock)
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
    @discardableResult static func showIterableNotificationHTML(_ htmlString: String,
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
    static func showSystemNotification(_ title: String,
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
    
    
    /**
     Gets the next message from the payload
     
     - parameter payload:         The payload dictionary
     
     - returns: a Dictionary containing the InAppMessage parameters
     */
    static func getNextMessageFromPayload(_ payload: [AnyHashable : Any]?) -> [AnyHashable : Any]? {
        guard let payload = payload else {
            return nil
        }
        guard let messageArray = payload[.ITBL_IN_APP_MESSAGE] as? [[AnyHashable : Any]], messageArray.count > 0 else {
            return nil
        }
        return messageArray[0]
    }
    
    /**
     Parses the padding offsets from the payload
     
     - parameter payload:         the payload NSDictionary
     
     - returns: the UIEdgeInset
     */
    static func getPaddingFromPayload(_ payload: [AnyHashable : Any]?) -> UIEdgeInsets {
        guard let payload = payload else {
            return UIEdgeInsets.zero
        }

        var padding = UIEdgeInsets.zero
        if let topPadding = payload[PADDING_TOP] {
            padding.top = CGFloat(decodePadding(topPadding))
        }
        if let leftPadding = payload[PADDING_LEFT] {
            padding.left = CGFloat(decodePadding(leftPadding))
        }
        if let rightPadding = payload[PADDING_RIGHT] {
            padding.right = CGFloat(decodePadding(rightPadding))
        }
        if let bottomPadding = payload[PADDING_BOTTOM] {
            padding.bottom = CGFloat(decodePadding(bottomPadding))
        }
        
        return padding
    }
    
    /**
     Gets the int value of the padding from the payload
     
     @param value          the value
     
     @return the padding integer
     
     @discussion Passes back -1 for Auto expanded padding
     */
    static func decodePadding(_ value: Any?) -> Int {
        guard let dict = value as? [AnyHashable : Any] else {
            return 0
        }
        
        if let displayOption = dict[IN_APP_DISPLAY_OPTION] as? String, displayOption == IN_APP_AUTO_EXPAND {
            return -1
        } else {
            if let percentage = dict[IN_APP_PERCENTAGE] as? NSNumber {
                return percentage.intValue
            } else {
                return 0
            }
        }
    }
    
    static func getBackgroundAlpha(fromInAppSettings settings: [AnyHashable : Any]?) -> Double {
        guard let settings = settings else {
            return 0
        }

        if let number = settings[.ITBL_IN_APP_BACKGROUND_ALPHA] as? NSNumber {
            return number.doubleValue
        } else {
            return 0
        }
    }
    
    enum ShowInAppResult {
        case success(opened: Bool, messageId: String)
        case failure(reason: String, messageId: String?)
    }
    
    static func showInApp(parseResult: InAppParseResult, callbackBlock:ITEActionBlock?) -> Future<ShowInAppResult> {
        switch parseResult {
        case .success(let inAppDetails):
            let result = Promise<ShowInAppResult>()
            let notificationMetadata = IterableNotificationMetadata.metadata(fromInAppOptions: inAppDetails.messageId)
            
            DispatchQueue.main.async {
                let opened = InAppHelper.showIterableNotificationHTML(inAppDetails.html,
                                                                               trackParams: notificationMetadata,
                                                                               backgroundAlpha: inAppDetails.backgroundAlpha,
                                                                               padding: inAppDetails.edgeInsets,
                                                                               callbackBlock: callbackBlock)
                result.resolve(with: .success(opened: opened, messageId: inAppDetails.messageId))
            }
            return result
        case .failure(let reason, let messageId):
            return Promise<ShowInAppResult>(value: .failure(reason: reason, messageId: messageId))
        }
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
    
    enum InAppParseResult {
        case success(InAppDetails)
        case failure(reason: String, messageId: String?)
    }
    
    struct InAppDetails {
        let edgeInsets: UIEdgeInsets
        let backgroundAlpha: Double
        let messageId: String
        let html: String
    }
    
    // Payload is what comes from Api
    // If successful you get InAppDetails
    static func parseInApp(fromPayload payload: [AnyHashable : Any]) -> InAppParseResult {
        guard let dialogOptions = InAppHelper.getNextMessageFromPayload(payload) else {
            return .failure(reason: "No notifications found for inApp payload \(payload)", messageId: nil)
        }
        guard let message = dialogOptions[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(reason: "no message", messageId: nil)
        }
        guard let messageId = dialogOptions[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(reason: "no message id", messageId: nil)
        }
        guard let html = message[.ITBL_IN_APP_HTML] as? String else {
            return .failure(reason: "no html", messageId: nil)
        }
        guard html.range(of: AnyHashable.ITBL_IN_APP_HREF, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)", messageId: messageId)
        }
        
        let inAppDisplaySettings = message[.ITBL_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
        let backgroundAlpha = InAppHelper.getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
        let edgeInsets = InAppHelper.getPaddingFromPayload(inAppDisplaySettings)
        
        return .success(InAppDetails(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, messageId: messageId, html: html))
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
    
    private static let PADDING_TOP = "top"
    private static let PADDING_LEFT = "left"
    private static let PADDING_BOTTOM = "bottom"
    private static let PADDING_RIGHT = "right"
    
    private static let IN_APP_DISPLAY_OPTION = "displayOption"
    private static let IN_APP_AUTO_EXPAND = "AutoExpand"
    private static let IN_APP_PERCENTAGE = "percentage"
}
