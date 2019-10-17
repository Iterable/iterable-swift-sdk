//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

// Iterable API Endpoints
enum Endpoint {
    static let api = String.ITBL_ENDPOINT_API
    static let links = String.ITBL_ENDPOINT_LINKS
}

public extension String {
    static let ITBL_API_PATH = "/api/"
    static let ITBL_ENDPOINT_API = apiHostname + ITBL_API_PATH
    static let ITBL_ENDPOINT_LINKS = linksHostname + "/"
    
    private static let apiHostname = "https://api.iterable.com"
    private static let linksHostname = "https://links.iterable.com"
}

// UserDefaults Int Consts
public extension Int {
    static let ITBL_USER_DEFAULTS_PAYLOAD_EXPIRATION_HOURS = 24
    static let ITBL_USER_DEFAULTS_ATTRIBUTION_INFO_EXPIRATION_HOURS = 24
}

//let apiHostName = "https://api.iterable.com"
//let linksHostName = "https://links.iterable.com"

public enum Const: String {
    case apiPath = "/api/"
//    case endpointApi = apiHostName + apiPath
//    case endpointLinks = linksHostName + "/"
    
    case get = "GET"
    case post = "POST"
    
    case deepLinkRegex = "/a/[a-zA-Z0-9]+"
    
    case href
    
    public enum Path: String {
        case trackPurchase = "commerce/trackPurchase"
        case disableDevice = "users/disableDevice"
        case getInAppMessages = "inApp/getMessages"
        case inAppConsume = "events/inAppConsume"
        case registerDeviceToken = "users/registerDeviceToken"
        case trackEvent = "events/track"
        case trackInAppClick = "events/trackInAppClick"
        case trackInAppOpen = "events/trackInAppOpen"
        case trackInAppClose = "events/trackInAppClose"
        case trackInAppDelivery = "events/trackInAppDelivery"
        case trackPushOpen = "events/trackPushOpen"
        case trackInboxSession = "events/trackInboxSession"
        case updateUser = "users/update"
        case updateEmail = "users/updateEmail"
        case updateSubscriptions = "users/updateSubscriptions"
        case ddlMatch = "a/matchFp" // DDL = Deferred Deep Linking
    }
    
    public enum UserDefaults: String {
        case payloadKey = "itbl_payload_key"
        case attributionInfoKey = "itbl_attribution_info_key"
        case emailKey = "itbl_email"
        case userIdKey = "itbl_userid"
        case ddlChecked = "itbl_ddl_checked"
        case deviceId = "itbl_device_id"
        case sdkVersion = "itbl_sdk_version"
    }
}

public protocol JsonKeyValueRepresentable {
    var key: JsonKeyRepresentable { get }
    var value: JsonValueRepresentable { get }
}

public struct JsonKeyValue: JsonKeyValueRepresentable {
    public let key: JsonKeyRepresentable
    public let value: JsonValueRepresentable
}

public protocol JsonKeyRepresentable {
    var jsonKey: String { get }
}

public enum JsonKey: String, JsonKeyRepresentable {
    case email
    case userId
    case currentEmail
    case currentUserId
    case newEmail
    case emailListIds
    case unsubscribedChannelIds
    case unsubscribedMessageTypeIds
    case preferUserId
    
    case mergeNestedObjects
    
    case inboxMetadata
    case inboxTitle = "title"
    case inboxSubtitle = "subtitle"
    case inboxIcon = "icon"
    
    case inboxExpiresAt = "expiresAt"
    case inboxCreatedAt = "createdAt"
    
    case inAppMessageContext = "messageContext"
    
    case campaignId
    case templateId
    case messageId
    
    case saveToInbox
    case silentInbox
    case inAppLocation = "location"
    case clickedUrl
    
    case inboxSessionStart
    case inboxSessionEnd
    case startTotalMessageCount
    case startUnreadMessageCount
    case endTotalMessageCount
    case endUnreadMessageCount
    case impressions
    case closeAction
    case deleteAction
    
    case url
    
    case device
    case token
    case dataFields
    case deviceInfo
    case identifierForVendor
    case deviceId
    case localizedModel
    case model
    case userInterfaceIdiom
    case systemName
    case systemVersion
    case platform
    case appPackageName
    case appVersion
    case appBuild
    case applicationName
    case eventName
    case actionIdentifier
    case userText
    
    case html
    
    case iterableSdkVersion
    
    case notificationsEnabled
    
    case contentType = "Content-Type"
    
