//
//  ITBConsts.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class ITBConsts : NSObject {
    // the API endpoint
    public static let apiEndpoint = "https://api.iterable.com/api/"
    
    public class UserDefaults {
        public static let objectTag = ITBL_USER_DEFAULTS_OBJECT_TAG
        public static let expirationTag = ITBL_USER_DEFAULTS_EXPIRATION_TAG
        public static let payloadKey = ITBL_USER_DEFAULTS_PAYLOAD_KEY
        public static let payloadExpirationHours = ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS
        public static let attributionInfoKey = ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY
        public static let attributionInfoExpirationHours = ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS
        public static let emailKey = ITBL_USER_DEFAULTS_EMAIL_KEY
        public static let userIdKey = ITBL_USER_DEFAULTS_USERID_KEY
    }
    
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
