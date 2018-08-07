//
//
//  Created by Tapash Majumder on 7/25/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest
import Foundation

@testable import IterableSDK

struct TestUtils {
    enum RequestType {
        case get
        case post
    }
    
    static func validate(request: URLRequest, requestType: RequestType? = nil, apiEndPoint:String, path: String, queryParams: [(name: String, value:String)]? = nil) {
        if let requestType = requestType {
            XCTAssertEqual(requestType == .get ? ITBL_KEY_GET : ITBL_KEY_POST, request.httpMethod)
        }

        XCTAssertTrue(request.url!.absoluteString.hasPrefix(IterableRequestUtil.pathCombine(paths: [apiEndPoint, path])), "request: \(request.url!.absoluteString), apiEndPoint: \(apiEndPoint), path: \(path)")
        
        if let queryParams = queryParams {
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            validateQueryParameters(inUrlComponents: urlComponents, queryParams: queryParams)
        }
    }
    
    static func validateElementPresent<T:Equatable>(withName name: String, andValue value: T, inDictionary dict: [AnyHashable : Any]) {
        XCTAssertEqual(dict[name] as? T, value)
    }
    
    private static func validateQueryParameters(inUrlComponents urlComponents: URLComponents, queryParams: [(name:String, value:String)]) {
        queryParams.forEach { (name, value) in
            validateQueryParameter(inUrlComponents: urlComponents, withName: name, andValue: value)
        }
    }
    
    private static func validateQueryParameter(inUrlComponents urlComponents: URLComponents, withName name: String, andValue value: String) {
        let foundValue = findQueryItem(inUrlComponents: urlComponents, withName: name).value!
        XCTAssertEqual(foundValue, value)
    }
    
    private static func findQueryItem(inUrlComponents urlComponents: URLComponents, withName name: String) -> URLQueryItem {
        return urlComponents.queryItems!.first { (queryItem) -> Bool in
            queryItem.name == name
            }!
    }
}

