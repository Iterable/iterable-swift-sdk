//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

public struct IterableFlexMessage {
    let metadata: FlexMessageMetadata
    let elements: FlexMessageElements?
    let custom: [AnyHashable: Any]?
    let payload: [AnyHashable: Any]?
    
    init(metadata: FlexMessageMetadata,
         elements: FlexMessageElements? = nil,
         custom: [AnyHashable : Any]? = nil,
         payload: [AnyHashable : Any]? = nil) {
        self.metadata = metadata
        self.elements = elements
        self.custom = custom
        self.payload = payload
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
            let id: String
            let title: String?
            let action: String?
        }
        
        struct FlexMessageElementsImages {
            let id: String
            let url: String?
        }
        
        struct FlexMessageElementsText {
            let id: String
            let text: String?
        }
        
        let type: String?
        let buttons: [FlexMessageElementsButton]?
        let images: [FlexMessageElementsImages]?
        let text: [FlexMessageElementsText]?
    }
}
