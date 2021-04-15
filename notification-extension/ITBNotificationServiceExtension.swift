//
//  Copyright © 2018 Iterable. All rights reserved.
//

import UserNotifications

@objc open class ITBNotificationServiceExtension: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    @objc override open func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // IMPORTANT: need to add this to the documentation
        bestAttemptContent?.categoryIdentifier = getCategory(fromContent: request.content)
        
        guard let itblDictionary = request.content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any] else {
            callContentHandler()
            return
        }
        
        retrieveAttachment(itblDictionary: itblDictionary)
    }
    
    @objc override open func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        
        callContentHandler()
    }
    
    // MARK: - Private
    
    private func retrieveAttachment(itblDictionary: [AnyHashable: Any]) {
        guard let attachmentUrlString = itblDictionary[JsonKey.Payload.attachmentUrl] as? String else { return }
        guard let url = URL(string: attachmentUrlString) else { return }
        
        attachmentDownloadTask = createAttachmentDownloadTask(url: url)
        attachmentDownloadTask?.resume()
    }
    
    private func createAttachmentDownloadTask(url: URL) -> URLSessionDownloadTask {
        return URLSession.shared.downloadTask(with: url) { [weak self] location, response, error in
            guard let strongSelf = self, error == nil, let response = response, let responseUrl = response.url, let location = location else {
                self?.callContentHandler()
                return
            }
            
            let attachmentId = UUID().uuidString + ITBNotificationServiceExtension.getAttachmentIdSuffix(response: response, responseUrl: responseUrl)
            let tempFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(attachmentId)
            
            var attachment: UNNotificationAttachment?
            
            do {
                try FileManager.default.moveItem(at: location, to: tempFileUrl)
                attachment = try UNNotificationAttachment(identifier: attachmentId, url: tempFileUrl, options: nil)
            } catch {
                self?.callContentHandler()
                return
            }
            
            if let attachment = attachment, let content = strongSelf.bestAttemptContent, let handler = strongSelf.contentHandler {
                content.attachments.append(attachment)
                handler(content)
            } else {
                self?.callContentHandler()
                return
            }
        }
    }
    
    private func callContentHandler() {
        attachmentDownloadTask?.cancel()
        attachmentDownloadTask = nil
        
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func getCategory(fromContent content: UNNotificationContent) -> String {
        guard content.categoryIdentifier.count == 0 else {
            return content.categoryIdentifier
        }
        
        guard let itblDictionary = content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any],
              let messageId = itblDictionary[JsonKey.Payload.messageId] as? String else {
            return ""
        }
        
        var actionButtons: [[AnyHashable: Any]] = []
        
        if let actionButtonsFromITBLPayload = itblDictionary[JsonKey.Payload.actionButtons] as? [[AnyHashable: Any]] {
            actionButtons = actionButtonsFromITBLPayload
        } else {
            #if DEBUG
            if let actionButtonsFromUserInfo = content.userInfo[JsonKey.Payload.actionButtons] as? [[AnyHashable: Any]] {
                actionButtons = actionButtonsFromUserInfo
            }
            #endif
        }
        
        var notificationActions = [UNNotificationAction]()

        for actionButton in actionButtons {
            if let notificationAction = createNotificationActionButton(buttonDictionary: actionButton) {
                notificationActions.append(notificationAction)
            }
        }
        
        messageCategory = UNNotificationCategory(identifier: messageId, actions: notificationActions, intentIdentifiers: [], options: [])
        
        if let messageCategory = messageCategory {
            UNUserNotificationCenter.current().getNotificationCategories { categories in
                var newCategories = categories
                newCategories.insert(messageCategory)
                UNUserNotificationCenter.current().setNotificationCategories(newCategories)
            }
        }
        
        return messageId
    }
    
    private func createNotificationActionButton(buttonDictionary: [AnyHashable: Any]) -> UNNotificationAction? {
        guard let identifier = buttonDictionary[JsonKey.ActionButton.identifier] as? String,
              let title = buttonDictionary[JsonKey.ActionButton.title] as? String else {
            return nil
        }
        
        let buttonType = getButtonType(buttonDictionary: buttonDictionary)
        var openApp = true
        
        if let openAppFromDict = buttonDictionary[JsonKey.ActionButton.openApp] as? NSNumber {
            openApp = openAppFromDict.boolValue
        }
        
        var requiresUnlock = false
        
        if let requiresUnlockFromDict = buttonDictionary[JsonKey.ActionButton.requiresUnlock] as? NSNumber {
            requiresUnlock = requiresUnlockFromDict.boolValue
        }
        
        var actionOptions: UNNotificationActionOptions = []
        
        if buttonType == IterableButtonTypeDestructive {
            actionOptions.insert(.destructive)
        }
        
        if openApp {
            actionOptions.insert(.foreground)
        }
        
        if requiresUnlock || openApp {
            actionOptions.insert(.authenticationRequired)
        }
        
        if buttonType == IterableButtonTypeTextInput {
            let inputTitle = buttonDictionary[JsonKey.ActionButton.inputTitle] as? String ?? ""
            let inputPlaceholder = buttonDictionary[JsonKey.ActionButton.inputPlaceholder] as? String ?? ""
            
            return UNTextInputNotificationAction(identifier: identifier,
                                                 title: title,
                                                 options: actionOptions,
                                                 textInputButtonTitle: inputTitle,
                                                 textInputPlaceholder: inputPlaceholder)
        } else {
            return UNNotificationAction(identifier: identifier, title: title, options: actionOptions)
        }
    }
    
    private func getButtonType(buttonDictionary: [AnyHashable: Any]) -> String {
        guard let buttonType = buttonDictionary[JsonKey.ActionButton.buttonType] as? String else {
            return IterableButtonTypeDefault
        }
        
        if buttonType == IterableButtonTypeTextInput || buttonType == IterableButtonTypeDestructive {
            return buttonType
        }
        
        return IterableButtonTypeDefault
    }
    
    private static func getAttachmentIdSuffix(response: URLResponse, responseUrl: URL) -> String {
        if let suggestedFilename = response.suggestedFilename {
            return suggestedFilename
        }
        
        return responseUrl.lastPathComponent
    }
    
    private var messageCategory: UNNotificationCategory?
    private var attachmentDownloadTask: URLSessionDownloadTask?
    private let IterableButtonTypeDefault = "default"
    private let IterableButtonTypeDestructive = "destructive"
    private let IterableButtonTypeTextInput = "textInput"
}
