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
         identityProvider: @escaping () -> UserIdentitySnapshot?,
         identityCoordinator: IdentityCoordinator) {
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.identityProvider = identityProvider
        self.identityCoordinator = identityCoordinator
    }

    var identityContext: UserIdentityContext {
        identityCoordinator.capture(identityProvider: identityProvider)
    }

    @discardableResult
    func enqueue(_ message: IterableInAppMessage, identityContext: UserIdentityContext) -> Bool {
        guard let identity = identityContext.identity else { return false }
        var result = false
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            result = stateQueue.sync {
                guard var state = loadCurrentState(currentIdentity: identity) else { return false }
                let currentDate = dateProvider.currentDate
                guard !Self.isExpired(message, at: currentDate) else { return false }
                if state.entries.contains(where: { $0.message.messageId == message.messageId }) {
                    return true
                }
                guard !state.discardedUnacknowledgedMessageIds.contains(message.messageId) else { return false }
                guard !isAcknowledgedUnchanged(message, in: state) else { return false }
                state.acknowledgements.removeAll { $0.messageId == message.messageId }
                state.entries.append(Entry(message: message,
                                           storedAt: currentDate,
                                           didBeginInitialDelivery: false))
                trimEntries(&state)
                return persist(state)
            }
        }) else { return false }
        return result
    }

    @discardableResult
    func enqueue(_ messages: [IterableInAppMessage], identityContext: UserIdentityContext) -> Bool {
        guard let identity = identityContext.identity else { return false }
        var result = false
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            result = stateQueue.sync {
                guard var state = loadCurrentState(currentIdentity: identity) else { return false }
                let currentDate = dateProvider.currentDate
                var didChange = false

                messages.forEach { message in
                    guard !Self.isExpired(message, at: currentDate),
                          !state.entries.contains(where: { $0.message.messageId == message.messageId }),
                          !state.discardedUnacknowledgedMessageIds.contains(message.messageId),
                          !isAcknowledgedUnchanged(message, in: state) else {
                        return
                    }
                    state.acknowledgements.removeAll { $0.messageId == message.messageId }
                    state.entries.append(Entry(message: message,
                                               storedAt: currentDate,
                                               didBeginInitialDelivery: false))
                    didChange = true
                }

                guard didChange else { return true }
                trimEntries(&state)
                return persist(state)
            }
        }) else { return false }
        return result
    }

    func prepareDelivery(for message: IterableInAppMessage, identityContext: UserIdentityContext) -> Delivery? {
        guard let identity = identityContext.identity else { return nil }
        var result: Delivery?
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            result = stateQueue.sync {
                guard var state = loadCurrentState(currentIdentity: identity),
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
        }) else { return nil }
        return result
    }

    func getMessages() -> [IterableInAppMessage] {
        getMessages(identityContext: identityContext)
    }

    func getMessages(identityContext: UserIdentityContext) -> [IterableInAppMessage] {
        guard let identity = identityContext.identity else { return [] }
        var result = [IterableInAppMessage]()
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            result = stateQueue.sync {
                loadCurrentState(currentIdentity: identity)?.entries.map(\.message) ?? []
            }
        }) else { return [] }
        return result
    }

    struct AcknowledgementStatus {
        let unchangedMessageIds: Set<String>
        let changedMessageIds: Set<String>
    }

    func acknowledgementStatus(for messages: [IterableInAppMessage],
                               identityContext: UserIdentityContext) -> AcknowledgementStatus {
        guard let identity = identityContext.identity else {
            return AcknowledgementStatus(unchangedMessageIds: [], changedMessageIds: [])
        }
        var result = AcknowledgementStatus(unchangedMessageIds: [], changedMessageIds: [])
        guard identityCoordinator.performIfCurrent(identityContext, identityProvider: identityProvider, {
            result = stateQueue.sync {
                guard let state = loadCurrentState(currentIdentity: identity) else { return result }
                var unchangedMessageIds = Set<String>()
                var changedMessageIds = Set<String>()
                messages.forEach { message in
                    guard message.isJsonOnly else { return }
                    if state.discardedUnacknowledgedMessageIds.contains(message.messageId) {
                        unchangedMessageIds.insert(message.messageId)
                        return
                    }
                    guard let acknowledgement = state.acknowledgements.last(where: { $0.messageId == message.messageId }) else {
                        return
                    }
                    if let acknowledgedFingerprint = acknowledgement.payloadFingerprint,
                       let messageFingerprint = Self.payloadFingerprint(for: message),
                       acknowledgedFingerprint == messageFingerprint {
                        unchangedMessageIds.insert(message.messageId)
                    } else {
                        changedMessageIds.insert(message.messageId)
                    }
                }
                return AcknowledgementStatus(unchangedMessageIds: unchangedMessageIds,
                                             changedMessageIds: changedMessageIds)
            }
        }) else { return AcknowledgementStatus(unchangedMessageIds: [], changedMessageIds: []) }
        return result
    }

    @discardableResult
    func remove(messageId: String) -> Bool {
        let context = identityContext
        guard let identity = context.identity else { return false }
        var result = false
        guard identityCoordinator.performIfCurrent(context, identityProvider: identityProvider, {
            result = stateQueue.sync {
                guard var state = loadCurrentState(currentIdentity: identity),
                      let index = state.entries.firstIndex(where: { $0.message.messageId == messageId }) else {
                    return false
                }

                let message = state.entries.remove(at: index).message
                state.discardedUnacknowledgedMessageIds.removeAll { $0 == messageId }
                state.acknowledgements.removeAll { $0.messageId == messageId }
                state.acknowledgements.append(Acknowledgement(messageId: messageId,
                                                              payloadFingerprint: Self.payloadFingerprint(for: message)))
                state.acknowledgements = Array(state.acknowledgements.suffix(Self.maximumAcknowledgementCount))
                return persist(state)
            }
        }) else { return false }
        return result
    }

    func clear() {
        identityCoordinator.withCriticalSection {
            stateQueue.sync {
                localStorage.jsonOnlyMessageQueueData = nil
            }
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

    private struct Acknowledgement: Codable {
        let messageId: String
        let payloadFingerprint: Data?
    }

    private struct State: Codable {
        let identity: StoredIdentity
        var entries: [Entry]
        var acknowledgements: [Acknowledgement]
        var discardedUnacknowledgedMessageIds: [String]

        init(identity: StoredIdentity,
             entries: [Entry],
             acknowledgements: [Acknowledgement] = [],
             discardedUnacknowledgedMessageIds: [String] = []) {
            self.identity = identity
            self.entries = entries
            self.acknowledgements = acknowledgements
            self.discardedUnacknowledgedMessageIds = discardedUnacknowledgedMessageIds
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            identity = try container.decode(StoredIdentity.self, forKey: .identity)
            entries = try container.decode([Entry].self, forKey: .entries)
            acknowledgements = try container.decodeIfPresent([Acknowledgement].self, forKey: .acknowledgements) ?? []
            discardedUnacknowledgedMessageIds = try container.decodeIfPresent([String].self,
                                                                               forKey: .discardedUnacknowledgedMessageIds) ?? []
        }
    }

    private static func isExpired(_ message: IterableInAppMessage, at currentDate: Date) -> Bool {
        guard let expiresAt = message.expiresAt else { return false }
        return expiresAt <= currentDate
    }

    private func loadCurrentState(currentIdentity: UserIdentitySnapshot) -> State? {
        let identity = StoredIdentity(currentIdentity)
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
        let expiredEntries = state.entries.filter { entry in
            if entry.message.expiresAt != nil {
                return Self.isExpired(entry.message, at: currentDate)
            }
            return entry.storedAt.addingTimeInterval(Self.fallbackRetentionPeriod) <= currentDate
        }

        if !expiredEntries.isEmpty {
            state.discardedUnacknowledgedMessageIds.append(contentsOf: expiredEntries.map { $0.message.messageId })
            state.discardedUnacknowledgedMessageIds = Array(state.discardedUnacknowledgedMessageIds.suffix(Self.maximumDiscardedMessageCount))
            let expiredMessageIds = Set(expiredEntries.map { $0.message.messageId })
            state.entries.removeAll { expiredMessageIds.contains($0.message.messageId) }
            stateChanged = true
        }

        if stateChanged, !persist(state) { return nil }
        return state
    }

    private func isAcknowledgedUnchanged(_ message: IterableInAppMessage, in state: State) -> Bool {
        guard let messageFingerprint = Self.payloadFingerprint(for: message) else { return false }
        return state.acknowledgements.contains {
            $0.messageId == message.messageId && $0.payloadFingerprint == messageFingerprint
        }
    }

    private func trimEntries(_ state: inout State) {
        let overflow = state.entries.count - Self.maximumRecordCount
        guard overflow > 0 else { return }
        state.discardedUnacknowledgedMessageIds.append(contentsOf: state.entries.prefix(overflow).map { $0.message.messageId })
        state.discardedUnacknowledgedMessageIds = Array(state.discardedUnacknowledgedMessageIds.suffix(Self.maximumDiscardedMessageCount))
        state.entries = Array(state.entries.suffix(Self.maximumRecordCount))
    }

    private static func payloadFingerprint(for message: IterableInAppMessage) -> Data? {
        guard let customPayload = message.customPayload,
              let canonicalPayload = canonicalJson(customPayload) else { return nil }
        return canonicalPayload.data(using: .utf8)
    }

    private static func canonicalJson(_ value: Any) -> String? {
        if let dictionary = value as? [AnyHashable: Any] {
            var entries = [(String, Any)]()
            for (key, value) in dictionary {
                guard let key = key as? String else { return nil }
                entries.append((key, value))
            }
            entries.sort { $0.0 < $1.0 }
            var encodedEntries = [String]()
            for (key, value) in entries {
                guard let encodedKey = canonicalJson(key),
                      let encodedValue = canonicalJson(value) else { return nil }
                encodedEntries.append("\(encodedKey):\(encodedValue)")
            }
            return "{\(encodedEntries.joined(separator: ","))}"
        }
        if let array = value as? [Any] {
            var encodedValues = [String]()
            for value in array {
                guard let encodedValue = canonicalJson(value) else { return nil }
                encodedValues.append(encodedValue)
            }
            return "[\(encodedValues.joined(separator: ","))]"
        }
        guard JSONSerialization.isValidJSONObject([value]),
              let data = try? JSONSerialization.data(withJSONObject: [value], options: []),
              let encodedArray = String(data: data, encoding: .utf8) else { return nil }
        return String(encodedArray.dropFirst().dropLast())
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

    private static let fallbackRetentionPeriod: TimeInterval = 30 * 24 * 60 * 60
    private static let maximumRecordCount = 100
    private static let maximumAcknowledgementCount = 100
    private static let maximumDiscardedMessageCount = 100

    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    private let identityProvider: () -> UserIdentitySnapshot?
    private let identityCoordinator: IdentityCoordinator
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
