//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableRequestUtilTests: XCTestCase {
    func testDictToJsonData() {
        let args: [AnyHashable: Any] = [
            "email": "ilya@iterable.com",
            "device": [
                "token": "foo",
                "platform": "bar",
                "applicationName": "baz",
                "dataFields": [
                    "name": "green",
                    "localizedModel": "eggs",
                    "userInterfaceIdiom": "and",
                    "identifierForVendor": "ham",
                    "systemName": "iterable",
                    "systemVersion": "is",
                    "model": "awesome",
                ],
            ] as [String : Any],
        ]
        
        let data = IterableRequestUtil.dictToJsonData(args)!
        let jsonObject = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
        XCTAssertTrue(NSDictionary(dictionary: args).isEqual(to: jsonObject))
    }
    
    func testGetRequest() {
        let apiEndPoint = "https://somewhere.com/"
        let path = "path"
        let headers = [
            "header1": "headerValue1",
            "header2": "headerValue2",
        ]
        let args = ["arg1": "value1", "arg2": "value2"]
        let request = IterableRequestUtil.createGetRequest(forApiEndPoint: apiEndPoint, path: path, headers: headers, args: args)!
        
        let queryParams = [
            (name: "arg1", value: "value1"),
            (name: "arg2", value: "value2"),
        ]
        
        TestUtils.validate(request: request, requestType: .get, apiEndPoint: apiEndPoint, path: path, headers: headers, queryParams: queryParams)
    }
    
    func testGetRequestWithPlusSignInEmail() {
        let apiEndPoint = "https://somewhere.com/"
        let path = "path"
        let args = ["email": "user+1@somewhere.com"]
        let request = IterableRequestUtil.createGetRequest(forApiEndPoint: apiEndPoint, path: path, args: args)!
        let requestString = String(describing: request)
        XCTAssertEqual(requestString, "https://somewhere.com/path?email=user%2B1@somewhere.com")
    }
    
    func testPostRequest() {
        let apiEndPoint = "https://somewhere.com/"
        let path = "path"
        let headers = [
            "header1": "headerValue1",
            "header2": "headerValue2",
        ]
        let args = ["arg1": "value1", "arg2": "value2"]
        let body = ["var1": "val1", "var2": "val2"]
        let request = IterableRequestUtil.createPostRequest(forApiEndPoint: apiEndPoint, path: path, headers: headers, args: args, body: body)!
        
        let queryParams = [
            (name: "arg1", value: "value1"),
            (name: "arg2", value: "value2"),
        ]
        TestUtils.validate(request: request, requestType: .post, apiEndPoint: apiEndPoint, path: path, headers: headers, queryParams: queryParams)
        
        let bodyData = request.httpBody!
        
        let bodyFromRequest = try! JSONSerialization.jsonObject(with: bodyData, options: []) as! [AnyHashable: Any]
        
        TestUtils.validateElementPresent(withName: "var1", andValue: "val1", inDictionary: bodyFromRequest)
        TestUtils.validateElementPresent(withName: "var2", andValue: "val2", inDictionary: bodyFromRequest)
    }
}
