//
//
//  Created by Tapash Majumder on 1/8/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

// Adhering to Codable
extension UIEdgeInsets : Codable {
    enum CodingKeys: String, CodingKey {
        case top
        case left
        case bottom
        case right
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let top = try container.decode(Double.self, forKey: .top)
        let left = try container.decode(Double.self, forKey: .left)
        let bottom = try container.decode(Double.self, forKey: .bottom)
        let right = try container.decode(Double.self, forKey: .right)
        
        self.init(top: CGFloat(top), left: CGFloat(left), bottom: CGFloat(bottom), right: CGFloat(right))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Double(top), forKey: .top)
        try container.encode(Double(left), forKey: .left)
        try container.encode(Double(bottom), forKey: .bottom)
        try container.encode(Double(right), forKey: .right)
    }
}

// This is needed because String(describing: ...) returns wrong
// value for this enum when it is exposed to Objective C
extension IterableInAppContentType : CustomStringConvertible {
    public var description: String {
        switch self {
        case .html:
            return "html"
        case .alert:
            return "alert"
        case .banner:
            return "banner"
        case .inboxHtml:
            return "inboxHtml"
        }
    }
}

extension IterableInAppContentType {
    static func from(string: String) -> IterableInAppContentType {
        switch string.lowercased() {
        case String(describing: IterableInAppContentType.html).lowercased():
            return .html
        case String(describing: IterableInAppContentType.alert).lowercased():
            return .alert
        case String(describing: IterableInAppContentType.banner).lowercased():
            return .banner
        case String(describing: IterableInAppContentType.inboxHtml).lowercased():
            return .inboxHtml
        default:
            return .html
        }
    }
}

// This is needed because String(describing: ...) returns wrong
// value for this enum when it is exposed to Objective C
extension IterableInAppType : CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return "default"
        case .inbox:
            return "inbox"
        }
    }
}

extension IterableInAppType {
    static func from(string: String) -> IterableInAppType {
        switch string.lowercased() {
        case String(describing: IterableInAppType.default).lowercased():
            return .default
        case String(describing: IterableInAppType.inbox).lowercased():
            return .inbox
        default:
            return .default
        }
    }
}

// This is needed because String(describing: ...) returns wrong
// value for this enum when it is exposed to Objective C
extension IterableInAppTriggerType : CustomStringConvertible {
    public var description: String {
        switch self {
        case .event:
            return "event"
        case .immediate:
            return "immediate"
        case .never:
            return "never"
        }
    }
}

extension IterableInAppTriggerType {
    // Internal
    static func from(string: String) -> IterableInAppTriggerType {
        switch string.lowercased() {
        case String(describing: IterableInAppTriggerType.immediate).lowercased():
            return .immediate
        case String(describing: IterableInAppTriggerType.event).lowercased():
            return .event
        case String(describing: IterableInAppTriggerType.never).lowercased():
            return .never
        default:
            return .undefinedTriggerType // if string is not known
        }
    }
}

extension IterableInAppTrigger {
    static let defaultTrigger = IterableInAppTrigger(dict: createDefaultTriggerDict())
    static let undefinedTrigger = IterableInAppTrigger(dict: createUndefinedTriggerDict())

    private static func createDefaultTriggerDict() -> [AnyHashable : Any] {
        return [.ITBL_IN_APP_TRIGGER_TYPE : String(describing: IterableInAppTriggerType.defaultTriggerType)]
    }
    
    private static func createUndefinedTriggerDict() -> [AnyHashable : Any] {
        return [.ITBL_IN_APP_TRIGGER_TYPE : String(describing: IterableInAppTriggerType.undefinedTriggerType)]
    }
}

extension IterableInAppTrigger : Codable {
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
            return
        }

        guard let data = (try? container.decode(Data.self, forKey: .data)) else {
            self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
            return
        }

        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable : Any] {
                self.init(dict: dict)
            } else {
                self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
            }
            
        } catch (let error) {
            ITBError(error.localizedDescription)
            self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            try? container.encode(data, forKey: .data)
        }
    }
}

struct IterableHtmlContentPersistenceHelper {
    enum CodingKeys: String, CodingKey {
        case edgeInsets
        case backgroundAlpha
        case html
    }
    
