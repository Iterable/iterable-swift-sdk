//
//  Copyright © 2018 Iterable. All rights reserved.
//

import UserNotifications

@objc open class ITBNotificationServiceExtension: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    @objc override open func didReceive(_ request: UNNotificationRequest,
                                        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        resolveCategory(from: request.content)

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
        guard let metadata = content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any],
              let attachmentUrlString = metadata[JsonKey.Payload.attachmentUrl] as? String,
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
            
            let attachmentId = UUID().uuidString + ITBNotificationServiceExtension.getAttachmentIdSuffix(response: response,
                                                                                                         responseUrl: responseUrl)
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
    
    /// If a category id can be obtained from the message content, we set `categoryId` to the value obtained from message.
    /// Otherwise, if a messageId is present in the content, we create a new category with the messageId
    /// and add this newly created category to list of system categories.
    /// After that we set `categoryId` to messageId.
    private func resolveCategory(from content: UNNotificationContent) {
        guard content.categoryIdentifier.count == 0 else {
            setCategoryId(id: content.categoryIdentifier)
            return
        }
        guard let messageId = NotificationContentParser.getIterableMessageId(from: content) else {
            setCategoryId(id: "")
            return
        }

        let category = UNNotificationCategory(identifier: messageId,
                                              actions: NotificationContentParser.getNotificationActions(from: content),
                                              intentIdentifiers: [],
                                              options: [])

        Self.createCategory(category: category, afterCategoryCreated: { [weak self] in self?.setCategoryId(id: messageId) })
    }
    
    private static func createCategory(category: UNNotificationCategory, afterCategoryCreated: (() -> Void)?) {
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            var newCategories = categories
            newCategories.insert(category)
            UNUserNotificationCenter.current().setNotificationCategories(newCategories)
            afterCategoryCreated?()
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
}
