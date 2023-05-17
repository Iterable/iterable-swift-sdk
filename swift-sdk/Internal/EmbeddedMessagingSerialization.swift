//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

struct EmbeddedMessagingSerialization {
    static func encode(messages: [IterableEmbeddedMessage]) -> Data {
        guard let encoded = try? JSONEncoder().encode(EmbeddedMessagesPayload(embeddedMessages: messages)) else {
            ITBError("unable to encode embedded messages into JSON payload")
            return Data()
        }
        
        return encoded
    }
    
    static func decode(messages: Data) -> [IterableEmbeddedMessage] {
        guard let decoded = try? JSONDecoder().decode(EmbeddedMessagesPayload.self, from: messages) else {
            ITBError("unable to decode JSON payload into embedded messages")
            return []
        }
        
        return decoded.embeddedMessages
    }
    
    static func encode(payload: [AnyHashable: Any]?) -> Data? {
        guard let payload = payload else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: payload)
    }
    
    static func decode(payload: Data?) -> [AnyHashable: Any]? {
        guard let payload = payload else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: payload) as? [AnyHashable: Any]
    }
}

struct EmbeddedMessagesPayload: Codable {
    let embeddedMessages: [IterableEmbeddedMessage]
}

extension IterableEmbeddedMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case metadata
        case elements
        case payload
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(metadata, forKey: .metadata)
        try? container.encodeIfPresent(elements, forKey: .elements)
        try? container.encodeIfPresent(EmbeddedMessagingSerialization.encode(payload: payload), forKey: .payload)
    }
    
    public convenience init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("unable to decode embedded messages payload")
            
            self.init(id: 0)
            
            return
        }
        
        let metadata = (try? container.decode(EmbeddedMessageMetadata.self, forKey: .metadata))
        let elements = (try? container.decode(EmbeddedMessageElements.self, forKey: .elements))
        let payload = EmbeddedMessagingSerialization.decode(payload: try? container.decode(Data.self, forKey: .payload))
        
        guard let metadata = metadata else {
            ITBError("unable to decode metadata section of embedded messages payload")
            self.init(id: 0)
            
            return
        }
        
        self.init(metadata: metadata,
                  elements: elements,
                  payload: payload)
    }
}

