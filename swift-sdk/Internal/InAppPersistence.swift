//
//  Created by Tapash Majumder on 1/8/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

/// This is needed because String(describing: ...) returns the
/// wrong value for this enum when it is exposed to Objective-C
extension IterableInAppContentType: CustomStringConvertible {
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
        case String(describing: IterableInAppContentType.html).lowercased():
            return .html
        case String(describing: IterableInAppContentType.alert).lowercased():
            return .alert
        case String(describing: IterableInAppContentType.banner).lowercased():
            return .banner
        default:
            return .html
        }
    }
}

/// This is needed because String(describing: ...) returns the
/// wrong value for this enum when it is exposed to Objective-C
extension IterableInAppTriggerType: CustomStringConvertible {
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
    static let defaultTrigger = create(withTriggerType: .defaultTriggerType)
    static let undefinedTrigger = create(withTriggerType: .undefinedTriggerType)
    static let neverTrigger = create(withTriggerType: .never)
    
    static func create(withTriggerType triggerType: IterableInAppTriggerType) -> IterableInAppTrigger {
        return IterableInAppTrigger(dict: createTriggerDict(forTriggerType: triggerType))
    }
    
    static func createDefaultTriggerDict() -> [AnyHashable: Any] {
        return createTriggerDict(forTriggerType: .defaultTriggerType)
    }
    
    static func createTriggerDict(forTriggerType triggerType: IterableInAppTriggerType) -> [AnyHashable: Any] {
        return [JsonKey.InApp.type: String(describing: triggerType)]
    }
}

extension IterableInAppTrigger: Codable {
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
            
            return
        }
        
        guard let data = try? container.decode(Data.self, forKey: .data) else {
            self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
            
            return
        }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] {
                self.init(dict: dict)
            } else {
                self.init(dict: IterableInAppTrigger.createDefaultTriggerDict())
            }
        } catch {
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

extension IterableHtmlInAppContent: Codable {
    enum CodingKeys: String, CodingKey {
        case edgeInsets
        case backgroundAlpha
        case html
    }
    
    static func htmlContent(from decoder: Decoder) -> IterableHtmlInAppContent {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            
            return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
        }
        
        let edgeInsets = (try? container.decode(UIEdgeInsets.self, forKey: .edgeInsets)) ?? .zero
        let backgroundAlpha = (try? container.decode(Double.self, forKey: .backgroundAlpha)) ?? 0.0
        let html = (try? container.decode(String.self, forKey: .html)) ?? ""
        
        return IterableHtmlInAppContent(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, html: html)
    }
    
    static func encode(htmlContent: IterableHtmlInAppContent, to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(htmlContent.edgeInsets, forKey: .edgeInsets)
        try? container.encode(htmlContent.backgroundAlpha, forKey: .backgroundAlpha)
        try? container.encode(htmlContent.html, forKey: .html)
    }
    
    public convenience init(from decoder: Decoder) {
        let htmlContent = IterableHtmlInAppContent.htmlContent(from: decoder)
        
        self.init(edgeInsets: htmlContent.edgeInsets, backgroundAlpha: htmlContent.backgroundAlpha, html: htmlContent.html)
    }
    
    public func encode(to encoder: Encoder) {
        IterableHtmlInAppContent.encode(htmlContent: self, to: encoder)
    }
}

extension IterableInboxMetadata: Codable {
    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case icon
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(title: nil, subtitle: nil, icon: nil)
            
            return
        }
        
        let title = (try? container.decode(String.self, forKey: .title))
        let subtitle = (try? container.decode(String.self, forKey: .subtitle))
        let icon = (try? container.decode(String.self, forKey: .icon))
        
        self.init(title: title, subtitle: subtitle, icon: icon)
    }
    
    public func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(title, forKey: .title)
        try? container.encode(subtitle, forKey: .subtitle)
        try? container.encode(icon, forKey: .icon)
    }
}