    static func htmlContent(from decoder: Decoder) -> IterableHtmlContent {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            return IterableHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
        }
        
        let edgeInsets = (try? container.decode(UIEdgeInsets.self, forKey: .edgeInsets)) ?? .zero
        let backgroundAlpha = (try? container.decode(Double.self, forKey: .backgroundAlpha)) ?? 0.0
        let html = (try? container.decode(String.self, forKey: .html)) ?? ""
        
        return IterableHtmlContent(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, html: html)
    }
    
    static func encode(htmlContent: IterableHtmlContent, to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(htmlContent.edgeInsets, forKey: .edgeInsets)
        try? container.encode(htmlContent.backgroundAlpha, forKey: .backgroundAlpha)
        try? container.encode(htmlContent.html, forKey: .html)
    }
}

extension IterableInAppHtmlContent : Codable {
    public convenience init(from decoder: Decoder) {
        let htmlContent = IterableHtmlContentPersistenceHelper.htmlContent(from: decoder)
        self.init(edgeInsets: htmlContent.edgeInsets, backgroundAlpha: htmlContent.backgroundAlpha, html: htmlContent.html)
    }
    
    public func encode(to encoder: Encoder) {
        IterableHtmlContentPersistenceHelper.encode(htmlContent: self, to: encoder)
    }
}

extension IterableInboxHtmlContent : Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case subTitle
        case icon
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(edgeInsets: .zero, backgroundAlpha: 0.0, html: "", title: nil, subTitle: nil, icon: nil)
            return
        }
        
        
        let htmlContent = IterableHtmlContentPersistenceHelper.htmlContent(from: decoder)
        
        let title = (try? container.decode(String.self, forKey: .title))
        let subTitle = (try? container.decode(String.self, forKey: .subTitle))
        let icon = (try? container.decode(String.self, forKey: .icon))
        
        self.init(edgeInsets: htmlContent.edgeInsets, backgroundAlpha: htmlContent.backgroundAlpha, html: htmlContent.html, title: title, subTitle: subTitle, icon: icon)
    }
    
    public func encode(to encoder: Encoder) {
        IterableHtmlContentPersistenceHelper.encode(htmlContent: self, to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(title, forKey: .title)
        try? container.encode(subTitle, forKey: .subTitle)
        try? container.encode(icon, forKey: .icon)
    }
}

struct IterablePersistableMessage : Codable {
    enum CodingKeys : String, CodingKey {
        case inAppType
    }
    
    let iterableMessage: IterableMessageProtocol
    
    init(iterableMessage: IterableMessageProtocol) {
        self.iterableMessage = iterableMessage
    }
    
    func encode(to encoder: Encoder) {
        switch (iterableMessage.inAppType) {
        case .default:
            (iterableMessage as? IterableInAppMessage)?.encode(to: encoder)
        case .inbox:
            (iterableMessage as? IterableInboxMessage)?.encode(to: encoder)
        }
    }
    
    init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.iterableMessage = IterablePersistableMessage.createDefaultMessage()
            return
        }
        guard let mainContainer = try? decoder.singleValueContainer() else {
            ITBError("Can not decode, returning default")
            self.iterableMessage = IterablePersistableMessage.createDefaultMessage()
            return
        }
        
        let inAppType = (try? container.decode(IterableInAppType.self, forKey: .inAppType)) ?? .default
        switch (inAppType) {
        case .default:
            self.iterableMessage = (try? mainContainer.decode(IterableInAppMessage.self)) ?? IterablePersistableMessage.createDefaultMessage()
        case .inbox:
            self.iterableMessage = (try? mainContainer.decode(IterableInboxMessage.self)) ?? IterablePersistableMessage.createDefaultMessage()
        }
    }
    
    private static func createDefaultMessage() -> IterableMessageProtocol {
        return IterableInAppMessage(messageId: "", campaignId: "", content: IterableInAppHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""))
    }
}

struct IterableMessagePersistenceHelper {
    struct IterableMessageInfo {
        let inAppType: IterableInAppType
        
        let messageId: String
        
        let campaignId: String
        
        let expiresAt: Date?
        
        let customPayload: [AnyHashable : Any]?
        
        var processed: Bool = false
        
        var consumed: Bool = false
        
