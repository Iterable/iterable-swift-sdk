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
    func onInAppMessagesAvailable(messages: [IterableInAppMessage])
}

///
protocol InAppSynchronizerProtocol {
    var internalApi: IterableAPIInternal? {get set}
    var inAppSyncDelegate: InAppSynchronizerDelegate? {get set}
}

protocol InAppDisplayerProtocol {
    func showInApp(message: IterableInAppMessage, callback: ITEActionBlock?) -> Bool
}

class InAppDisplayer : InAppDisplayerProtocol {
    func showInApp(message: IterableInAppMessage, callback: ITEActionBlock?) -> Bool {
        return InAppHelper.showInApp(message: message, callback: callback)
    }
}

class InAppSynchronizer : InAppSynchronizerProtocol {
    weak var internalApi: IterableAPIInternal?
    weak var inAppSyncDelegate: InAppSynchronizerDelegate?
    
    init() {
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] timer in
                self?.sync(timer: timer)
            }
        } else {
            // Fallback on earlier versions
            Timer.scheduledTimer(timeInterval: syncInterval, target: self, selector: #selector(sync(timer:)), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func sync(timer: Timer) {
        self.timer = timer
        
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
    
    deinit {
        ITBInfo()
        timer?.invalidate()
    }
    
    // in seconds
    private let syncInterval = 1.0
    private let numMessages = 10
    private var timer: Timer?
}


// This is Internal Struct, no public methods
struct InAppHelper {
    /// Shows an inApp message and consumes it from server queue if the message is shown.
    /// - parameter message: The inApp message to show
    /// - parameter callback: the code to execute when user clicks on a link or button on inApp message.
    /// - returns: A Bool indicating whether the inApp was opened.
    @discardableResult fileprivate static func showInApp(message: IterableInAppMessage, callback:ITEActionBlock?) -> Bool {
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
    
    // Given the clicked url in inApp get the callbackUrl and destinationUrl
    static func getCallbackAndDestinationUrl(url: URL) -> (callbackUrl: String, destinationUrl: String)? {
        if url.scheme == UrlScheme.custom.rawValue {
            // Since we are calling loadHTMLString with a nil baseUrl, any request url without a valid scheme get treated as a local resource.
            // Url looks like applewebdata://abc-def/something
            // Removes the extra applewebdata scheme/host data that is appended to the original url.
            // So in this case (callback = something, destination = something)
            // Warn the client that the request url does not contain a valid scheme
            ITBError("Request url contains an invalid scheme: \(url)")
            
            guard let urlPath = getUrlPath(url: url) else {
                return nil
            }
            return (callbackUrl: urlPath, destinationUrl: urlPath)
        } else if url.scheme == UrlScheme.itbl.rawValue {
            // itbl://something => (callback = something, destination = itbl://something)
            let callbackUrl = dropScheme(urlString: url.absoluteString, scheme: UrlScheme.itbl.rawValue)
            return (callbackUrl: callbackUrl, destinationUrl: url.absoluteString)
        } else {
            // http, https etc, return unchanged
            return (url.absoluteString, url.absoluteString)
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
    
    /// This is a struct equivalent of IterableHtmlInAppContent class
    private struct InAppDetails {
        let channelName: String
        let messageId: String
        let campaignId: String
        let edgeInsets: UIEdgeInsets
        let backgroundAlpha: Double
        let html: String
        let extraInfo: [AnyHashable : Any]?
    }

    /// Returns an array of Dictionaries holding inApp messages.
    private static func getInAppDicts(fromPayload payload: [AnyHashable : Any]) -> [[AnyHashable : Any]] {
        return payload[.ITBL_IN_APP_MESSAGE] as? [[AnyHashable : Any]] ?? []
    }
    
    /// Gets the first message from the payload, if one esists or nil if the payload is empty
    static func spawn(inAppNotification callbackBlock: ITEActionBlock?, internalApi: IterableAPIInternal) -> Future<Bool> {
        return internalApi.getInAppMessages(1).map {
            getFirstInAppMessage(fromPayload: $0, internalApi: internalApi).map { showInApp(message: $0, callback: callbackBlock) }
            ?? false
        }
    }
    
    private static func getFirstMessageDict(fromPayload payload: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        let messages = getInAppDicts(fromPayload: payload)
        return messages.count > 0 ? messages[0] : nil
    }
    
    private static func getFirstInAppMessage(fromPayload payload: [AnyHashable : Any], internalApi: IterableAPIInternal) -> IterableInAppMessage? {
        return getFirstMessageDict(fromPayload: payload)
            .map { parseInApp(fromDict: $0) }
            .flatMap { toMessage(fromInAppParseResult: $0, internalApi: internalApi) }
    }

    private static func parseInApps(fromPayload payload: [AnyHashable : Any]) -> [InAppParseResult] {
        return getInAppDicts(fromPayload: payload).map {
            parseInApp(fromDict: $0)
        }
    }

    private static func parseInApp(fromDict dict: [AnyHashable : Any]) -> InAppParseResult {
        guard let content = dict[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(reason: "no message", messageId: nil)
        }
        guard let messageId = dict[.ITBL_KEY_MESSAGE_ID] as? String else {
            return .failure(reason: "no message id", messageId: nil)
        }
        guard let html = content[.ITBL_IN_APP_HTML] as? String else {
            return .failure(reason: "no html", messageId: nil)
        }
        guard html.range(of: AnyHashable.ITBL_IN_APP_HREF, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)", messageId: messageId)
        }

        let campaignId: String
        if let theCampaignId = dict[.ITBL_KEY_CAMPAIGN_ID] as? String {
            campaignId = theCampaignId
        } else {
            ITBDebug("Could not find campaignId") // This is debug level because this happens a lot with proof inApps
            campaignId = ""
        }

        let extraInfo = parseExtraInfo(fromContent: content)
        
        // this is temporary until we fix backend
        let channelName = extraInfo?["channelName"] as? String ?? ""
        
        let inAppDisplaySettings = content[.ITBL_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
        let backgroundAlpha = InAppHelper.getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
        let edgeInsets = InAppHelper.getPadding(fromInAppSettings: inAppDisplaySettings)
        
        return .success(InAppDetails(
            channelName: channelName,
            messageId: messageId,
            campaignId: campaignId,
            edgeInsets: edgeInsets,
            backgroundAlpha: backgroundAlpha,
            html: html,
            extraInfo: extraInfo))
    }
    
    private static func parseExtraInfo(fromContent content: [AnyHashable : Any]) -> [AnyHashable : Any]? {
        return content[.ITBL_IN_APP_PAYLOAD] as? [AnyHashable : Any]
    }
    
    private static func toMessage(fromInAppParseResult inAppParseResult: InAppHelper.InAppParseResult, internalApi: IterableAPIInternal) -> IterableInAppMessage? {
        switch inAppParseResult {
        case .success(let inAppDetails):
            let content = IterableHtmlInAppContent(edgeInsets: inAppDetails.edgeInsets,
                                                   backgroundAlpha: inAppDetails.backgroundAlpha,
                                                   html: inAppDetails.html)
            return IterableInAppMessage(messageId: inAppDetails.messageId,
                                        campaignId: inAppDetails.campaignId,
                                        channelName: inAppDetails.channelName,
                                        contentType: .html,
                                        content: content,
                                        extraInfo: inAppDetails.extraInfo)
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
        case custom = "applewebdata"
        case itbl = "itbl"
        case other
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
