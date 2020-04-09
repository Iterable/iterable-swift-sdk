//
//  Created by Tapash Majumder on 6/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

enum Endpoint {
    private static let apiHostName = "https://api.iterable.com"
    private static let linksHostName = "https://links.iterable.com"
    
    static let api = Endpoint.apiHostName + Const.apiPath
    static let links = linksHostName + "/"
}

public enum Const {
    public static let apiPath = "/api/"
    
    static let deepLinkRegex = "/a/[a-zA-Z0-9]+"
    static let href = "href"
    
    enum Http {
        static let GET = "GET"
        static let POST = "POST"
    }
    
    enum Path {
        static let trackPurchase = "commerce/trackPurchase"
        static let disableDevice = "users/disableDevice"
        static let getInAppMessages = "inApp/getMessages"
        static let inAppConsume = "events/inAppConsume"
        static let registerDeviceToken = "users/registerDeviceToken"
        static let trackEvent = "events/track"
        static let trackInAppClick = "events/trackInAppClick"
        static let trackInAppOpen = "events/trackInAppOpen"
        static let trackInAppClose = "events/trackInAppClose"
        static let trackInAppDelivery = "events/trackInAppDelivery"
        static let trackPushOpen = "events/trackPushOpen"
        static let trackInboxSession = "events/trackInboxSession"
        static let updateUser = "users/update"
        static let updateEmail = "users/updateEmail"
        static let updateSubscriptions = "users/updateSubscriptions"
        static let ddlMatch = "a/matchFp" // DDL = Deferred Deep Linking
    }
    
    public enum UserDefaults {
        static let payloadKey = "itbl_payload_key"
        static let attributionInfoKey = "itbl_attribution_info_key"
        public static let emailKey = "itbl_email"
        static let userIdKey = "itbl_userid"
        static let ddlChecked = "itbl_ddl_checked"
        static let deviceId = "itbl_device_id"
        static let sdkVersion = "itbl_sdk_version"
        
        static let payloadExpiration = 24
        static let attributionInfoExpiration = 24
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
    case subscribedMessageTypeIds
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
    case inboxSessionId
    
    case saveToInbox
    case silentInbox
    case inAppLocation = "location"
    case clickedUrl
    case read
    
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
    case appAlreadyRunning
    
    case html
    
    case iterableSdkVersion
    
    case notificationsEnabled
    
    case contentType = "Content-Type"
    
    public enum ActionButton {
        static let identifier = "identifier"
        static let action = "action"
    }
    
    public enum Commerce {
        static let items = "items"
        static let total = "total"
        static let user = "user"
    }
    
    public enum Device {
        static let localizedModel = "localizedModel"
        static let vendorId = "identifierForVendor"
        static let model = "model"
        static let systemName = "systemName"
        static let systemVersion = "systemVersion"
        static let userInterfaceIdiom = "userInterfaceIdiom"
    }
    
    public enum Header {
        static let apiKey = "Api-Key"
        static let sdkVersion = "SDK-Version"
        static let sdkPlatform = "SDK-Platform"
    }
    
    public enum InApp {
        static let trigger = "trigger"
        static let type = "type"
        static let contentType = "contentType"
        static let inAppDisplaySettings = "inAppDisplaySettings"
        static let backgroundAlpha = "backgroundAlpha"
        static let customPayload = "customPayload"
        static let inAppMessages = "inAppMessages"
        static let count = "count"
        static let packageName = "packageName"
        static let sdkVersion = "SDKVersion"
        static let content = "content"
    }
    
    public enum Payload {
        static let metadata = "itbl"
        static let actionButtons = "actionButtons"
        static let defaultAction = "defaultAction"
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
    
    public enum ActionIdentifier {
        static let pushOpenDefault = "default"
    }
    
    public enum DeviceIdiom {
        static let pad = "Pad"
        static let phone = "Phone"
        static let carPlay = "CarPlay"
        static let tv = "TV"
        static let unspecified = "Unspecified"
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
    
    public var jsonValue: Any {
        switch self {
        case .inApp:
            return "in-app"
        case .inbox:
            return "inbox"
        }
    }
}

@objc public enum InAppCloseSource: Int, JsonValueRepresentable {
    case back
    case link
    
    public var jsonValue: Any {
        switch self {
        case .back:
            return "back"
        case .link:
            return "link"
        }
    }
}

@objc public enum InAppDeleteSource: Int, JsonValueRepresentable {
    case inboxSwipe
    case deleteButton
    
    public var jsonValue: Any {
        switch self {
        case .inboxSwipe:
            return "inbox-swipe"
        case .deleteButton:
            return "delete-button"
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

enum MobileDeviceType: String, Codable {
    case iOS
    case Android
}

@objc public enum IterableActionSource: Int {
    case push
    case universalLink
    case inApp
}

// Lowest level that will be logged. By default the LogLevel is set to LogLevel.info.
@objc(IterableLogLevel) public enum LogLevel: Int {
    case debug = 1
    case info
    case error
}

/**
 Enum representing push platform; apple push notification service, production vs sandbox
 */
@objc public enum PushServicePlatform: Int {
    /** The sandbox push service */
    case sandbox
    /** The production push service */
    case production
    /** Detect automatically */
    case auto
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
public typealias UrlHandler = (URL) -> Bool
public typealias CustomActionHandler = (String) -> Bool
