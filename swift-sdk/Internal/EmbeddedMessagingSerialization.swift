//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

struct AnyDecodable: Decodable {
    let value: Any

    // the current implementation decodes the following value types: null, int, string, bool, double, array, and dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        }
        else if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let arrayVal = try? container.decode([AnyDecodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictionaryVal = try? container.decode([String: AnyDecodable].self) {
            var dictionary: [String: Any] = [:]
            for (key, val) in dictionaryVal {
                dictionary[key] = val.value
            }
            value = dictionary
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Container contains an unexpected type")
        }
    }
}


struct EmbeddedMessagingSerialization {
    static func encode(placements: [Placement]) -> Data {
        guard let encoded = try? JSONEncoder().encode(PlacementsPayload(placements: placements)) else {
            ITBError("unable to encode placements into JSON payload")
            return Data()
        }
        
        return encoded
    }
    
    static func decode(placements: Data) -> [IterableEmbeddedMessage] {
        guard let decoded = try? JSONDecoder().decode(PlacementsPayload.self, from: placements) else {
            ITBError("unable to decode JSON payload into placements")
            return []
        }
        
        let messages = decoded.placements.flatMap { $0.embeddedMessages }
        return messages
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

struct Placement: Codable {
    let placementId: Int?
    let embeddedMessages: [IterableEmbeddedMessage]
}

struct PlacementsPayload: Codable {
    let placements: [Placement]
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
            
            self.init(messageId: "")
            
            return
        }
        
        let metadata = (try? container.decode(EmbeddedMessageMetadata.self, forKey: .metadata))
        let elements = (try? container.decode(EmbeddedMessageElements.self, forKey: .elements))
        var payload: [String: Any]? = nil
        
        do {
            let anyDecodable = try container.decodeIfPresent(AnyDecodable.self, forKey: .payload)
            payload = anyDecodable?.value as? [String: Any]
        } catch {
            ITBError("Error decoding payload data: \(error)")
        }
        
        guard let metadata = metadata else {
            ITBError("unable to decode metadata section of embedded messages payload")
            self.init(messageId: "")
            
            return
        }
        
        self.init(metadata: metadata,
                  elements: elements,
                  payload: payload)
    }
}

