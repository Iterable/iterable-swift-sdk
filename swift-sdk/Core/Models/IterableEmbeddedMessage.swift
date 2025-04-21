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
    
    convenience init(messageId: String, campaignId: Int? = nil, isProof: Bool? = nil, placementId: Int? = nil) {
        let metadata = EmbeddedMessageMetadata(messageId: messageId, campaignId: campaignId, isProof: isProof, placementId: placementId)
        
        self.init(metadata: metadata)
    }
}

extension IterableEmbeddedMessage {
    public struct EmbeddedMessageMetadata: Codable {
        public let messageId: String
        public let campaignId: Int?
        public let isProof: Bool?
        public let placementId: Int?
        
        init(messageId: String, campaignId: Int? = nil, isProof: Bool? = nil, placementId: Int? = nil) {
                    self.messageId = messageId
                    self.campaignId = campaignId
                    self.isProof = isProof
                    self.placementId = placementId
                }
    }

    public struct EmbeddedMessageElements: Codable {
        public let title: String?
        public let body: String?
        public let mediaUrl: String?
        public let mediaUrlCaption: String?
        
        public let buttons: [EmbeddedMessageElementsButton]?
        public let text: [EmbeddedMessageElementsText]?
        public let defaultAction: EmbeddedMessageElementsDefaultAction?
        
        public struct EmbeddedMessageElementsButton: Codable {
            public let id: String
            public let title: String?
            public let action: EmbeddedMessageElementsButtonAction?
        }

        public struct EmbeddedMessageElementsText: Codable {
            public let id: String
            public let text: String?
        }

        public struct EmbeddedMessageElementsButtonAction: Codable {
            public let type: String
            public let data: String?
        }
        
        public struct EmbeddedMessageElementsDefaultAction: Codable {
            public let type: String
            public let data: String?
        }
    }
}