    public enum ActionButton: String, JsonKeyRepresentable {
        case identifier
        case buttonType
        case title
        case openApp
        case requiresUnlock
        case inputTitle
        case inputPlaceholder
        case action
        
        public var jsonKey: String {
            return rawValue
        }
    }
    
    public enum Commerce: String, JsonKeyRepresentable {
        case items
        case total
        case user
        
        public var jsonKey: String {
            return rawValue
        }
    }
    
    public enum Device: String, JsonKeyRepresentable {
        case localizedModel
        case vendorId = "identifierForVendor"
        case model
        case systemName
        case systemVersion
        case userInterfaceIdiom
        
        public var jsonKey: String {
            return rawValue
        }
    }
    
    public enum Header: String, JsonKeyRepresentable {
        case apiKey = "Api-Key"
        case sdkVersion = "SDK-Version"
        case sdkPlatform = "SDK-Platform"
        
        public var jsonKey: String {
            return rawValue
        }
    }
    
    public enum InApp: String, JsonKeyRepresentable {
        case trigger
        case type
        case contentType
        case inAppDisplaySettings
        case backgroundAlpha
        case customPayload
        case inAppMessages
        case count
        case packageName
        case sdkVersion = "SDKVersion"
        case content
        
        public var jsonKey: String {
            return rawValue
        }
    }
    
    public enum Payload: String, JsonKeyRepresentable {
        case metadata = "itbl"
        case messageId
        case deepLinkUrl = "url"
        case attachmentUrl = "attachment-url"
        case actionButtons
        case defaultAction
        
        public var jsonKey: String {
            return rawValue
        }
    }
    
    public var jsonKey: String {
        return rawValue
    }
}

public protocol JsonValueRepresentable {
    var jsonValue: Any { get }
}

public enum JsonValue: String, JsonValueRepresentable {
    case applicationJson = "application/json"
    case apnsSandbox = "APNS_SANDBOX"
    case apnsProduction = "APNS"
    case iOS
    
    public enum ActionIdentifier: String, JsonValueRepresentable {
        case pushOpenDefault = "default"
        
        public var jsonValue: Any {
            return rawValue
        }
        
        public var jsonStringValue: String {
            return rawValue
        }
    }
    
    public enum DeviceIdiom: String, JsonValueRepresentable {
        case pad = "Pad"
        case phone = "Phone"
        case carPlay = "CarPlay"
        case tv = "TV"
        case unspecified = "Unspecified"
        
        public var jsonValue: Any {
            return rawValue
        }
        
        public var jsonStringValue: String {
            return rawValue
        }
    }
    
    public var jsonStringValue: String {
        return rawValue
    }
    
    public var jsonValue: Any {
        return rawValue
    }
}

@objc public enum InAppLocation: Int, JsonValueRepresentable {
    case inApp
    case inbox
    case other
    
    public var jsonValue: Any {
        switch self {
        case .inApp:
            return "in-app"
        case .inbox:
            return "inbox"
        case .other:
            return "other"
        }
    }
}

@objc public enum InAppCloseSource: Int, JsonValueRepresentable {
    case back
    case link
    case other
    
    public var jsonValue: Any {
        switch self {
        case .back:
            return "back"
        case .link:
            return "link"
        case .other:
            return "other"
        }
    }
}

@objc public enum InAppDeleteSource: Int, JsonValueRepresentable {
    case inboxSwipe
    case deleteButton
    case other
    
    public var jsonValue: Any {
        switch self {
        case .inboxSwipe:
            return "inbox-swipe"
        case .deleteButton:
            return "delete-button"
        case .other:
            return "other"
        }
    }
}

extension Int: JsonValueRepresentable {
    public var jsonValue: Any {
        return self
    }
}

extension String: JsonValueRepresentable {
    public var jsonValue: Any {
        return self
    }
}

extension Bool: JsonValueRepresentable {
    public var jsonValue: Any {
        return self
    }
}

extension Dictionary: JsonValueRepresentable {
    public var jsonValue: Any {
        return self
    }
}

extension Array: JsonValueRepresentable where Element: JsonValueRepresentable {
    public var jsonValue: Any {
        return self
    }
}

// These are custom action for "iterable://delete" etc.
public enum IterableCustomActionName: String, CaseIterable {
    case dismiss
    case delete
}

public typealias ITEActionBlock = (String?) -> Void
public typealias ITBURLCallback = (URL?) -> Void
public typealias OnSuccessHandler = (_ data: [AnyHashable: Any]?) -> Void
public typealias OnFailureHandler = (_ reason: String?, _ data: Data?) -> Void
