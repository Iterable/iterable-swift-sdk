//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc protocol DateProviderProtocol: AnyObject {
    @objc var currentDate: Date { get }
}

class SystemDateProvider: DateProviderProtocol {
    public init() {}
    
    public var currentDate: Date {
        return Date()
    }
}
