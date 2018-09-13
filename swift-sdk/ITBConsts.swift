//
//  ITBConsts.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

// Keys
public extension AnyHashable {
    public static let ITBL_KEY_API_KEY = "api_key"
    public static let ITBL_KEY_APPLICATION_NAME = "applicationName"
    public static let ITBL_KEY_CAMPAIGN_ID = "campaignId"
    public static let ITBL_KEY_COUNT = "count"
    public static let ITBL_KEY_CURRENT_EMAIL = "currentEmail"
    public static let ITBL_KEY_DATA_FIELDS = "dataFields"
    public static let ITBL_KEY_DEVICE = "device"
    public static let ITBL_KEY_EMAIL = "email"
    public static let ITBL_KEY_EMAIL_LIST_IDS = "emailListIds"
    public static let ITBL_KEY_EVENT_NAME = "eventName"
    public static let ITBL_KEY_ITEMS = "items"
    public static let ITBL_KEY_MERGE_NESTED = "mergeNestedObjects"
    public static let ITBL_KEY_MESSAGE_ID = "messageId"
    public static let ITBL_KEY_NEW_EMAIL = "newEmail"
    public static let ITBL_KEY_PLATFORM = "platform"
    public static let ITBL_KEY_SDK_VERSION = "SDKVersion"
    public static let ITBL_KEY_TOKEN = "token"
    public static let ITBL_KEY_TEMPLATE_ID = "templateId"
    public static let ITBL_KEY_TOTAL = "total"
    public static let ITBL_KEY_UNSUB_CHANNEL = "unsubscribedChannelIds"
    public static let ITBL_KEY_UNSUB_MESSAGE = "unsubscribedMessageTypeIds"
    public static let ITBL_KEY_USER = "user"
    public static let ITBL_KEY_USER_ID = "userId"
    public static let ITBL_KEY_ACTION_IDENTIFIER = "actionIdentifier"
    public static let ITBL_KEY_USER_TEXT = "userText"
}

//Decvice Dictionary
public extension String {
    public static let ITBL_DEVICE_LOCALIZED_MODEL = "localizedModel"
    public static let ITBL_DEVICE_ID_VENDOR = "identifierForVendor"
    public static let ITBL_DEVICE_MODEL = "model"
    public static let ITBL_DEVICE_SYSTEM_NAME = "systemName"
    public static let ITBL_DEVICE_SYSTEM_VERSION = "systemVersion"
    public static let ITBL_DEVICE_USER_INTERFACE = "userInterfaceIdiom"

    public static let ITBL_DEVICE_DEVICE_ID = "deviceId"
    public static let ITBL_DEVICE_APP_PACKAGE_NAME = "appPackageName"
    public static let ITBL_DEVICE_APP_VERSION = "appVersion"
    public static let ITBL_DEVICE_APP_BUILD = "appBuild"
    public static let ITBL_DEVICE_ITERABLE_SDK_VERSION = "iterableSdkVersion"
}

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
    
    private static let apiHostname = "https://api.iterable.com"
    private static let linksHostname = "https://links.iterable.com"
}
