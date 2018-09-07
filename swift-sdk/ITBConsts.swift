//
//  ITBConsts.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objcMembers public class ITBConsts : NSObject {
    // the API endpoint
    public static let apiEndpoint = apiHostname + "/api/"
    public static let linksEndpoint = linksHostname + "/"

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
    
    public class Device {
        public static let localizedModel = ITBL_DEVICE_LOCALIZED_MODEL
        public static let identifierForVendor = ITBL_DEVICE_ID_VENDOR
        public static let model = ITBL_DEVICE_MODEL
        public static let systemName = ITBL_DEVICE_SYSTEM_NAME
        public static let systemVersion = ITBL_DEVICE_SYSTEM_VERSION
        public static let userInterfaceIdiom = ITBL_DEVICE_USER_INTERFACE
        public static let deviceId = "deviceId"
        public static let appPackageName = "appPackageName"
        public static let appVersion = "appVersion"
        public static let appBuild = "appBuild"
        public static let sdkVersion = "sdkVersion"
    }

    private static let apiHostname = "https://api.iterable.com"
    private static let linksHostname = "https://links.iterable.com"
}
