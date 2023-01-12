//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

public struct IterableFlexMessage {
    let metadata: FlexMessageMetadata
    let elements: FlexMessageElements?
    let custom: [AnyHashable: Any]?
    let payload: [AnyHashable: Any]?
    
    private init(payload: [AnyHashable : Any]? = nil,
                 metadata: FlexMessageMetadata,
                 elements: FlexMessageElements? = nil,
                 custom: [AnyHashable : Any]? = nil) {
        self.payload = payload
        self.metadata = metadata
        self.elements = elements
        self.custom = custom
    }
    
    init(id: String) {
        let metadata = FlexMessageMetadata(id: id)
        
        self.init(metadata: metadata)
    }
}

extension IterableFlexMessage {
    struct FlexMessageMetadata {
        let id: String
        let placementId: String?
        let campaignId: String?
        let isProof: Bool?
        
        init(id: String, placementId: String? = nil, campaignId: String? = nil, isProof: Bool? = nil) {
            self.id = id
            self.placementId = placementId
            self.campaignId = campaignId
            self.isProof = isProof
        }
    }
    
    struct FlexMessageElements {
        struct FlexMessageElementsButton {
            let title: String?
            let action: String?
        }
        
        let type: String?
        let buttons: [String: FlexMessageElementsButton]?
        let images: [String: String]?
        let text: [String: String]?
    }
}
