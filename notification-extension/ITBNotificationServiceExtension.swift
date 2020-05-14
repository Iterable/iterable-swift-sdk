//
//  Created by Tapash Majumder on 6/8/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UserNotifications

@objc open class ITBNotificationServiceExtension: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    @objc open override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // IMPORTANT: need to add this to the documentation
        bestAttemptContent?.categoryIdentifier = getCategory(fromContent: request.content)
        
        guard let itblDictionary = request.content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any] else {
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
            
            return
        }
        
        var contentHandlerCalled = false
        contentHandlerCalled = loadAttachment(itblDictionary: itblDictionary)
        
        if !contentHandlerCalled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let bestAttemptContent = self.bestAttemptContent {
                    contentHandler(bestAttemptContent)
                }
            }
        }
    }
    
    @objc open override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func loadAttachment(itblDictionary: [AnyHashable: Any]) -> Bool {
        guard let attachmentUrlString = itblDictionary[JsonKey.Payload.attachmentUrl] as? String else { return false }
        guard let url = URL(string: attachmentUrlString) else { return false }
        
        let downloadTask = URLSession.shared.downloadTask(with: url, completionHandler: { [weak self] location, response, error in
            guard let strongSelf = self else { return }
            
            if error == nil, let response = response, let responseUrl = response.url, let location = location {
                let tempDirectoryUrl = FileManager.default.temporaryDirectory
                var attachmentIdString = UUID().uuidString + responseUrl.lastPathComponent
                if let suggestedFilename = response.suggestedFilename {
                    attachmentIdString = UUID().uuidString + suggestedFilename
                }
                
                var attachment: UNNotificationAttachment?
                let tempFileUrl = tempDirectoryUrl.appendingPathComponent(attachmentIdString)
                do {
                    try FileManager.default.moveItem(at: location, to: tempFileUrl)
                    attachment = try UNNotificationAttachment(identifier: attachmentIdString, url: tempFileUrl, options: nil)
                } catch { /* TODO: FileManager or attachment error */ }
                
                if let attachment = attachment, let bestAttemptContent = strongSelf.bestAttemptContent, let contentHandler = strongSelf.contentHandler {
                    bestAttemptContent.attachments.append(attachment)
                    contentHandler(bestAttemptContent)
                }
            } else { /* TODO: handle download error */ }
        })
        
        downloadTask.resume()
        return true
    }
    
    private func getCategory(fromContent content: UNNotificationContent) -> String {
        if content.categoryIdentifier.count == 0 {
            guard let itblDictionary = content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any] else {
                return ""
            }
            
            guard let messageId = itblDictionary[JsonKey.Payload.messageId] as? String else {
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
        } else {
            return content.categoryIdentifier
        }
    }
    
    private func createNotificationActionButton(buttonDictionary: [AnyHashable: Any]) -> UNNotificationAction? {
        guard let identifier = buttonDictionary[JsonKey.ActionButton.identifier] as? String else {
            return nil
        }
        
        guard let title = buttonDictionary[JsonKey.ActionButton.title] as? String else {
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
        } else {
            return IterableButtonTypeDefault
        }
    }
    
    private var messageCategory: UNNotificationCategory?
    private let IterableButtonTypeDefault = "default"
    private let IterableButtonTypeDestructive = "destructive"
    private let IterableButtonTypeTextInput = "textInput"
}
