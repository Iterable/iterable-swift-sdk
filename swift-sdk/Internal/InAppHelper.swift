//
//  Created by David Truong on 9/14/16.
//  Ported to Swift by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//
// Utility Methods for inApp
// All classes/structs are internal.

import UIKit

/// Callbacks from the synchronizer
protocol InAppSynchronizerDelegate : class {
    func onInAppRemoved(messageId: String)
    func onInAppMessagesAvailable(messages: [IterableInAppMessage])
}

///
protocol InAppSynchronizerProtocol {
    var internalApi: IterableAPIInternal? {get set}
    var inAppSyncDelegate: InAppSynchronizerDelegate? {get set}
    
    func sync()
    func remove(messageId: String)
}

protocol InAppDisplayerProtocol {
    func isShowingInApp() -> Bool
    func showInApp(message: IterableInAppMessage, callback: ITBURLCallback?) -> Bool
}

class InAppDisplayer : InAppDisplayerProtocol {
    func isShowingInApp() -> Bool {
        return InAppHelper.isShowingInApp()
    }
    
    func showInApp(message: IterableInAppMessage, callback: ITBURLCallback?) -> Bool {
        return InAppHelper.showInApp(message: message, callback: callback)
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
    private let numMessages = 100
}


// This is Internal Struct, no public methods
struct InAppHelper {
    fileprivate static func isShowingInApp() -> Bool {
        guard Thread.isMainThread else {
            ITBError("Must be called from main thread")
            return false
        }
        guard let topViewController = getTopViewController() else {
            return false
        }

        return topViewController is IterableInAppHTMLViewController
    }
    
