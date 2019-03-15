//
//  Created by Tapash Majumder on 3/1/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

extension IterableInboxMessage : Codable {
    enum CodingKeys: String, CodingKey {
        case content
    }
    
    enum ContentCodingKeys: String, CodingKey {
        case type
    }
    
    public convenience init(from decoder: Decoder) {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else {
            ITBError("Can not decode, returning default")
            self.init(messageId: "",
                      campaignId: "",
                      content: IterableInboxMessage.createDefaultContent()
            )
            return
        }
        
        let message = IterableMessagePersistenceHelper.message(from: decoder)
        
        let content = IterableInboxMessage.decodeContent(from: container)
        
        self.init(messageId: message.messageId,
                  campaignId: message.campaignId,
                  expiresAt: message.expiresAt,
                  content: content,
                  customPayload: message.customPayload)
        
        self.processed = message.processed
        self.consumed = message.consumed
    }
    
    public func encode(to encoder: Encoder) {
        let message = IterableMessagePersistenceHelper.IterableMessageInfo(saveToInbox: saveToInbox,
                                                                           messageId: messageId,
                                                                           campaignId: campaignId,
                                                                           expiresAt: expiresAt,
                                                                           customPayload: customPayload,
                                                                           processed: processed,
                                                                           consumed: consumed)
        IterableMessagePersistenceHelper.encode(message: message, to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        IterableInboxMessage.encode(content: content, inContainer: &container)
    }
    
    private static func decodeContent(from container: KeyedDecodingContainer<IterableInboxMessage.CodingKeys>) -> IterableContent {
        guard let contentContainer = try? container.nestedContainer(keyedBy: ContentCodingKeys.self, forKey: .content) else {
            ITBError()
            return createDefaultContent()
        }
        
        let contentType = (try? contentContainer.decode(String.self, forKey: .type)).map{ IterableContentType.from(string: $0) } ?? .inboxHtml
        
        switch contentType {
        case .inboxHtml:
            return (try? container.decode(IterableInboxHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        default:
            return (try? container.decode(IterableInboxHtmlContent.self, forKey: .content)) ?? createDefaultContent()
        }
    }
    
    private static func encode(content: IterableContent, inContainer container: inout KeyedEncodingContainer<IterableInboxMessage.CodingKeys>) {
        switch content.type {
        case .inboxHtml:
            if let content = content as? IterableInboxHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        default:
            if let content = content as? IterableInboxHtmlContent {
                try? container.encode(content, forKey: .content)
            }
        }
    }
    
    private static func createDefaultContent() -> IterableContent {
        return IterableInboxHtmlContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "", title: nil, subTitle: nil, icon: nil)
    }
}
