//
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
        IterableInAppTrigger(dict: createTriggerDict(forTriggerType: triggerType))
    }
    
    static func createDefaultTriggerDict() -> [AnyHashable: Any] {
        createTriggerDict(forTriggerType: .defaultTriggerType)
    }
    
    static func createTriggerDict(forTriggerType triggerType: IterableInAppTriggerType) -> [AnyHashable: Any] {
        [JsonKey.InApp.type: String(describing: triggerType)]
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
    struct CodableColor: Codable {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
        
        static func uiColorFromCodableColor(_ codableColor: CodableColor) -> UIColor {
            UIColor(red: codableColor.r, green: codableColor.g, blue: codableColor.b, alpha: codableColor.a)
        }
        
        static func codableColorFromUIColor(_ uiColor: UIColor) -> CodableColor {
            let (r, g, b, a) = uiColor.rgba
            return CodableColor(r: r, g: g, b: b, a: a)
        }
    }

    enum CodingKeys: String, CodingKey {
        case edgeInsets
        case html
        case shouldAnimate
        case bgColor // saves codable color, not UIColor
    }
    
    static func htmlContent(from decoder: Decoder) -> IterableHtmlInAppContent {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            
            return IterableHtmlInAppContent(edgeInsets: .zero, html: "")
        }
        
        let edgeInsets = (try? container.decode(UIEdgeInsets.self, forKey: .edgeInsets)) ?? .zero
        let html = (try? container.decode(String.self, forKey: .html)) ?? ""
        let shouldAnimate = (try? container.decode(Bool.self, forKey: .shouldAnimate)) ?? false
        let backgroundColor = (try? container.decode(CodableColor.self, forKey: .bgColor)).map(CodableColor.uiColorFromCodableColor(_:))

        return IterableHtmlInAppContent(edgeInsets: edgeInsets,
                                        html: html,
                                        shouldAnimate: shouldAnimate,
                                        backgroundColor: backgroundColor)
    }
    
    static func encode(htmlContent: IterableHtmlInAppContent, to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(htmlContent.edgeInsets, forKey: .edgeInsets)
        try? container.encode(htmlContent.html, forKey: .html)
        try? container.encode(htmlContent.shouldAnimate, forKey: .shouldAnimate)
        if let backgroundColor = htmlContent.backgroundColor {
            try? container.encode(CodableColor.codableColorFromUIColor(backgroundColor), forKey: .bgColor)
        }
    }
    
    public convenience init(from decoder: Decoder) {
        let htmlContent = IterableHtmlInAppContent.htmlContent(from: decoder)
        
        self.init(edgeInsets: htmlContent.edgeInsets,
                  html: htmlContent.html,
                  shouldAnimate: htmlContent.shouldAnimate,
                  backgroundColor: htmlContent.backgroundColor)
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
        case priorityLevel
        case jsonOnly
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
        
        let jsonOnly = (try? container.decode(Int.self, forKey: .jsonOnly)) ?? 0
        let customPayloadData = try? container.decode(Data.self, forKey: .customPayload)
        var customPayload = IterableInAppMessage.deserializeCustomPayload(withData: customPayloadData)
        
        if jsonOnly == 1 && customPayload == nil {
            customPayload = [:]
        }
        
        let saveToInbox = (try? container.decode(Bool.self, forKey: .saveToInbox)) ?? false
        let inboxMetadata = (try? container.decode(IterableInboxMetadata.self, forKey: .inboxMetadata))
        let messageId = (try? container.decode(String.self, forKey: .messageId)) ?? ""
        let campaignId = (try? container.decode(Int.self, forKey: .campaignId)).map { NSNumber(value: $0) }
        let createdAt = (try? container.decode(Date.self, forKey: .createdAt))
        let expiresAt = (try? container.decode(Date.self, forKey: .expiresAt))
        let didProcessTrigger = (try? container.decode(Bool.self, forKey: .didProcessTrigger)) ?? false
        let consumed = (try? container.decode(Bool.self, forKey: .consumed)) ?? false
        let read = (try? container.decode(Bool.self, forKey: .read)) ?? false
        
        let trigger = (try? container.decode(IterableInAppTrigger.self, forKey: .trigger)) ?? .undefinedTrigger
        let content = IterableInAppMessage.decodeContent(from: container, isJsonOnly: jsonOnly == 1)
        let priorityLevel = (try? container.decode(Double.self, forKey: .priorityLevel)) ?? Const.PriorityLevel.unassigned
        
        self.init(messageId: messageId,
                  campaignId: campaignId,
                  trigger: trigger,
                  createdAt: createdAt,
                  expiresAt: expiresAt,
                  content: content,
                  saveToInbox: saveToInbox && jsonOnly != 1,
                  inboxMetadata: inboxMetadata,
                  customPayload: customPayload,
                  read: read,
                  priorityLevel: priorityLevel,
                  jsonOnly: jsonOnly == 1)
        
        self.didProcessTrigger = didProcessTrigger
        self.consumed = consumed
    }
    
    var isJsonOnly: Bool {
        return jsonOnly
    }
    
    public func encode(to encoder: Encoder) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode jsonOnly first
        try? container.encode(isJsonOnly ? 1 : 0, forKey: .jsonOnly)
        
        try? container.encode(trigger, forKey: .trigger)
        try? container.encode(saveToInbox && !isJsonOnly, forKey: .saveToInbox)
        try? container.encode(messageId, forKey: .messageId)
        try? container.encode(campaignId as? Int, forKey: .campaignId)
        try? container.encode(createdAt, forKey: .createdAt)
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(IterableInAppMessage.serialize(customPayload: customPayload), forKey: .customPayload)
        try? container.encode(didProcessTrigger, forKey: .didProcessTrigger)
        try? container.encode(consumed, forKey: .consumed)
        try? container.encode(read, forKey: .read)
        try? container.encode(priorityLevel, forKey: .priorityLevel)
        
        if let inboxMetadata = inboxMetadata {
            try? container.encode(inboxMetadata, forKey: .inboxMetadata)
        }
        
        // Only encode content if not JSON-only
        if !isJsonOnly {
            IterableInAppMessage.encode(content: content, inContainer: &container)
        }
    }
    
    private static func createDefaultContent() -> IterableInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, html: "")
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
    
    private static func decodeContent(from container: KeyedDecodingContainer<IterableInAppMessage.CodingKeys>, isJsonOnly: Bool) -> IterableInAppContent {
        if isJsonOnly {
            return createDefaultContent()
        }

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

final class JsonOnlyMessageStore {
    struct Delivery {
        let message: IterableInAppMessage
        let isInitial: Bool
    }

    init(localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol,
         identityProvider: @escaping () -> UserIdentitySnapshot?) {
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.identityProvider = identityProvider
    }

    var identityScope: UserIdentitySnapshot? {
        stateQueue.sync {
            identityProvider()
        }
    }

    @discardableResult
    func enqueue(_ message: IterableInAppMessage) -> Bool {
        guard let identityScope = identityScope else { return false }
        return enqueue(message, identityScope: identityScope)
    }

    @discardableResult
    func enqueue(_ message: IterableInAppMessage, identityScope: UserIdentitySnapshot) -> Bool {
        stateQueue.sync {
            guard var state = loadCurrentState(expectedIdentity: identityScope) else { return false }
            let currentDate = dateProvider.currentDate
            guard !Self.isExpired(message, at: currentDate) else { return false }

            if state.entries.contains(where: { $0.message.messageId == message.messageId }) {
                return true
            }

            state.entries.append(Entry(message: message,
                                       storedAt: currentDate,
                                       didBeginInitialDelivery: false))
            state.entries = Array(state.entries.suffix(Self.maximumRecordCount))
            return persist(state)
        }
    }

    func prepareDelivery(for message: IterableInAppMessage) -> Delivery? {
        guard let identityScope = identityScope else { return nil }
        return prepareDelivery(for: message, identityScope: identityScope)
    }

    func prepareDelivery(for message: IterableInAppMessage, identityScope: UserIdentitySnapshot) -> Delivery? {
        stateQueue.sync {
            guard var state = loadCurrentState(expectedIdentity: identityScope),
                  let index = state.entries.firstIndex(where: { $0.message.messageId == message.messageId }) else {
                return nil
            }
            let currentDate = dateProvider.currentDate
            guard !Self.isExpired(state.entries[index].message, at: currentDate) else { return nil }
            let isInitial = !state.entries[index].didBeginInitialDelivery
            if isInitial {
                state.entries[index].didBeginInitialDelivery = true
                guard persist(state) else { return nil }
            }
            return Delivery(message: state.entries[index].message, isInitial: isInitial)
        }
    }

    func getMessages() -> [IterableInAppMessage] {
        stateQueue.sync {
            loadCurrentState()?.entries.map(\.message) ?? []
        }
    }

    func getMessages(identityScope: UserIdentitySnapshot) -> [IterableInAppMessage] {
        stateQueue.sync {
            loadCurrentState(expectedIdentity: identityScope)?.entries.map(\.message) ?? []
        }
    }

    @discardableResult
    func remove(messageId: String) -> Bool {
        stateQueue.sync {
            guard var state = loadCurrentState(),
                  let index = state.entries.firstIndex(where: { $0.message.messageId == messageId }) else {
                return false
            }

            state.entries.remove(at: index)
            return persist(state)
        }
    }

    func clear() {
        stateQueue.sync {
            localStorage.jsonOnlyMessageQueueData = nil
        }
    }

    private struct StoredIdentity: Codable, Equatable {
        enum Kind: String, Codable {
            case email
            case userId
        }

        let kind: Kind
        let value: String

        init(_ snapshot: UserIdentitySnapshot) {
            switch snapshot {
            case let .email(email):
                kind = .email
                value = email
            case let .userId(userId):
                kind = .userId
                value = userId
            }
        }
    }

    private struct Entry: Codable {
        let message: IterableInAppMessage
        let storedAt: Date
        var didBeginInitialDelivery: Bool
    }

    private struct State: Codable {
        let identity: StoredIdentity
        var entries: [Entry]
    }

    private static func isExpired(_ message: IterableInAppMessage, at currentDate: Date) -> Bool {
        guard let expiresAt = message.expiresAt else { return false }
        return expiresAt <= currentDate
    }

    private func loadCurrentState(expectedIdentity: UserIdentitySnapshot? = nil) -> State? {
        guard let snapshot = identityProvider() else { return nil }
        if let expectedIdentity = expectedIdentity, snapshot != expectedIdentity { return nil }

        let identity = StoredIdentity(snapshot)
        var state: State
        var stateChanged = false
        if let data = localStorage.jsonOnlyMessageQueueData {
            do {
                state = try JSONDecoder().decode(State.self, from: data)
            } catch {
                ITBError("Unable to decode unhandled JSON-only messages: \(error.localizedDescription)")
                state = State(identity: identity, entries: [])
                stateChanged = true
            }
        } else {
            state = State(identity: identity, entries: [])
        }

        if state.identity != identity {
            state = State(identity: identity, entries: [])
            stateChanged = true
        }

        let currentDate = dateProvider.currentDate
        let retainedEntries = state.entries.filter { entry in
            if entry.message.expiresAt != nil {
                return !Self.isExpired(entry.message, at: currentDate)
            }
            return entry.storedAt.addingTimeInterval(Self.fallbackRetentionPeriod) > currentDate
        }

        if retainedEntries.count != state.entries.count {
            state.entries = retainedEntries
            stateChanged = true
        }

        if stateChanged, !persist(state) { return nil }
        return state
    }

    private func persist(_ state: State) -> Bool {
        do {
            localStorage.jsonOnlyMessageQueueData = try JSONEncoder().encode(state)
            return true
        } catch {
            ITBError("Unable to persist unhandled JSON-only messages: \(error.localizedDescription)")
            return false
        }
    }

    // Product defaults pending confirmation.
    private static let fallbackRetentionPeriod: TimeInterval = 30 * 24 * 60 * 60
    private static let maximumRecordCount = 100

    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    private let identityProvider: () -> UserIdentitySnapshot?
    private let stateQueue = DispatchQueue(label: "JsonOnlyMessageStore")
}

class InAppInMemoryPersister: InAppPersistenceProtocol {
    func getMessages() -> [IterableInAppMessage] {
        []
    }
    
    func persist(_ messages: [IterableInAppMessage]) {
        return
    }
    
    func clear() {
        return
    }
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
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
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
