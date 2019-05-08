//
//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

class InboxMessageViewModel {
    let title: String
    let subtitle: String?
    let imageUrl: String?
    var imageData: Data? = nil
    let createdAt: Date? = nil // Not used at the moment
    let read: Bool
    let iterableMessage: IterableInAppMessage
    
    init(message: IterableInAppMessage) {
        self.title = InboxMessageViewModel.getTitle(message: message)
        self.subtitle = InboxMessageViewModel.getSubtitle(message: message)
        self.imageUrl = InboxMessageViewModel.getImageUrl(message: message)
        self.read = message.read
        self.iterableMessage = message
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

extension InboxMessageViewModel : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.iterableMessage.messageId)
        hasher.combine(self.read)
    }
}

extension InboxMessageViewModel : Equatable {
    static func == (lhs: InboxMessageViewModel, rhs: InboxMessageViewModel) -> Bool {
        guard lhs.iterableMessage.messageId == rhs.iterableMessage.messageId else {
            return false
        }
        guard lhs.read == rhs.read else {
            return false
        }
        return true
    }
}
