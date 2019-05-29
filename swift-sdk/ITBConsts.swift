//
//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

// Iterable API Endpoints
public extension String {
    static let ITBL_ENDPOINT_API = apiHostname + "/api/"
    static let ITBL_ENDPOINT_LINKS = linksHostname + "/"
    
    private static let apiHostname = "https://api.iterable.com"
    private static let linksHostname = "https://links.iterable.com"
}

// API Paths (Offset from base)
public extension String {
    static let ITBL_PATH_COMMERCE_TRACK_PURCHASE = "commerce/trackPurchase"
    static let ITBL_PATH_DISABLE_DEVICE = "users/disableDevice"
    static let ITBL_PATH_GET_INAPP_MESSAGES = "inApp/getMessages"
    static let ITBL_PATH_INAPP_CONSUME = "events/inAppConsume"
    static let ITBL_PATH_REGISTER_DEVICE_TOKEN = "users/registerDeviceToken"
    static let ITBL_PATH_TRACK = "events/track"
    static let ITBL_PATH_TRACK_INAPP_CLICK = "events/trackInAppClick"
    static let ITBL_PATH_TRACK_INAPP_OPEN = "events/trackInAppOpen"
    static let ITBL_PATH_TRACK_PUSH_OPEN = "events/trackPushOpen"
    static let ITBL_PATH_UPDATE_USER = "users/update"
    static let ITBL_PATH_UPDATE_EMAIL = "users/updateEmail"
    static let ITBL_PATH_UPDATE_SUBSCRIPTIONS = "users/updateSubscriptions"
    static let ITBL_PATH_DDL_MATCH = "a/matchFp" //DDL = Deferred Deep Linking
}

// Keys
public extension AnyHashable {
    static let ITBL_KEY_API_KEY = "api_key"
    static let ITBL_KEY_APPLICATION_NAME = "applicationName"
    static let ITBL_KEY_CAMPAIGN_ID = "campaignId"
    static let ITBL_KEY_COUNT = "count"
    static let ITBL_KEY_CURRENT_EMAIL = "currentEmail"
    static let ITBL_KEY_CURRENT_USER_ID = "currentUserId"
    static let ITBL_KEY_DATA_FIELDS = "dataFields"
    static let ITBL_KEY_DEVICE = "device"
    static let ITBL_KEY_EMAIL = "email"
    static let ITBL_KEY_EMAIL_LIST_IDS = "emailListIds"
    static let ITBL_KEY_EVENT_NAME = "eventName"
    static let ITBL_KEY_ITEMS = "items"
    static let ITBL_KEY_MERGE_NESTED = "mergeNestedObjects"
    static let ITBL_KEY_MESSAGE_ID = "messageId"
    static let ITBL_KEY_NEW_EMAIL = "newEmail"
    static let ITBL_KEY_PLATFORM = "platform"
    static let ITBL_KEY_PACKAGE_NAME = "packageName"
    static let ITBL_KEY_SDK_VERSION = "SDKVersion"
    static let ITBL_KEY_TOKEN = "token"
    static let ITBL_KEY_TEMPLATE_ID = "templateId"
    static let ITBL_KEY_TOTAL = "total"
    static let ITBL_KEY_UNSUB_CHANNEL = "unsubscribedChannelIds"
    static let ITBL_KEY_UNSUB_MESSAGE = "unsubscribedMessageTypeIds"
    static let ITBL_KEY_USER = "user"
    static let ITBL_KEY_USER_ID = "userId"
    static let ITBL_KEY_ACTION_IDENTIFIER = "actionIdentifier"
    static let ITBL_KEY_USER_TEXT = "userText"
    static let ITBL_KEY_PREFER_USER_ID = "preferUserId"
}

// More Keys
public extension String {
    static let ITBL_KEY_GET = "GET"
    static let ITBL_KEY_POST = "POST"
    
    static let ITBL_KEY_APNS = "APNS"
    static let ITBL_KEY_APNS_SANDBOX = "APNS_SANDBOX"
    static let ITBL_KEY_PAD = "Pad"
    static let ITBL_KEY_PHONE = "Phone"
    static let ITBL_KEY_UNSPECIFIED = "Unspecified"
}

// Misc Values
public extension String {
    static let ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID = "default"
    static let ITBL_PLATFORM_IOS = "iOS"
    static let ITBL_DEEPLINK_IDENTIFIER = "/a/[a-zA-Z0-9]+"
}

