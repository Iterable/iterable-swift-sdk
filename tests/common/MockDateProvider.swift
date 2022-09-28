//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockDateProvider: DateProviderProtocol {
    var currentDate = Date()
    
    func reset() {
        currentDate = Date()
    }
}