        init(inAppType: IterableInAppType, messageId: String, campaignId: String, expiresAt: Date?, customPayload: [AnyHashable : Any]?, processed: Bool, consumed: Bool) {
            self.inAppType = inAppType
            self.messageId = messageId
            self.campaignId = campaignId
            self.expiresAt = expiresAt
            self.customPayload = customPayload
            self.processed = processed
            self.consumed = consumed
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case inAppType
        case messageId
        case campaignId
        case expiresAt
        case customPayload
        case processed
        case consumed
    }
    
    static func message(from decoder: Decoder) -> IterableMessageInfo {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            return defaultMessage
        }

        let inAppType = (try? container.decode(IterableInAppType.self, forKey: .inAppType)) ?? .default
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(String.self, forKey: .campaignId)) ?? ""
        let expiresAt = (try? container.decode(Date.self, forKey: .expiresAt))
        let customPayloadData = try? container.decode(Data.self, forKey: .customPayload)
        let customPayload = deserializeCustomPayload(withData: customPayloadData)
        let processed = (try? container.decode(Bool.self, forKey: .processed)) ?? false
        let consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false

        return IterableMessageInfo(inAppType: inAppType,
                            messageId: messageId,
                            campaignId: campaignId,
                            expiresAt: expiresAt,
                            customPayload: customPayload,
                            processed: processed,
                            consumed: consumed)
    }
    
    static func encode(message: IterableMessageInfo, to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(message.inAppType, forKey: .inAppType)
        try? container.encode(message.messageId, forKey: .messageId)
        try? container.encode(message.campaignId, forKey: .campaignId)
        try? container.encode(message.expiresAt, forKey: .expiresAt)
        try? container.encode(serialize(customPayload: message.customPayload), forKey: .customPayload)
        try? container.encode(message.processed, forKey: .processed)
        try? container.encode(message.consumed, forKey: .consumed)
    }
    
    private static func serialize(customPayload: [AnyHashable : Any]?) -> Data? {
        guard let customPayload = customPayload else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: customPayload, options: [])
    }

    private static func deserializeCustomPayload(withData data: Data?) -> [AnyHashable : Any]? {
        guard let data = data else {
            return nil
        }
        
        let deserialized = try? JSONSerialization.jsonObject(with: data, options: [])
        return (deserialized as? [AnyHashable : Any])
    }

    private static let defaultMessage = IterableMessageInfo(inAppType: .default, messageId: "", campaignId: "", expiresAt: nil, customPayload: nil, processed: false, consumed: false)
}

