//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

@objcMembers
public class MockUrlDelegate: NSObject, IterableURLDelegate {
    // returnValue = true if we handle the url, else false
    override private convenience init() {
        self.init(returnValue: false)
    }
    
    public init(returnValue: Bool) {
        self.returnValue = returnValue
    }
    
    private(set) var returnValue: Bool
    private(set) var url: URL?
    private(set) var context: IterableActionContext?
    var callback: ((URL, IterableActionContext) -> Void)?
    
    public func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        self.url = url
        self.context = context
        callback?(url, context)
        return returnValue
    }
}
