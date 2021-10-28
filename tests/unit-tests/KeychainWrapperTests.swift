//
//  Copyright © 2021 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class KeychainWrapperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSave() throws {
        let wrapper = KeychainWrapper(serviceName: "test-keychain")
        let valueString = "this is a string value"
        let value = valueString.data(using: .utf8)!
        let key = "zee-key"
        let isSaved = wrapper.set(value, forKey: key)
        
        let retrievedData = wrapper.data(forKey: key)!
        let retrieved = String(data: retrievedData, encoding: .utf8)!
        
        XCTAssertTrue(isSaved)
        XCTAssertEqual(retrieved, valueString)
    }

    func testRewrite() throws {
        let wrapper = KeychainWrapper(serviceName: "test-keychain")
        let key = "zee-key"

        let valueString = "this is a string value"
        let value = valueString.data(using: .utf8)!
        XCTAssertTrue(wrapper.set(value, forKey: key))

        let newValueString = "new string"
        let newValue = newValueString.data(using: .utf8)!
        XCTAssertTrue(wrapper.set(newValue, forKey: key))

        let retrievedData = wrapper.data(forKey: key)!
        let retrieved = String(data: retrievedData, encoding: .utf8)!
        
        XCTAssertEqual(retrieved, newValueString)
    }
    
    func testDelete() throws {
        let wrapper = KeychainWrapper(serviceName: "test-keychain")
        let key = "zee-key"

        let valueString = "this is a string value"
        let value = valueString.data(using: .utf8)!
        XCTAssertTrue(wrapper.set(value, forKey: key))

        wrapper.removeValue(forKey: key)
        XCTAssertNil(wrapper.data(forKey: key))
    }
}
