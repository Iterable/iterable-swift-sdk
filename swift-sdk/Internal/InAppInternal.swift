//
//  Created by Tapash Majumder on 2/28/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum IterableInAppType : Int, Codable {
    case `default`
    case inbox
}


internal protocol IterableMessageInternal : IterableMessage {
    /// the in-app type
    var inAppType: IterableInAppType { get }
    
    /// Whether we have processed this message.
    /// Note: This is internal and not public
    var processed: Bool { get set }
    
    /// Mark this message to be removed from server queue.
    /// Note: This is internal and not public
    var consumed: Bool { get set }
}

extension IterableInAppMessage : IterableMessageInternal {
    var inAppType : IterableInAppType { return .default }
}

extension IterableInboxMessage : IterableMessageInternal {
    var inAppType : IterableInAppType { return .inbox }
}
