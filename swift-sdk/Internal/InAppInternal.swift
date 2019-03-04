//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum IterableInAppType : Int, Codable {
    case `default`
    case inbox
}

internal protocol IterableMessageProtocol {
    /// the in-app type
    var inAppType: IterableInAppType { get }
    
    /// the id for the inApp message
    var messageId: String { get }
    
    /// the campaign id for this message
    var campaignId: String { get }
    
    /// when to expire this in-app, nil means do not expire
    var expiresAt: Date? { get }
    
    /// Custom Payload for this message.
    var customPayload: [AnyHashable : Any]? { get }

    /// Whether we have processed this message.
    /// Note: This is internal and not public
    var processed: Bool { get set }
    
    /// Mark this message to be removed from server queue.
    /// Note: This is internal and not public
    var consumed: Bool { get set }
}

extension IterableInAppMessage : IterableMessageProtocol {
    var inAppType : IterableInAppType { return .default }
}

extension IterableInboxMessage : IterableMessageProtocol {
    var inAppType : IterableInAppType { return .inbox }
}