// Device Dictionary
public extension String {
    static let ITBL_DEVICE_LOCALIZED_MODEL = "localizedModel"
    static let ITBL_DEVICE_ID_VENDOR = "identifierForVendor"
    static let ITBL_DEVICE_MODEL = "model"
    static let ITBL_DEVICE_SYSTEM_NAME = "systemName"
    static let ITBL_DEVICE_SYSTEM_VERSION = "systemVersion"
    static let ITBL_DEVICE_USER_INTERFACE = "userInterfaceIdiom"

    static let ITBL_DEVICE_DEVICE_ID = "deviceId"
    static let ITBL_DEVICE_APP_PACKAGE_NAME = "appPackageName"
    static let ITBL_DEVICE_APP_VERSION = "appVersion"
    static let ITBL_DEVICE_APP_BUILD = "appBuild"
    static let ITBL_DEVICE_NOTIFICATIONS_ENABLED = "notificationsEnabled"
    static let ITBL_DEVICE_ITERABLE_SDK_VERSION = "iterableSdkVersion"
}

// Push Payload
public extension AnyHashable {
    static let ITBL_PAYLOAD_METADATA = "itbl"
    static let ITBL_PAYLOAD_MESSAGE_ID = "messageId"
    static let ITBL_PAYLOAD_DEEP_LINK_URL = "url"
    static let ITBL_PAYLOAD_ATTACHMENT_URL = "attachment-url"
    static let ITBL_PAYLOAD_ACTION_BUTTONS = "actionButtons"
    static let ITBL_PAYLOAD_DEFAULT_ACTION = "defaultAction"
}

// UserDefaults String Consts
public extension String {
    static let ITBL_USER_DEFAULTS_PAYLOAD_KEY = "itbl_payload_key"
    static let ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_KEY = "itbl_attribution_info_key"
    static let ITBL_USER_DEFAULTS_EMAIL_KEY = "itbl_email"
    static let ITBL_USER_DEFAULTS_USERID_KEY = "itbl_userid"
    static let ITBL_USER_DEFAULTS_DDL_CHECKED = "itbl_ddl_checked"
    static let ITBL_USER_DEFAULTS_DEVICE_ID = "itbl_device_id"
    static let ITBL_USER_DEFAULTS_SDK_VERSION = "itbl_sdk_version"
}

// UserDefaults Int Consts
public extension Int {
    static let ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS = 24
    static let ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS = 24
}

//Action Buttons
public extension AnyHashable {
    static let ITBL_BUTTON_IDENTIFIER = "identifier"
    static let ITBL_BUTTON_TYPE = "buttonType"
    static let ITBL_BUTTON_TITLE = "title"
    static let ITBL_BUTTON_OPEN_APP = "openApp"
    static let ITBL_BUTTON_REQUIRES_UNLOCK = "requiresUnlock"
    static let ITBL_BUTTON_INPUT_TITLE = "inputTitle"
    static let ITBL_BUTTON_INPUT_PLACEHOLDER = "inputPlaceholder"
    static let ITBL_BUTTON_ACTION = "action"
}

//In-App Constants
public extension AnyHashable {
    static let ITBL_IN_APP_CLICKED_URL = "clickedUrl"
    
    static let ITBL_IN_APP_BUTTON_INDEX = "buttonIndex"
    static let ITBL_IN_APP_MESSAGE = "inAppMessages"
    
    static let ITBL_IN_APP_TRIGGER = "trigger"
    static let ITBL_IN_APP_TRIGGER_TYPE = "type"

    static let ITBL_IN_APP_CONTENT = "content"
    
    //In-App HTML Constants
    static let ITBL_IN_APP_BACKGROUND_ALPHA = "backgroundAlpha"
    static let ITBL_IN_APP_HTML = "html"
    static let ITBL_IN_APP_HREF = "href"
    static let ITBL_IN_APP_DISPLAY_SETTINGS = "inAppDisplaySettings"
    static let ITBL_IN_APP_CUSTOM_PAYLOAD = "customPayload"
    static let ITBL_IN_APP_SAVE_TO_INBOX = "saveToInbox"
    static let ITBL_IN_APP_CONTENT_TYPE = "type"
    static let ITBL_IN_APP_INBOX_METADATA = "inboxMetadata"
}

public enum JsonKey : String {
    // Inbox Message
    case inboxTitle = "title"
    case inboxSubtitle = "subtitle"
    case inboxIcon = "icon"
    
    case inboxExpiresAt = "expiresAt"
    case inboxCreatedAt = "createdAt"
}

// These are custom action for "iterable://delete" etc.
public enum IterableCustomActionName : String, CaseIterable {
    case dismiss
    case delete
}
