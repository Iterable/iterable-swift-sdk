//
//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct InboxMessageViewModel {
    let title: String
    let subTitle: String?
    let imageUrl: String?
    let createdAt: Date? // Not used at the moment
    let read: Bool
    let iterableMessage: IterableInAppMessage
    
    static func from(message: IterableInAppMessage) -> InboxMessageViewModel {
        return InboxMessageViewModel(title: getTitle(message: message),
                              subTitle: getSubTitle(message: message),
                              imageUrl: getImageUrl(message: message),
                              createdAt: nil,
                              read: message.read,
                              iterableMessage: message)
    }

    private static func getTitle(message: IterableInAppMessage) -> String {
        return message.inboxMetadata?.title ?? ""
    }
    
    private static func getSubTitle(message: IterableInAppMessage) -> String? {
        return message.inboxMetadata?.subTitle
    }
    
    private static func getImageUrl(message: IterableInAppMessage) -> String? {
        return message.inboxMetadata?.icon
    }
}
