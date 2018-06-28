//
//  ITBConsts.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class ITBConsts : NSObject {
    public class Payload {
        public static let metadata = ITBL_PAYLOAD_METADATA
        public static let messageId = ITBL_PAYLOAD_MESSAGE_ID
        public static let deeplinkUrl = ITBL_PAYLOAD_DEEP_LINK_URL
        public static let attachmentUrl = ITBL_PAYLOAD_ATTACHMENT_URL
        public static let actionButtons = ITBL_PAYLOAD_ACTION_BUTTONS
        public static let defaultAction = ITBL_PAYLOAD_DEFAULT_ACTION
    }
    
    public class Button {
        public static let identifier = ITBL_BUTTON_IDENTIFIER
        public static let type = ITBL_BUTTON_TYPE
        public static let title = ITBL_BUTTON_TITLE
        public static let openApp = ITBL_BUTTON_OPEN_APP
        public static let requiresUnlock = ITBL_BUTTON_REQUIRES_UNLOCK
        public static let inputTitle = ITBL_BUTTON_INPUT_TITLE
        public static let inputPlaceholder = ITBL_BUTTON_INPUT_PLACEHOLDER
        public static let action = ITBL_BUTTON_ACTION
    }
}
