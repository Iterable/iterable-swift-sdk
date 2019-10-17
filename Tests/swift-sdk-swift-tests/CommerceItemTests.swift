//
//  Created by Jay Kim on 5/22/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class CommerceItemTests: XCTestCase {
    func testToDictionary() {
        let commerceItemDictionary = CommerceItem(id: "commerceItemId", name: "commerceItemName", price: 6, quantity: 9000).toDictionary()
        
        let expected: [AnyHashable: Any] = ["id": "commerceItemId",
                                            "name": "commerceItemName",
                                            "price": 6,
                                            "quantity": 9000]
        
        XCTAssertEqual(NSDictionary(dictionary: commerceItemDictionary), NSDictionary(dictionary: expected))
    }
}
