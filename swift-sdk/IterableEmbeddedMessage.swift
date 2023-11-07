//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@objcMembers
public final class EmbeddedMessageMetadata {
    public let messageId: String
    public let campaignId: Int?
    public let isProof: Bool?
    public let placementId: Int?
    
    
    init(messageId: String,
         campaignId: Int? = nil,
         isProof: Bool? = nil,
         placementId: Int? = nil) {
        self.messageId = messageId
        self.campaignId = campaignId
        self.isProof = isProof
        self.placementId = placementId
    }
}

@objcMembers
public final class EmbeddedMessageElementsButton {
    public let id: String
    public let title: String?
    public let action: IterableAction?
        
    init(id: String,
         title: String? = nil,
         action: IterableAction? = nil) {
        self.id = id
        self.title = title
        self.action = action
    }
}
    
@objcMembers
public final class EmbeddedMessageElementsText {
    public let id: String
    public let text: String?
            
    init(id: String,
         text: String? = nil) {
        self.id = id
        self.text = text
    }
}

@objcMembers
public final class EmbeddedMessageElements {
    public let title: String?
    public let body: String?
    public let mediaUrl: String?
    
    public let buttons: [EmbeddedMessageElementsButton]?
    public let text: [EmbeddedMessageElementsText]?
    public let defaultAction: IterableAction?
    
    init(title: String? = nil,
         body: String? = nil,
         mediaUrl: String? = nil,
         buttons: [EmbeddedMessageElementsButton]? = nil,
         text: [EmbeddedMessageElementsText]? = nil,
         defaultAction: IterableAction? = nil) {
        self.title = title
        self.body = body
        self.mediaUrl = mediaUrl
        self.buttons = buttons
        self.text = text
        self.defaultAction = defaultAction
    }
}

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
