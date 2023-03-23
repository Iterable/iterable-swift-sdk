//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@objcMembers
public final class IterableEmbeddedMessage: NSObject {
    public let metadata: EmbeddedMessageMetadata
    public let elements: EmbeddedMessageElements?
    public let payload: [AnyHashable: Any]?
    
    init(metadata: EmbeddedMessageMetadata,
         elements: EmbeddedMessageElements? = nil,
         payload: [AnyHashable : Any]? = nil) {
        self.metadata = metadata
        self.elements = elements
        self.payload = payload
    }
    
    convenience init(id: Int, campaignId: String? = nil, isProof: Bool? = nil) {
        let metadata = EmbeddedMessageMetadata(id: id, campaignId: campaignId, isProof: isProof)
        
        self.init(metadata: metadata)
    }
}

extension IterableEmbeddedMessage {
    public struct EmbeddedMessageMetadata: Codable {
        let id: Int
        let campaignId: String?
        let isProof: Bool?
    }

    public struct EmbeddedMessageElements: Codable {
        let title: String?
        let body: String?
        let mediaUrl: String?
        
        let buttons: [EmbeddedMessageElementsButton]?
        let images: [EmbeddedMessageElementsImage]?
        let text: [EmbeddedMessageElementsText]?
        
        public struct EmbeddedMessageElementsButton: Codable {
            let id: String
            let title: String?
            let action: EmbeddedMessageElementsButtonAction?
        }

        public struct EmbeddedMessageElementsImage: Codable {
            let id: String
            let url: String?
        }

        public struct EmbeddedMessageElementsText: Codable {
            let id: String
            let text: String?
        }

        public struct EmbeddedMessageElementsButtonAction: Codable {
            public let type: String
            public let data: String?
        }
    }
}
