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
        }
    }
}

extension IterableInAppContentType {
    static func from(string: String) -> IterableInAppContentType {
        switch string.lowercased() {
        case String(describing: IterableInAppContentType.html):
            return .html
        case String(describing: IterableInAppContentType.alert):
            return .alert
        case String(describing: IterableInAppContentType.banner):
            return .banner
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

extension IterableInAppMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case inAppType
        case messageId
        case campaignId
        case trigger
        case expiresAt
        case content
        case customPayload
        case processed
        case consumed
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
                      )
            return
        }
        
        let inAppType = (try? container.decode(IterableInAppType.self, forKey: .inAppType)) ?? .default
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(String.self, forKey: .campaignId)) ?? ""
        let trigger = (try? container.decode(IterableInAppTrigger.self, forKey: .trigger)) ?? .undefinedTrigger
        let expiresAt = (try? container.decode(Date.self, forKey: .expiresAt))
        let content = IterableInAppMessage.decodeContent(from: container)
        let customPayloadData = try? container.decode(Data.self, forKey: .customPayload)
        let customPayload = IterableInAppMessage.deserializeCustomPayload(withData: customPayloadData)
        
        self.init(messageId: messageId,
                  campaignId: campaignId,
                  inAppType: inAppType,
                  trigger: trigger,
                  expiresAt: expiresAt,
                  content: content,
                  customPayload: customPayload)
        
        self.processed = (try? container.decode(Bool.self, forKey: .processed)) ?? false
        self.consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false
    }

    private static func decodeContent(from container: KeyedDecodingContainer<IterableInAppMessage.CodingKeys>) -> IterableInAppContent {
        guard let contentContainer = try? container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content) else {
            ITBError()
            return createDefaultContent()
        }

        let contentType = (try? contentContainer.decode(String.self, forKey: .contentType)).map{ IterableInAppContentType.from(string: $0) } ?? .html

        enum ContentCodingKeys: String, CodingKey {
            case contentType
        }
        
        switch contentType {
        case .html:
            return (try? container.decode(IterableHtmlInAppContent.self, forKey: .content)) ?? createDefaultContent()
        default:
            return (try? container.decode(IterableHtmlInAppContent.self, forKey: .content)) ?? createDefaultContent()
        }
    }
    
    private static func createDefaultContent() -> IterableInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }

    
    public func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(inAppType, forKey: .inAppType)
        try? container.encode(messageId, forKey: .messageId)
        try? container.encode(campaignId, forKey: .campaignId)
        try? container.encode(trigger, forKey: .trigger)
        try? container.encode(expiresAt, forKey: .expiresAt)
        IterableInAppMessage.encode(content: content, inContainer: &container)
        try? container.encode(IterableInAppMessage.serialize(customPayload: customPayload), forKey: .customPayload)
        try? container.encode(processed, forKey: .processed)
        try? container.encode(consumed, forKey: .consumed)
        
    }
    
    fileprivate static func encode(content: IterableInAppContent, inContainer container: inout KeyedEncodingContainer<IterableInAppMessage.CodingKeys>) {
        switch content.contentType {
        case .html:
            if let content = content as? IterableHtmlInAppContent {
                try? container.encode(content, forKey: .content)
            }
        default:
            if let content = content as? IterableHtmlInAppContent {
                try? container.encode(content, forKey: .content)
            }
        }
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
}

protocol InAppPersistenceProtocol {
    func getMessages() -> [IterableInAppMessage]
    func persist(_ messages: [IterableInAppMessage])
    func clear()
}


class InAppFilePersister : InAppPersistenceProtocol {
    init(filename: String = "itbl_inapp", ext: String = "json") {
        self.filename = filename
        self.ext = ext
    }
    
    func getMessages() -> [IterableInAppMessage] {
        guard let data = FileHelper.read(filename: filename, ext: ext) else {
            return []
        }
        
        guard let messages = try? JSONDecoder().decode([IterableInAppMessage].self, from: data) else {
            return []
        }
        return messages
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
