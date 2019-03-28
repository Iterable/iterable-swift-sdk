//
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

// Iterable API Endpoints
public extension String {
    public static let ITBL_ENDPOINT_API = apiHostname + "/api/"
    public static let ITBL_ENDPOINT_LINKS = linksHostname + "/"
    
    private static let apiHostname = "https://api.iterable.com"
    private static let linksHostname = "https://links.iterable.com"
}

// API Paths (Offset from base)
public extension String {
    public static let ITBL_PATH_COMMERCE_TRACK_PURCHASE = "commerce/trackPurchase"
    public static let ITBL_PATH_DISABLE_DEVICE = "users/disableDevice"
    public static let ITBL_PATH_GET_INAPP_MESSAGES = "inApp/getMessages"
    public static let ITBL_PATH_INAPP_CONSUME = "events/inAppConsume"
    public static let ITBL_PATH_REGISTER_DEVICE_TOKEN = "users/registerDeviceToken"
    public static let ITBL_PATH_TRACK = "events/track"
    public static let ITBL_PATH_TRACK_INAPP_CLICK = "events/trackInAppClick"
    public static let ITBL_PATH_TRACK_INAPP_OPEN = "events/trackInAppOpen"
    public static let ITBL_PATH_TRACK_PUSH_OPEN = "events/trackPushOpen"
    public static let ITBL_PATH_UPDATE_USER = "users/update"
    public static let ITBL_PATH_UPDATE_EMAIL = "users/updateEmail"
    public static let ITBL_PATH_UPDATE_SUBSCRIPTIONS = "users/updateSubscriptions"
    public static let ITBL_PATH_DDL_MATCH = "a/matchFp" //DDL = Deferred Deep Linking
}

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
    public static let ITBL_KEY_PREFER_USER_ID = "preferUserId"
}

// More Keys
public extension String {
    public static let ITBL_KEY_GET = "GET"
    public static let ITBL_KEY_POST = "POST"
    
    public static let ITBL_KEY_APNS = "APNS"
    public static let ITBL_KEY_APNS_SANDBOX = "APNS_SANDBOX"
    public static let ITBL_KEY_PAD = "Pad"
    public static let ITBL_KEY_PHONE = "Phone"
    public static let ITBL_KEY_UNSPECIFIED = "Unspecified"
}

// Misc Values
public extension String {
    public static let ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID = "default"
    public static let ITBL_PLATFORM_IOS = "iOS"
    public static let ITBL_DEEPLINK_IDENTIFIER = "/a/[a-zA-Z0-9]+"
}

// Decvice Dictionary
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

// Push Payload
public extension AnyHashable {
    public static let ITBL_PAYLOAD_METADATA = "itbl"
    public static let ITBL_PAYLOAD_MESSAGE_ID = "messageId"
    public static let ITBL_PAYLOAD_DEEP_LINK_URL = "url"
    public static let ITBL_PAYLOAD_ATTACHMENT_URL = "attachment-url"
    public static let ITBL_PAYLOAD_ACTION_BUTTONS = "actionButtons"
    public static let ITBL_PAYLOAD_DEFAULT_ACTION = "defaultAction"
}

// UserDefaults String Consts
public extension String {
    public static let ITBL_USER_DEFAULTS_PAYLOAD_KEY = "itbl_payload_key"
    public static let ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY = "itbl_attribution_info_key"
    public static let ITBL_USER_DEFAULTS_EMAIL_KEY = "itbl_email"
    public static let ITBL_USER_DEFAULTS_USERID_KEY = "itbl_userid"
    public static let ITBL_USER_DEFAULTS_DDL_CHECKED = "itbl_ddl_checked"
    public static let ITBL_USER_DEFAULTS_DEVICE_ID = "itbl_device_id"
    public static let ITBL_USER_DEFAULTS_SDK_VERSION = "itbl_sdk_version"
}

// UserDefaults Int Consts
public extension Int {
    public static let ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS = 24
    public static let ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS = 24
}

//Action Buttons
public extension AnyHashable {
    public static let ITBL_BUTTON_IDENTIFIER = "identifier"
    public static let ITBL_BUTTON_TYPE = "buttonType"
    public static let ITBL_BUTTON_TITLE = "title"
    public static let ITBL_BUTTON_OPEN_APP = "openApp"
    public static let ITBL_BUTTON_REQUIRES_UNLOCK = "requiresUnlock"
    public static let ITBL_BUTTON_INPUT_TITLE = "inputTitle"
    public static let ITBL_BUTTON_INPUT_PLACEHOLDER = "inputPlaceholder"
    public static let ITBL_BUTTON_ACTION = "action"
}

//In-App Constants
public extension AnyHashable {
    public static let ITBL_IN_APP_CLICKED_URL = "clickedUrl"
    
    public static let ITBL_IN_APP_BUTTON_INDEX = "buttonIndex"
    public static let ITBL_IN_APP_MESSAGE = "inAppMessages"
    
    public static let ITBL_IN_APP_CONTENT = "content"
    
    //In-App HTML Constants
    public static let ITBL_IN_APP_BACKGROUND_ALPHA = "backgroundAlpha"
    public static let ITBL_IN_APP_HTML = "html"
    public static let ITBL_IN_APP_HREF = "href"
    public static let ITBL_IN_APP_DISPLAY_SETTINGS = "inAppDisplaySettings"
}

