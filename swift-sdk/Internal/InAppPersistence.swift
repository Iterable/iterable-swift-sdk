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

extension IterableInAppMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case messageId
        case campaignId
        case channelName
        case contentType
        case trigger
        case expiresAt
        case content
        case extraInfo
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
        
        guard let contentType = (try? container.decode(IterableInAppContentType.self, forKey: .contentType)), contentType == .html else {
            // unexpected content type
            ITBError("Unexpected contentType, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
            )
            return
        }
        
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(String.self, forKey: .campaignId)) ?? ""
        let channelName = (try? container.decode(String.self, forKey: .channelName)) ?? ""
        let trigger = (try? container.decode(IterableInAppTriggerType.self, forKey: .trigger)) ?? .undefinedTriggerType
        let expiresAt = (try? container.decode(Date.self, forKey: .expiresAt))
        let content = (try? container.decode(IterableHtmlInAppContent.self, forKey: .content)) ?? IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
        let extraInfoData = try? container.decode(Data.self, forKey: .extraInfo)
        let extraInfo = IterableInAppMessage.deserializeExtraInfo(withData: extraInfoData)
        
        self.init(messageId: messageId,
                  campaignId: campaignId,
                  channelName: channelName,
                  contentType: contentType,
                  trigger: trigger,
                  expiresAt: expiresAt,
                  content: content,
                  extraInfo: extraInfo)
        
        self.processed = (try? container.decode(Bool.self, forKey: .processed)) ?? false
        self.consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false
    }
    
    public func encode(to encoder: Encoder) {
        guard let content = content as? IterableHtmlInAppContent else {
            return
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(messageId, forKey: .messageId)
        try? container.encode(campaignId, forKey: .campaignId)
        try? container.encode(channelName, forKey: .channelName)
        try? container.encode(contentType, forKey: .contentType)
        try? container.encode(trigger, forKey: .trigger)
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(content, forKey: .content)
        try? container.encode(IterableInAppMessage.serialize(extraInfo: extraInfo), forKey: .extraInfo)
        try? container.encode(processed, forKey: .processed)
        try? container.encode(consumed, forKey: .consumed)
        
    }
    
    private static func serialize(extraInfo: [AnyHashable : Any]?) -> Data? {
        guard let extraInfo = extraInfo else {
            return nil
        }

        return try? JSONSerialization.data(withJSONObject: extraInfo, options: [])
    }
    
    private static func deserializeExtraInfo(withData data: Data?) -> [AnyHashable : Any]? {
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
