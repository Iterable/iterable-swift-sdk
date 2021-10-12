//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public enum JsonKey {
    public enum ActionButton {
        static let identifier = "identifier"
        static let buttonType = "buttonType"
        static let title = "title"
        static let openApp = "openApp"
        static let requiresUnlock = "requiresUnlock"
        static let inputTitle = "inputTitle"
        static let inputPlaceholder = "inputPlaceholder"
        static let actionIcon = "actionIcon"
    }
    
    public enum Payload {
        static let metadata = "itbl"
        static let messageId = "messageId"
        static let deepLinkUrl = "url"
        static let attachmentUrl = "attachment-url"
        static let actionButtons = "actionButtons"
        static let defaultAction = "defaultAction"
    }
}