extension IterableInAppMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case trigger
        case content
    }
    
    enum ContentCodingKeys: String, CodingKey {
        case contentType
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableInAppMessage.createDefaultContent()
                      )
            return
        }
        
        let message = IterableMessagePersistenceHelper.message(from: decoder)
        
        let trigger = (try? container.decode(IterableInAppTrigger.self, forKey: .trigger)) ?? .undefinedTrigger
        let content = IterableInAppMessage.decodeContent(from: container)
        
        self.init(messageId: message.messageId,
                  campaignId: message.campaignId,
                  trigger: trigger,
                  expiresAt: message.expiresAt,
                  content: content,
                  customPayload: message.customPayload)
        
        self.processed = message.processed
        self.consumed = message.consumed
    }

    private static func createDefaultContent() -> IterableContent {
        return IterableInAppHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }

    
    public func encode(to encoder: Encoder) {
        let message = IterableMessagePersistenceHelper.IterableMessageInfo(inAppType: inAppType,
                                                                               messageId: messageId,
                                                                               campaignId: campaignId,
                                                                               expiresAt: expiresAt,
                                                                               customPayload: customPayload,
                                                                               processed: processed,
                                                                               consumed: consumed)
        IterableMessagePersistenceHelper.encode(message: message, to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(trigger, forKey: .trigger)
        IterableInAppMessage.encode(content: content, inContainer: &container)
    }
    
    private static func decodeContent(from container: KeyedDecodingContainer<IterableInAppMessage.CodingKeys>) -> IterableContent {
        guard let contentContainer = try? container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content) else {
            ITBError()
            return createDefaultContent()
        }
        
        let contentType = (try? contentContainer.decode(String.self, forKey: .contentType)).map{ IterableInAppContentType.from(string: $0) } ?? .html
        
        switch contentType {
        case .html:
            return (try? container.decode(IterableInAppHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        default:
            return (try? container.decode(IterableInAppHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        }
    }
    
    private static func encode(content: IterableContent, inContainer container: inout KeyedEncodingContainer<IterableInAppMessage.CodingKeys>) {
        switch content.contentType {
        case .html:
            if let content = content as? IterableInAppHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        default:
            if let content = content as? IterableInAppHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        }
    }
}

extension IterableInboxMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case content
    }

    enum ContentCodingKeys: String, CodingKey {
        case contentType
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableInboxMessage.createDefaultContent()
            )
            return
        }
        
        let message = IterableMessagePersistenceHelper.message(from: decoder)
        
        let content = IterableInboxMessage.decodeContent(from: container)
        
        self.init(messageId: message.messageId,
                  campaignId: message.campaignId,
                  expiresAt: message.expiresAt,
                  content: content,
                  customPayload: message.customPayload)
        
        self.processed = message.processed
        self.consumed = message.consumed
    }
    
    public func encode(to encoder: Encoder) {
        let message = IterableMessagePersistenceHelper.IterableMessageInfo(inAppType: inAppType,
                                                                           messageId: messageId,
                                                                           campaignId: campaignId,
                                                                           expiresAt: expiresAt,
                                                                           customPayload: customPayload,
                                                                           processed: processed,
                                                                           consumed: consumed)
        IterableMessagePersistenceHelper.encode(message: message, to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        IterableInboxMessage.encode(content: content, inContainer: &container)
    }

    private static func decodeContent(from container: KeyedDecodingContainer<IterableInboxMessage.CodingKeys>) -> IterableContent {
        guard let contentContainer = try? container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content) else {
            ITBError()
            return createDefaultContent()
        }
        
        let contentType = (try? contentContainer.decode(String.self, forKey: .contentType)).map{ IterableInAppContentType.from(string: $0) } ?? .inboxHtml
        
        switch contentType {
        case .inboxHtml:
            return (try? container.decode(IterableInboxHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        default:
            return (try? container.decode(IterableInboxHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        }
    }

    private static func encode(content: IterableContent, inContainer container: inout KeyedEncodingContainer<IterableInboxMessage.CodingKeys>) {
        switch content.contentType {
        case .inboxHtml:
            if let content = content as? IterableInboxHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        default:
            if let content = content as? IterableInboxHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        }
    }
    
    private static func createDefaultContent() -> IterableContent {
        return IterableInboxHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "", title: nil, subTitle: nil, icon: nil)
    }
}

protocol InAppPersistenceProtocol {
    func getMessages() -> [IterableMessageProtocol]
    func persist(_ messages: [IterableMessageProtocol])
    func clear()
}


class InAppFilePersister : InAppPersistenceProtocol {
    init(filename: String = "itbl_inapp", ext: String = "json") {
        self.filename = filename
        self.ext = ext
    }
    
    func getMessages() -> [IterableMessageProtocol] {
        guard let data = FileHelper.read(filename: filename, ext: ext) else {
            return []
        }

        guard let messages = try? JSONDecoder().decode([IterablePersistableMessage].self, from: data) else {
            return []
        }
        return messages.map { $0.iterableMessage }
    }
    
    func persist(_ messages: [IterableMessageProtocol]) {
        
        let persistableMessages = messages.map { IterablePersistableMessage(iterableMessage: $0) }
        
        guard let encoded = try? JSONEncoder().encode(persistableMessages) else {
            return
        }
        
        FileHelper.write(filename: filename, ext: ext, data: encoded)
    }
    
    func clear() {
        FileHelper.delete(filename: filename, ext: ext)
    }
    
    private let filename: String
    private let ext: String
}

// Files Utility class
struct FileHelper {
    static func getUrl(filename: String, ext: String) -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return dir.appendingPathComponent(filename).appendingPathExtension(ext)
    }
    
    static func write(filename: String, ext: String, data: Data) {
        guard let url = getUrl(filename: filename, ext: ext) else {
            return
        }
        
        try? data.write(to: url)
    }
    
    static func read(filename: String, ext: String) -> Data? {
        guard let url = getUrl(filename: filename, ext: ext) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    static func delete(filename: String, ext: String) {
        guard let url = getUrl(filename: filename, ext: ext) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }

}
