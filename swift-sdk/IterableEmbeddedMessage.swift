//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

public struct IterableEmbeddedMessage {
    let metadata: EmbeddedMessageMetadata
    let elements: EmbeddedMessageElements?
    let payload: [AnyHashable: Any]?
    
    init(metadata: EmbeddedMessageMetadata,
         elements: EmbeddedMessageElements? = nil,
         payload: [AnyHashable : Any]? = nil) {
        self.metadata = metadata
        self.elements = elements
        self.payload = payload
    }

    init(id: String, placementId: String, campaignId: String? = nil, isProof: Bool? = nil) {
        let metadata = EmbeddedMessageMetadata(id: id, placementId: placementId, campaignId: campaignId, isProof: isProof)

        self.init(metadata: metadata)
    }
}

extension IterableEmbeddedMessage {
    struct EmbeddedMessageMetadata: Codable {
        let id: String
        let placementId: String
        let campaignId: String?
        let isProof: Bool?
    }

    struct EmbeddedMessageElements: Codable {
        let type: String?
        let buttons: [EmbeddedMessageElementsButton]?
        let images: [EmbeddedMessageElementsImage]?
        let text: [EmbeddedMessageElementsText]?
        
        struct EmbeddedMessageElementsButton: Codable {
            let id: String
            let title: String?
            let action: String?
        }

        struct EmbeddedMessageElementsImage: Codable {
            let id: String
            let url: String?
        }

        struct EmbeddedMessageElementsText: Codable {
            let id: String
            let text: String?
        }
    }
}