    /// Shows an inApp message and consumes it from server queue if the message is shown.
    /// - parameter message: The inApp message to show
    /// - parameter callback: the code to execute when user clicks on a link or button on inApp message.
    /// - returns: A Bool indicating whether the inApp was opened.
    @discardableResult fileprivate static func showInApp(message: IterableInAppMessage, callback:ITBURLCallback?) -> Bool {
        guard let content = message.content as? IterableHtmlInAppContent else {
            ITBError("Invalid content type")
            return false
        }
        
        let notificationMetadata = IterableNotificationMetadata.metadata(fromInAppOptions: message.messageId)
        
        return InAppHelper.showIterableNotificationHTML(content.html,
                                                                  trackParams: notificationMetadata,
                                                                  backgroundAlpha: content.backgroundAlpha,
                                                                  padding: content.edgeInsets,
                                                                  callbackBlock: callback)
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
                                                          callbackBlock: ITBURLCallback?
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
     Parses the padding offsets from the payload
     
     - parameter settings:         the settings distionary.
     
     - returns: the UIEdgeInset
     */
    static func getPadding(fromInAppSettings settings: [AnyHashable : Any]?) -> UIEdgeInsets {
        guard let dict = settings else {
            return UIEdgeInsets.zero
        }

        var padding = UIEdgeInsets.zero
        if let topPadding = dict[PADDING_TOP] {
            padding.top = CGFloat(decodePadding(topPadding))
        }
        if let leftPadding = dict[PADDING_LEFT] {
            padding.left = CGFloat(decodePadding(leftPadding))
        }
        if let rightPadding = dict[PADDING_RIGHT] {
            padding.right = CGFloat(decodePadding(rightPadding))
        }
        if let bottomPadding = dict[PADDING_BOTTOM] {
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
    
    enum InAppClickedUrl {
        case localResource(name: String) // applewebdata://abc-def/something => something
        case iterableCustomAction(name: String) // iterable://something => something
        case customAction(name: String) // action:something => something or itbl://something => something
        case regularUrl(URL) // https://something => https://something
    }
    
    static func parse(inAppUrl url: URL) -> InAppClickedUrl? {
        guard let scheme = UrlScheme.from(url: url) else {
            ITBError("Request url contains an invalid scheme: \(url)")
            return nil
        }

        switch scheme {
        case .applewebdata:
            ITBError("Request url contains an invalid scheme: \(url)")
            guard let urlPath = getUrlPath(url: url) else {
                return nil
            }
            return .localResource(name: urlPath)
        case .iterable:
            return .iterableCustomAction(name: dropScheme(urlString: url.absoluteString, scheme: scheme.rawValue))
        case .action:
            return .customAction(name: dropScheme(urlString: url.absoluteString, scheme: scheme.rawValue))
        case .backwardCompat:
            return .customAction(name: dropScheme(urlString: url.absoluteString, scheme: scheme.rawValue))
        case .other:
            return .regularUrl(url)
        }
    }
    
    static func getInAppMessagesFromServer(internalApi: IterableAPIInternal, number: Int) -> Future<[IterableInAppMessage]> {
        return internalApi.getInAppMessages(NSNumber(value: number)).map {
            inAppMessages(fromPayload: $0, internalApi: internalApi)
        }
    }
    
    /// Given json payload, It will construct array of IterableInAppMessage
    /// This will also make sure to consume any invalid inAppMessage.
    static func inAppMessages(fromPayload payload: [AnyHashable : Any], internalApi: IterableAPIInternal) -> [IterableInAppMessage] {
        return parseInApps(fromPayload: payload).map { toMessage(fromInAppParseResult: $0, internalApi: internalApi) }.compactMap { $0 }
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
    
    private enum InAppParseResult {
        case success(InAppDetails)
        case failure(reason: String, messageId: String?)
    }
    
    /// This is a struct equivalent of IterableInAppMessage class
    private struct InAppDetails {
        let inAppType: IterableInAppType
        let content: IterableInAppContent
        let messageId: String
        let campaignId: String
        let trigger: IterableInAppTrigger
        let expiresAt: Date?
        let customPayload: [AnyHashable : Any]?
    }

    /// Returns an array of Dictionaries holding inApp messages.
    private static func getInAppDicts(fromPayload payload: [AnyHashable : Any]) -> [[AnyHashable : Any]] {
        return payload[.ITBL_IN_APP_MESSAGE] as? [[AnyHashable : Any]] ?? []
    }
    
    private static func parseInApps(fromPayload payload: [AnyHashable : Any]) -> [InAppParseResult] {
        return getInAppDicts(fromPayload: payload).map {
            parseInApp(fromDict: preProcess(dict: $0))
        }
    }
    
    // Change the in-app payload coming from the server to one that we expect it to be like
    // This is temporary until we fix the backend to do the right thing.
    // 1. Move 'inAppType', to top level from 'customPayload'
    // 2. Move 'contentType' to 'content' element.
    //!! Remove when we have backend support
    private static func preProcess(dict: [AnyHashable : Any]) -> [AnyHashable : Any] {
        var result = dict
        guard var customPayloadDict = dict[.ITBL_IN_APP_CUSTOM_PAYLOAD] as? [AnyHashable : Any] else {
            return result
        }

        moveValue(withKey: AnyHashable.ITBL_IN_APP_INAPP_TYPE, from: &customPayloadDict, to: &result)

        if var contentDict = dict[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] {
            moveValue(withKey: AnyHashable.ITBL_IN_APP_CONTENT_TYPE, from: &customPayloadDict, to: &contentDict)
            result[.ITBL_IN_APP_CONTENT] = contentDict
        }

        result[.ITBL_IN_APP_CUSTOM_PAYLOAD] = customPayloadDict
        
        return result
    }
    
    private static func moveValue(withKey key: String, from source: inout [AnyHashable : Any], to destination: inout [AnyHashable : Any]) {
        guard destination[key] == nil else {
            // value exists in destination, so don't override
            return
        }
        
        if let value = source[key] {
            destination[key] = value
            source[key] = nil
        }
    }

    private static func parseInApp(fromDict dict: [AnyHashable : Any]) -> InAppParseResult {
        guard let messageId = dict[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(reason: "no message id", messageId: nil)
        }

        let inAppType: IterableInAppType
        if let inAppTypeStr = dict[.ITBL_IN_APP_INAPP_TYPE] as? String {
            inAppType = IterableInAppType.from(string: inAppTypeStr)
        } else {
            inAppType = .default
        }

        guard let contentDict = dict[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(reason: "no content in json payload", messageId: messageId)
        }

        let content: IterableInAppContent
        switch (InAppContentParser.parse(contentDict: contentDict)) {
        case .success(let parsedContent):
            content = parsedContent
        case .failure(let reason):
            return .failure(reason: reason, messageId: messageId)
        }
        
        let campaignId: String
        if let theCampaignId = dict[.ITBL_KEY_CAMPAIGN_ID] as? String {
            campaignId = theCampaignId
        } else {
            ITBDebug("Could not find campaignId") // This is debug level because this happens a lot with proof inApps
            campaignId = ""
        }

        let customPayload = parseCustomPayload(fromPayload: dict)
        
        let trigger = parseTrigger(fromTriggerElement: dict[.ITBL_IN_APP_TRIGGER] as? [AnyHashable : Any])
        let expiresAt = parseExpiresAt(dict: dict)
        
        return .success(InAppDetails(
            inAppType: inAppType,
            content: content,
            messageId: messageId,
            campaignId: campaignId,
            trigger: trigger,
            expiresAt: expiresAt,
            customPayload: customPayload))
    }
    
    private static func parseExpiresAt(dict: [AnyHashable : Any]) -> Date? {
        guard let intValue = dict[.ITBL_IN_APP_EXPIRES_AT] as? Int else {
            return nil
        }
        
        let seconds = Double(intValue) / 1000.0
        return Date(timeIntervalSince1970: seconds)
    }
    
    private static func parseTrigger(fromTriggerElement element: [AnyHashable : Any]?) -> IterableInAppTrigger {
        guard let element = element else {
            return .defaultTrigger // if element is missing return default which is immediate
        }

        return IterableInAppTrigger(dict: element)
    }
    
    private static func parseCustomPayload(fromPayload payload: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        return payload[.ITBL_IN_APP_CUSTOM_PAYLOAD] as? [AnyHashable : Any]
    }
    
    private static func toMessage(fromInAppParseResult inAppParseResult: InAppHelper.InAppParseResult, internalApi: IterableAPIInternal) -> IterableInAppMessage? {
        switch inAppParseResult {
        case .success(let inAppDetails):
            return IterableInAppMessage(messageId: inAppDetails.messageId,
                                        campaignId: inAppDetails.campaignId,
                                        inAppType: inAppDetails.inAppType,
                                        trigger: inAppDetails.trigger,
                                        expiresAt: inAppDetails.expiresAt,
                                        content: inAppDetails.content,
                                        customPayload: inAppDetails.customPayload)
        case .failure(reason: let reason, messageId: let messageId):
            ITBError(reason)
            if let messageId = messageId {
                internalApi.inAppConsume(messageId)
            }
            return nil
        }
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
    
    private enum UrlScheme : String {
        case applewebdata = "applewebdata"
        case iterable = "iterable"
        case action = "action"
        case backwardCompat = "itbl"
        case other
        
        fileprivate static func from(url: URL) -> UrlScheme? {
            guard let name = url.scheme else {
                return nil
            }
            if let scheme = UrlScheme(rawValue: name.lowercased()) {
                return scheme
            } else {
                return .other
            }
        }
    }
    
    // returns everything other than scheme, hostname and leading slashes
    // so scheme://host/path#something => path#something
    private static func getUrlPath(url: URL) -> String? {
        guard let host = url.host else {
            return nil
        }
        let urlArray = url.absoluteString.components(separatedBy: host)
        guard urlArray.count > 1 else {
            return nil
        }
        let urlPath = urlArray[1]
        return dropLeadingSlashes(str: urlPath)
    }
    
    private static func dropLeadingSlashes(str: String) -> String {
        return String(str.drop { $0 == "/"})
    }
    
    private static func dropScheme(urlString: String, scheme: String) -> String {
        let prefix = scheme + "://"
        return String(urlString.dropFirst(prefix.count))
    }

    private static let PADDING_TOP = "top"
    private static let PADDING_LEFT = "left"
    private static let PADDING_BOTTOM = "bottom"
    private static let PADDING_RIGHT = "right"
    
    private static let IN_APP_DISPLAY_OPTION = "displayOption"
    private static let IN_APP_AUTO_EXPAND = "AutoExpand"
    private static let IN_APP_PERCENTAGE = "percentage"
}
