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
    
    static func validateMatch<T:Equatable>(keyPath: KeyPath, value: T, inDictionary dict: [String : Any]) {
        XCTAssertEqual(dict[keyPath: keyPath] as? T, value)
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

struct KeyPath {
    let segments: [String]
    
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
    
    init(segments: [String]) {
        self.segments = segments
    }
    
    var isEmpty : Bool {
        return segments.isEmpty
    }
    
    func firstAndRest() -> (String, KeyPath)? {
        guard !segments.isEmpty else { return nil }
        var rest = segments
        let first = rest.removeFirst()
        return (first, KeyPath(segments: rest))
    }
}

protocol StringKey {
    init(string: String)
}

extension String: StringKey {
    init(string: String) {
        self = string
    }
}

extension Dictionary where Key : StringKey {
    subscript(keyPath keyPath: KeyPath) -> Any? {
        get {
            switch keyPath.firstAndRest() {
            case nil:
                return nil
            case let (first, rest)? where rest.isEmpty:
                // nothing else left
                return self[Key(string: first)]
            case let (first, rest)?:
                let key = Key(string: first)
                if let value = self[key] as? [Key: Any] {
                    return value[keyPath: rest]
                } else {
                    return nil
                }
            }
        }
    }
}
