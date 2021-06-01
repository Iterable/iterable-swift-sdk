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
        
        getCategoryId(from: request.content)
        retrieveAttachment(from: request.content)
        
        checkPushCreationCompletion()
    }
    
    @objc override open func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        
        callContentHandler()
    }
    
    // MARK: - Private
    
    private func retrieveAttachment(from content: UNNotificationContent) {
        guard let itblDictionary = content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any],
              let attachmentUrlString = itblDictionary[JsonKey.Payload.attachmentUrl] as? String,
              let url = URL(string: attachmentUrlString) else {
            attachmentRetrievalFinished = true
            return
        }
        
        stopCurrentAttachmentDownloadTask()
        
        attachmentDownloadTask = createAttachmentDownloadTask(url: url)
        attachmentDownloadTask?.resume()
    }
    
    private func createAttachmentDownloadTask(url: URL) -> URLSessionDownloadTask {
        return URLSession.shared.downloadTask(with: url) { [weak self] location, response, error in
            guard let strongSelf = self, error == nil, let response = response, let responseUrl = response.url, let location = location else {
                self?.attachmentRetrievalFinished = true
                return
            }
            
            let attachmentId = UUID().uuidString + ITBNotificationServiceExtension.getAttachmentIdSuffix(response: response, responseUrl: responseUrl)
            let tempFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent(attachmentId)
            
            var attachment: UNNotificationAttachment?
            
            do {
                try FileManager.default.moveItem(at: location, to: tempFileUrl)
                attachment = try UNNotificationAttachment(identifier: attachmentId, url: tempFileUrl, options: nil)
            } catch {
                self?.attachmentRetrievalFinished = true
                return
            }
            
            if let attachment = attachment, let content = strongSelf.bestAttemptContent, let handler = strongSelf.contentHandler {
                content.attachments.append(attachment)
                handler(content)
            } else {
                self?.attachmentRetrievalFinished = true
                return
            }
        }
    }
    
    private func stopCurrentAttachmentDownloadTask() {
        attachmentDownloadTask?.cancel()
        attachmentDownloadTask = nil
    }
    
    private func getCategoryId(from content: UNNotificationContent) {
        guard content.categoryIdentifier.count == 0 else {
            setCategoryId(id: content.categoryIdentifier)
            return
        }
        
        guard let itblPayload = content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any],
              let messageId = itblPayload[JsonKey.Payload.messageId] as? String else {
            setCategoryId(id: "")
            return
        }
        
        messageCategory = UNNotificationCategory(identifier: messageId,
                                                 actions: getNotificationActions(payload: itblPayload, content: content),
                                                 intentIdentifiers: [],
                                                 options: [])
        
        if let messageCategory = messageCategory {
            UNUserNotificationCenter.current().getNotificationCategories { [weak self] categories in
                var newCategories = categories
                newCategories.insert(messageCategory)
                UNUserNotificationCenter.current().setNotificationCategories(newCategories)
                self?.setCategoryId(id: messageId)
            }
        } else {
            setCategoryId(id: messageId)
        }
    }
    
    private func setCategoryId(id: String) {
        // IMPORTANT: need to add this to the documentation
        bestAttemptContent?.categoryIdentifier = id
        
        // for some reason, the check needs to be put into this dispatch
        // to function properly for rich pushes with buttons but no image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.getCategoryIdFinished = true
        }
    }
    
    private func createNotificationActionButton(buttonDictionary: [AnyHashable: Any]) -> UNNotificationAction? {
        guard let identifier = buttonDictionary[JsonKey.ActionButton.identifier] as? String else { return nil }
        guard let title = buttonDictionary[JsonKey.ActionButton.title] as? String else { return nil }
        
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
        if let buttonType = buttonDictionary[JsonKey.ActionButton.buttonType] as? String {
            if buttonType == IterableButtonTypeTextInput || buttonType == IterableButtonTypeDestructive {
                return buttonType
            }
        }
        
        return IterableButtonTypeDefault
    }
    
    private func getNotificationActions(payload: [AnyHashable: Any], content: UNNotificationContent) -> [UNNotificationAction] {
        var actionButtons: [[AnyHashable: Any]] = []
        
        if let actionButtonsFromItblPayload = payload[JsonKey.Payload.actionButtons] as? [[AnyHashable: Any]] {
            actionButtons = actionButtonsFromItblPayload
        } else {
            #if DEBUG
            if let actionButtonsFromUserInfo = content.userInfo[JsonKey.Payload.actionButtons] as? [[AnyHashable: Any]] {
                actionButtons = actionButtonsFromUserInfo
            }
            #endif
        }
        
        return actionButtons.compactMap { createNotificationActionButton(buttonDictionary: $0) }
    }
    
    private func checkPushCreationCompletion() {
        if getCategoryIdFinished && attachmentRetrievalFinished {
            callContentHandler()
        }
    }
    
    private func callContentHandler() {
        stopCurrentAttachmentDownloadTask()
        
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private static func getAttachmentIdSuffix(response: URLResponse, responseUrl: URL) -> String {
        if let suggestedFilename = response.suggestedFilename {
            return suggestedFilename
        }
        
        return responseUrl.lastPathComponent
    }
    
    private var getCategoryIdFinished: Bool = false {
        didSet {
            checkPushCreationCompletion()
        }
    }
    
    private var attachmentRetrievalFinished: Bool = false {
        didSet {
            checkPushCreationCompletion()
        }
    }
    
    private var messageCategory: UNNotificationCategory?
    private var attachmentDownloadTask: URLSessionDownloadTask?
    private let IterableButtonTypeDefault = "default"
    private let IterableButtonTypeDestructive = "destructive"
    private let IterableButtonTypeTextInput = "textInput"
}
