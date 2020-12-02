//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class OrderedDictionaryTests: XCTestCase {
    func testOrderedDictCount() {
        var dict = OrderedDictionary<String, String>()
        
        XCTAssertEqual(dict.count, 0)
        
        dict["key"] = "value"
        
        XCTAssertEqual(dict.count, 1)
    }
    
    func testOrderedDictSubscript() {
        var dict = OrderedDictionary<String, String>()
        
        dict["key"] = "value"
        
        XCTAssertEqual(dict["key"], "value")
    }
    
    func testOrderedDictDescription() {
        var dict = OrderedDictionary<String, String>()
        
        dict["key"] = "value"
        
        XCTAssertEqual(dict.description, "key : value")
    }
    
    func testOrderedDictLiteralInit() {
        let dict = OrderedDictionary<String, String>(dictionaryLiteral: ("key", "value"))
        
        XCTAssertEqual(dict["key"], "value")
    }
    
    func testNonExistentKey() {
        let dict = OrderedDictionary<String, String>()
        
        XCTAssertNil(dict["key"])
    }
    
    func testRemoveValue() {
        var dict = OrderedDictionary<String, String>()
        
        let key = "asdf"
        
        dict[key] = "thing"
        
        XCTAssertNotNil(dict[key])
        
        dict[key] = nil
        
        XCTAssertNil(dict[key])
    }
}
