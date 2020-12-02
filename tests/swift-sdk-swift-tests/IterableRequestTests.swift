//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableRequestTests: XCTestCase {
    func testGetRequestSerialization() throws {
        let path = "/a/b"
        let args = ["var1": "val1", "var2": "val2"]
        let request = IterableRequest.get(GetRequest(path: path, args: args))
        
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(IterableRequest.self, from: data)
        if case let IterableRequest.get(request) = decoded {
            XCTAssertEqual(request.path, path)
            XCTAssertEqual(request.args, args)
        } else {
            XCTFail("Could not decode request properly")
        }
    }
    
    func testGetRequestSerializationWithNilArgs() throws {
        let path = "/a/b"
        let request = IterableRequest.get(GetRequest(path: path, args: nil))
        
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(IterableRequest.self, from: data)
        if case let IterableRequest.get(request) = decoded {
            XCTAssertEqual(request.path, path)
            XCTAssertEqual(request.args, nil)
        } else {
            XCTFail("Could not decode request properly")
        }
    }
    
    func testPostRequestSerialization() throws {
        let path = "/a/b"
        let args = ["var1": "val1", "var2": "val2"]
        let body: [AnyHashable: Any] = ["b1": "body1", "b2": true, "b3": 22]
        let request = IterableRequest.post(PostRequest(path: path, args: args, body: body))
        
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(IterableRequest.self, from: data)
        if case let IterableRequest.post(request) = decoded {
            XCTAssertEqual(request.path, path)
            XCTAssertEqual(request.args, args)
            XCTAssertTrue(TestUtils.areEqual(dict1: request.body!, dict2: body))
        } else {
            XCTFail("Could not decode request properly")
        }
    }
    
    func testPostRequestSerializationWithNilBody() throws {
        let path = "/a/b"
        let request = IterableRequest.post(PostRequest(path: path, args: nil, body: nil))
        
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(IterableRequest.self, from: data)
        if case let IterableRequest.post(request) = decoded {
            XCTAssertEqual(request.path, path)
            XCTAssertNil(request.args)
            XCTAssertNil(request.body)
        } else {
            XCTFail("Could not decode request properly")
        }
    }
}
