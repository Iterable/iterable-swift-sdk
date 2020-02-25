//
//  Created by Tapash Majumder on 6/28/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public enum IterableActionSource: Int {
    case push
    case universalLink
    case inApp
}

@objcMembers public class IterableActionContext: NSObject {
    public let action: IterableAction
    public let source: IterableActionSource
    
    public init(action: IterableAction, source: IterableActionSource) {
        self.action = action
        self.source = source
    }
}
