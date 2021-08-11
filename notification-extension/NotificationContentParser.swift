//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation
import UserNotifications.UNNotificationContent

struct NotificationContentParser {
    static func getIterableMetadata(from content: UNNotificationContent) -> [AnyHashable: Any]? {
        content.userInfo[JsonKey.Payload.metadata] as? [AnyHashable: Any]
    }

    static func getIterableMessageId(from content: UNNotificationContent) -> String? {
        guard let metadata = getIterableMetadata(from: content) else {
            return nil
        }

        return metadata[JsonKey.Payload.messageId] as? String
    }

    static func getNotificationActions(from content: UNNotificationContent) -> [UNNotificationAction] {
        getActionButtonsJsonArray(from: content)
            .compactMap { createNotificationActionButton(from: $0) }
    }

    private static func getActionButtonsJsonArray(from content: UNNotificationContent) -> [[AnyHashable: Any]] {
        var jsonArray: [[AnyHashable: Any]] = []
        if let metadata = getIterableMetadata(from: content),
           let actionButtonsFromMetadata = metadata[JsonKey.Payload.actionButtons] as? [[AnyHashable: Any]] {
            jsonArray = actionButtonsFromMetadata
        } else {
            #if DEBUG
            if let actionButtonsFromUserInfo = content.userInfo[JsonKey.Payload.actionButtons] as? [[AnyHashable: Any]] {
                jsonArray = actionButtonsFromUserInfo
            }
            #endif
        }
        return jsonArray
    }

    private static func createNotificationActionButton(from json: [AnyHashable: Any]) -> UNNotificationAction? {
        guard let identifier = json[JsonKey.ActionButton.identifier] as? String else { return nil }
        guard let title = json[JsonKey.ActionButton.title] as? String else { return nil }
        
        let buttonType = getButtonType(info: json)
        let openApp = getBoolValue(json[JsonKey.ActionButton.openApp]) ?? true
        let requiresUnlock = getBoolValue(json[JsonKey.ActionButton.requiresUnlock]) ?? false
        
        let options = getActionButtonOptions(buttonType: buttonType,
                                             openApp: openApp,
                                             requiresUnlock: requiresUnlock)
        
        guard buttonType == IterableButtonTypeTextInput else {
            return UNNotificationAction(identifier: identifier, title: title, options: options)
        }
        
        let inputTitle = json[JsonKey.ActionButton.inputTitle] as? String ?? ""
        let inputPlaceholder = json[JsonKey.ActionButton.inputPlaceholder] as? String ?? ""
        
        return UNTextInputNotificationAction(identifier: identifier,
                                             title: title,
                                             options: options,
                                             textInputButtonTitle: inputTitle,
                                             textInputPlaceholder: inputPlaceholder)
    }

    private static func getButtonType(info: [AnyHashable: Any]) -> String {
        if let buttonType = info[JsonKey.ActionButton.buttonType] as? String {
            if buttonType == IterableButtonTypeTextInput || buttonType == IterableButtonTypeDestructive {
                return buttonType
            }
        }
        
        return IterableButtonTypeDefault
    }

    private static func getBoolValue(_ value: Any?) -> Bool? {
        return (value as? NSNumber)?.boolValue
    }

    private static func getActionButtonOptions(buttonType: String, openApp: Bool, requiresUnlock: Bool) -> UNNotificationActionOptions {
        var options: UNNotificationActionOptions = []
        
        if buttonType == IterableButtonTypeDestructive {
            options.insert(.destructive)
        }
        
        if openApp {
            options.insert(.foreground)
        }
        
        if requiresUnlock || openApp {
            options.insert(.authenticationRequired)
        }
        
        return options
    }

    private static let IterableButtonTypeDefault = "default"
    private static let IterableButtonTypeDestructive = "destructive"
    private static let IterableButtonTypeTextInput = "textInput"
}