extension IterableInAppMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case saveToInbox
        case inboxMetadata
        case messageId
        case campaignId
        case createdAt
        case expiresAt
        case customPayload
        case didProcessTrigger
        case consumed
        case read
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
                      campaignId: 0,
                      content: IterableInAppMessage.createDefaultContent())
            
            return
        }
        
        let saveToInbox = (try? container.decode(Bool.self, forKey: .saveToInbox)) ?? false
        let inboxMetadata = (try? container.decode(IterableInboxMetadata.self, forKey: .inboxMetadata))
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(Int.self, forKey: .campaignId)).map { NSNumber(value: $0) }
        let createdAt = (try? container.decode(Date.self, forKey: .createdAt))
        let expiresAt = (try? container.decode(Date.self, forKey: .expiresAt))
        let customPayloadData = try? container.decode(Data.self, forKey: .customPayload)
        let customPayload = IterableInAppMessage.deserializeCustomPayload(withData: customPayloadData)
        let didProcessTrigger = (try? container.decode(Bool.self, forKey: .didProcessTrigger)) ?? false
        let consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false
        let read = (try? container.decode(Bool.self, forKey: .read)) ?? false
        
        let trigger = (try? container.decode(IterableInAppTrigger.self, forKey: .trigger)) ?? .undefinedTrigger
        let content = IterableInAppMessage.decodeContent(from: container)
        
        self.init(messageId: messageId,
                  campaignId: campaignId,
                  trigger: trigger,
                  createdAt: createdAt,
                  expiresAt: expiresAt,
                  content: content,
                  saveToInbox: saveToInbox,
                  inboxMetadata: inboxMetadata,
                  customPayload: customPayload,
                  read: read)
        
        self.didProcessTrigger = didProcessTrigger
        self.consumed = consumed
    }
    
    public func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(trigger, forKey: .trigger)
        try? container.encode(saveToInbox, forKey: .saveToInbox)
        try? container.encode(messageId, forKey: .messageId)
        try? container.encode(campaignId as? Int, forKey: .campaignId)
        try? container.encode(createdAt, forKey: .createdAt)
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(IterableInAppMessage.serialize(customPayload: customPayload), forKey: .customPayload)
        try? container.encode(didProcessTrigger, forKey: .didProcessTrigger)
        try? container.encode(consumed, forKey: .consumed)
        try? container.encode(read, forKey: .read)
        
        if let inboxMetadata = inboxMetadata {
            try? container.encode(inboxMetadata, forKey: .inboxMetadata)
        }
        
        IterableInAppMessage.encode(content: content, inContainer: &container)
    }
    
    private static func createDefaultContent() -> IterableInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
    
    private static func serialize(customPayload: [AnyHashable: Any]?) -> Data? {
        guard let customPayload = customPayload else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: customPayload, options: [])
    }
    
    private static func deserializeCustomPayload(withData data: Data?) -> [AnyHashable: Any]? {
        guard let data = data else {
            return nil
        }
        
        let deserialized = try? JSONSerialization.jsonObject(with: data, options: [])
        
        return deserialized as? [AnyHashable: Any]
    }
    
    private static func decodeContent(from container: KeyedDecodingContainer<IterableInAppMessage.CodingKeys>) -> IterableInAppContent {
        guard let contentContainer = try? container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content) else {
            ITBError()
            
            return createDefaultContent()
        }
        
        let contentType = (try? contentContainer.decode(String.self, forKey: .type)).map { IterableInAppContentType.from(string: $0) } ?? .html
        
        switch contentType {
        case .html:
            return (try? container.decode(IterableHtmlInAppContent.self, forKey: .content)) ?? createDefaultContent()
        default:
            return (try? container.decode(IterableHtmlInAppContent.self, forKey: .content)) ?? createDefaultContent()
        }
    }
    
    private static func encode(content: IterableInAppContent, inContainer container: inout KeyedEncodingContainer<IterableInAppMessage.CodingKeys>) {
        switch content.type {
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
}

protocol InAppPersistenceProtocol {
    func getMessages() -> [IterableInAppMessage]
    func persist(_ messages: [IterableInAppMessage])
    func clear()
}

class InAppFilePersister: InAppPersistenceProtocol {
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
