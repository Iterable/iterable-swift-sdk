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
    
    static func serialize(custom: [AnyHashable: Any]?) -> Data? {
        guard let custom = custom else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: custom)
    }
    
    static func deserialize(custom: Data?) -> [AnyHashable: Any]? {
        guard let custom = custom else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: custom) as? [AnyHashable: Any]
    }
}

extension IterableFlexMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case metadata
        case elements
        case custom
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(metadata, forKey: .metadata)
        try? container.encodeIfPresent(elements, forKey: .elements)
        try? container.encodeIfPresent(FlexMessagingSerialization.serialize(custom: custom), forKey: .custom)
    }

    public init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("unable to decode flex message payload")
            
            self.init(id: "", placementId: "")
            
            return
        }
        
        let metadata = (try? container.decode(FlexMessageMetadata.self, forKey: .metadata))
        let elements = (try? container.decode(FlexMessageElements.self, forKey: .elements))
        let custom = FlexMessagingSerialization.deserialize(custom: try? container.decode(Data.self, forKey: .custom))
        
        guard let metadata = metadata else {
            ITBError("unable to decode metadata section of flex message payload")
            self.init(id: "", placementId: "")
            
            return
        }
        
        self.init(metadata: metadata,
                  elements: elements,
                  custom: custom)
    }
}
