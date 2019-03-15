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
extension IterableContentType : CustomStringConvertible {
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

extension IterableContentType {
    static func from(string: String) -> IterableContentType {
        switch string.lowercased() {
        case String(describing: IterableContentType.html).lowercased():
            return .html
        case String(describing: IterableContentType.alert).lowercased():
            return .alert
        case String(describing: IterableContentType.banner).lowercased():
            return .banner
        case String(describing: IterableContentType.inboxHtml).lowercased():
            return .inboxHtml
        default:
            return .html
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

extension IterableHtmlContent : Codable {
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

    public convenience init(from decoder: Decoder) {
        let htmlContent = IterableHtmlContent.htmlContent(from: decoder)
        self.init(edgeInsets: htmlContent.edgeInsets, backgroundAlpha: htmlContent.backgroundAlpha, html: htmlContent.html)
    }
    
    public func encode(to encoder: Encoder) {
        IterableHtmlContent.encode(htmlContent: self, to: encoder)
    }
}


extension IterableInboxMetadata : Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case subTitle
        case icon
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(title: nil, subTitle: nil, icon: nil)
            return
        }
        
        
        let title = (try? container.decode(String.self, forKey: .title))
        let subTitle = (try? container.decode(String.self, forKey: .subTitle))
        let icon = (try? container.decode(String.self, forKey: .icon))
        
        self.init(title: title, subTitle: subTitle, icon: icon)
    }
    
    public func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(title, forKey: .title)
        try? container.encode(subTitle, forKey: .subTitle)
        try? container.encode(icon, forKey: .icon)
    }
}

extension IterableInAppMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case saveToInbox
        case inboxMetadata
        case messageId
        case campaignId
        case expiresAt
        case customPayload
        case processed
        case consumed
        case trigger
        case content
    }
    
    enum ContentCodingKeys: String, CodingKey {
        case type
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
        
        let saveToInbox = (try? container.decode(Bool.self, forKey: .saveToInbox)) ?? false
        let inboxMetadata = (try? container.decode(IterableInboxMetadata.self, forKey: .inboxMetadata))
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(String.self, forKey: .campaignId)) ?? ""
        let expiresAt = (try? container.decode(Date.self, forKey: .expiresAt))
        let customPayloadData = try? container.decode(Data.self, forKey: .customPayload)
        let customPayload = IterableInAppMessage.deserializeCustomPayload(withData: customPayloadData)
        let processed = (try? container.decode(Bool.self, forKey: .processed)) ?? false
        let consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false

        let trigger = (try? container.decode(IterableInAppTrigger.self, forKey: .trigger)) ?? .undefinedTrigger
        let content = IterableInAppMessage.decodeContent(from: container)
        
        self.init(messageId: messageId,
                  campaignId: campaignId,
                  trigger: trigger,
                  expiresAt: expiresAt,
                  content: content,
                  saveToInbox: saveToInbox,
                  inboxMetadata: inboxMetadata,
                  customPayload: customPayload)
        
        self.processed = processed
        self.consumed = consumed
    }

    public func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try? container.encode(trigger, forKey: .trigger)
        try? container.encode(saveToInbox, forKey: .saveToInbox)
        try? container.encode(messageId, forKey: .messageId)
        try? container.encode(campaignId, forKey: .campaignId)
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(IterableInAppMessage.serialize(customPayload: customPayload), forKey: .customPayload)
        try? container.encode(processed, forKey: .processed)
        try? container.encode(consumed, forKey: .consumed)
        if let inboxMetadata = inboxMetadata {
            try? container.encode(inboxMetadata, forKey: .inboxMetadata)
        }

        IterableInAppMessage.encode(content: content, inContainer: &container)
    }
    
    private static func createDefaultContent() -> IterableContent {
        return IterableHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
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
    
    private static func decodeContent(from container: KeyedDecodingContainer<IterableInAppMessage.CodingKeys>) -> IterableContent {
        guard let contentContainer = try? container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content) else {
            ITBError()
            return createDefaultContent()
        }
        
        let contentType = (try? contentContainer.decode(String.self, forKey: .type)).map{ IterableContentType.from(string: $0) } ?? .html
        
        switch contentType {
        case .html:
            return (try? container.decode(IterableHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        default:
            return (try? container.decode(IterableHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        }
    }
    
    private static func encode(content: IterableContent, inContainer container: inout KeyedEncodingContainer<IterableInAppMessage.CodingKeys>) {
        switch content.type {
        case .html:
            if let content = content as? IterableHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        default:
            if let content = content as? IterableHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        }
    }
}

protocol IterableMessagePersistenceProtocol {
    func getMessages() -> [IterableInAppMessage]
    func persist(_ messages: [IterableInAppMessage])
    func clear()
}


class IterableMessageFilePersister : IterableMessagePersistenceProtocol {
    init(filename: String = "itbl_inapp", ext: String = "json") {
        self.filename = filename
        self.ext = ext
    }
    
    func getMessages() -> [IterableInAppMessage] {
        guard let data = FileHelper.read(filename: filename, ext: ext) else {
            return []
        }

        return (try? JSONDecoder().decode([IterableInAppMessage].self, from: data)) ?? []
    }
    
    func persist(_ messages: [IterableInAppMessage]) {
        
        guard let encoded = try? JSONEncoder().encode(messages) else {
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
