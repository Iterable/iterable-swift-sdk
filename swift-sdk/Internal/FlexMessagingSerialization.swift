//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

struct FlexMessagingSerialization {
    static func encode(messages: [IterableFlexMessage]) -> Data {
        guard let encoded = try? JSONEncoder().encode(messages) else {
            ITBError("unable to encode flex messages into JSON payload")
            return Data()
        }
        
        return encoded
    }
    
    static func decode(messages: Data) -> [IterableFlexMessage] {
        guard let decoded = try? JSONDecoder().decode([IterableFlexMessage].self, from: messages) else {
            ITBError("unable to decode JSON payload into flex messages")
            return []
        }
        
        return decoded
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

extension IterableFlexMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case metadata
        case elements
        case payload
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(metadata, forKey: .metadata)
        try? container.encodeIfPresent(elements, forKey: .elements)
        try? container.encodeIfPresent(FlexMessagingSerialization.encode(payload: payload), forKey: .payload)
    }
    
    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("unable to decode flex message payload")
            
            self.init(id: "", placementId: "")
            
            return
        }
        
        let metadata = (try? container.decode(FlexMessageMetadata.self, forKey: .metadata))
        let elements = (try? container.decode(FlexMessageElements.self, forKey: .elements))
        let payload = FlexMessagingSerialization.decode(payload: try? container.decode(Data.self, forKey: .payload))
        
        guard let metadata = metadata else {
            ITBError("unable to decode metadata section of flex message payload")
            self.init(id: "", placementId: "")
            
            return
        }
        
        self.init(metadata: metadata,
                  elements: elements,
                  payload: payload)
    }
}

