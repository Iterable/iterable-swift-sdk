//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public protocol DateProviderProtocol: AnyObject {
    @objc var currentDate: Date { get }
}

public class SystemDateProvider: DateProviderProtocol {
    public init() {}
    
    public var currentDate: Date {
        return Date()
    }
}
