//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

public struct IterableFlexMessage {
    let metadata: FlexMessageMetadata
    let elements: FlexMessageElements?
    let payload: [AnyHashable: Any]?
    
    init(metadata: FlexMessageMetadata,
         elements: FlexMessageElements? = nil,
         payload: [AnyHashable : Any]? = nil) {
        self.metadata = metadata
        self.elements = elements
        self.payload = payload
    }

    init(id: String, placementId: String, campaignId: String? = nil, isProof: Bool? = nil) {
        let metadata = FlexMessageMetadata(id: id, placementId: placementId, campaignId: campaignId, isProof: isProof)

        self.init(metadata: metadata)
    }
}

extension IterableFlexMessage {
    struct FlexMessageMetadata: Codable {
        let id: String
        let placementId: String
        let campaignId: String?
        let isProof: Bool?
    }

    struct FlexMessageElements: Codable {
        let type: String?
        let buttons: [FlexMessageElementsButton]?
        let images: [FlexMessageElementsImage]?
        let text: [FlexMessageElementsText]?
        
        struct FlexMessageElementsButton: Codable {
            let id: String
            let title: String?
            let action: String?
        }

        struct FlexMessageElementsImage: Codable {
            let id: String
            let url: String?
        }

        struct FlexMessageElementsText: Codable {
            let id: String
            let text: String?
        }
    }
}
