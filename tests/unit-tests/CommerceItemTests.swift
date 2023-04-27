//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class CommerceItemTests: XCTestCase {
    func testToDictionaryWithRequiredFields() {
        let commerceItemDictionary = CommerceItem(id: "commerceItemId", name: "commerceItemName", price: 6, quantity: 9000).toDictionary()
        
        let expected: [AnyHashable: Any] = ["id": "commerceItemId",
                                            "name": "commerceItemName",
                                            "price": 6,
                                            "quantity": 9000]
        
        XCTAssertEqual(NSDictionary(dictionary: commerceItemDictionary), NSDictionary(dictionary: expected))
    }
    
    func testToDictionaryWithAllFields() {
        let itemDictionary = CommerceItem(id: "THINKTANK",
                                          name: "Tachikoma",
                                          price: 7.62,
                                          quantity: 9,
                                          sku: "kusanagi",
                                          description: "spider type multi leg/multi ped combat vehicle equipped with AI",
                                          url: "stand-alone-complex",
                                          imageUrl: "laughing-man",
                                          categories: ["section 9",
                                                       "personnel transport"],
                                          dataFields: ["color": "yellow",
                                                       "count": 8]).toDictionary()
        
        let expected: [AnyHashable: Any] = ["id": "THINKTANK",
                                            "name": "Tachikoma",
                                            "price": 7.62,
                                            "quantity": 9,
                                            "sku": "kusanagi",
                                            "description": "spider type multi leg/multi ped combat vehicle equipped with AI",
                                            "url": "stand-alone-complex",
                                            "imageUrl": "laughing-man",
                                            "categories": ["section 9",
                                                           "personnel transport"],
                                            "dataFields": ["color": "yellow",
                                                           "count": 8] as [String : Any]]
        
        XCTAssertEqual(NSDictionary(dictionary: itemDictionary), NSDictionary(dictionary: expected))
    }
}
