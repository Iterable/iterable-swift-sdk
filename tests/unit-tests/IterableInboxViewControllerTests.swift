//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableInboxViewControllerTests: XCTestCase {
    func testInitializers() {
        XCTAssertNotNil(IterableInboxViewController())
        
        XCTAssertNotNil(IterableInboxViewController(nibName: nil, bundle: nil))
        
        XCTAssertNotNil(IterableInboxViewController(style: .plain))
    }
}
