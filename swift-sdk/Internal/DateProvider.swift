//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc protocol DateProviderProtocol: AnyObject {
    @objc var currentDate: Date { get }
}

class SystemDateProvider: DateProviderProtocol {
    public init() {}
    
    public var currentDate: Date {
        Date()
    }
}
