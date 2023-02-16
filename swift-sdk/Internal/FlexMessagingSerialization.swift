//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

struct FlexMessagingSerialization {
    static func serialize(messages: [IterableFlexMessage]) -> [AnyHashable: Any] {
        return [:]
    }
    
    static func decode(messages: [AnyHashable: Any]) -> [IterableFlexMessage] {
        return []
    }
    
    static func serialize(payload: [AnyHashable: Any]?) -> Data? {
        guard let payload = payload else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: payload)
    }
    
    static func deserialize(payload: Data?) -> [AnyHashable: Any]? {
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
        try? container.encodeIfPresent(FlexMessagingSerialization.serialize(payload: payload), forKey: .payload)
    }

    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("unable to decode flex message payload")
            
            self.init(id: "", placementId: "")
            
            return
        }
        
        let metadata = (try? container.decode(FlexMessageMetadata.self, forKey: .metadata))
        let elements = (try? container.decode(FlexMessageElements.self, forKey: .elements))
        let payload = FlexMessagingSerialization.deserialize(payload: try? container.decode(Data.self, forKey: .payload))
        
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
