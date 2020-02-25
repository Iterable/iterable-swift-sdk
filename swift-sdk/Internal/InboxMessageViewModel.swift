//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

class InboxMessageViewModel {
    let title: String
    let subtitle: String?
    let imageUrl: String?
    var imageData: Data?
    let createdAt: Date?
    let read: Bool
    let iterableMessage: IterableInAppMessage
    
    init(message: IterableInAppMessage) {
        title = InboxMessageViewModel.getTitle(message: message)
        subtitle = InboxMessageViewModel.getSubtitle(message: message)
        imageUrl = InboxMessageViewModel.getImageUrl(message: message)
        createdAt = message.createdAt
        read = message.read
        iterableMessage = message
    }
    
    func hasValidImageUrl() -> Bool {
        guard let imageUrlString = imageUrl else {
            return false
        }
        
        guard let _ = URL(string: imageUrlString) else {
            return false
        }
        
        return true
    }
    
    private static func getTitle(message: IterableInAppMessage) -> String {
        return message.inboxMetadata?.title ?? ""
    }
    
    private static func getSubtitle(message: IterableInAppMessage) -> String? {
        return message.inboxMetadata?.subtitle
    }
    
    private static func getImageUrl(message: IterableInAppMessage) -> String? {
        return message.inboxMetadata?.icon
    }
}

extension InboxMessageViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(iterableMessage.messageId)
        hasher.combine(read)
    }
}

extension InboxMessageViewModel: Equatable {
    static func == (lhs: InboxMessageViewModel, rhs: InboxMessageViewModel) -> Bool {
        guard lhs.iterableMessage.messageId == rhs.iterableMessage.messageId else { return false }
        guard lhs.read == rhs.read else { return false }
        
        return true
    }
}
