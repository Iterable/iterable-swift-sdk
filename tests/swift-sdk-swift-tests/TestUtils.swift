//
//  Created by Tapash Majumder on 7/25/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import XCTest

@testable import IterableSDK

struct TestUtils {
    enum RequestType {
        case get
        case post
    }
    
    static let appPackageName = Bundle.main.bundleIdentifier!
    static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    static let appBuild = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    
    static func validate(request: URLRequest, requestType: RequestType? = nil, apiEndPoint: String, path: String, headers: [String: String]? = nil, queryParams: [(name: String, value: String)]? = nil) {
        if let requestType = requestType {
            XCTAssertEqual(requestType == .get ? Const.Http.GET : Const.Http.POST, request.httpMethod)
        }
        
        XCTAssertTrue(request.url!.absoluteString.hasPrefix(IterableRequestUtil.pathCombine(paths: [apiEndPoint, path])), "request: \(request.url!.absoluteString), apiEndPoint: \(apiEndPoint), path: \(path)")
        
        if let queryParams = queryParams {
            let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            validateQueryParameters(inUrlComponents: urlComponents, queryParams: queryParams)
        }
        
        if let headers = headers {
            for header in headers {
                XCTAssertEqual(header.value, request.value(forHTTPHeaderField: header.key))
            }
        }
    }
    
    static func validateElementPresent<T: Equatable>(withName name: String, andValue value: T, inDictionary dict: [AnyHashable: Any]) {
        XCTAssertEqual(dict[name] as? T, value)
    }
    
    static func validateElementNotPresent(withName name: String, inDictionary dict: [AnyHashable: Any]) {
        XCTAssertNil(dict[name])
    }
    
    static func validateMatch<T: Equatable>(keyPath: KeyPath, value: T, inDictionary dict: [String: Any], message: String? = nil) {
        if let message = message {
            XCTAssertEqual(dict[keyPath: keyPath] as? T, value, message)
        } else {
            XCTAssertEqual(dict[keyPath: keyPath] as? T, value)
        }
    }
    
    static func validateNil(keyPath: KeyPath, inDictionary dict: [String: Any], message: String? = nil) {
        if let message = message {
            XCTAssertNil(dict[keyPath: keyPath], message)
        } else {
            XCTAssertNil(dict[keyPath: keyPath])
        }
    }
    
    static func validateExists<T: Equatable>(keyPath: KeyPath, type _: T.Type, inDictionary dict: [String: Any], message: String? = nil) {
        if let message = message {
            XCTAssertNotNil(dict[keyPath: keyPath] as? T, message)
        } else {
            XCTAssertNotNil(dict[keyPath: keyPath] as? T)
        }
    }
    
    static func validateHeader(_ request: URLRequest, _ apiKey: String) {
        guard let header = request.allHTTPHeaderFields else {
            XCTFail("no header for request")
            return
        }
        
        XCTAssertEqual(header[JsonKey.contentType.jsonKey], JsonValue.applicationJson.jsonStringValue)
        XCTAssertEqual(header[JsonKey.Header.sdkPlatform], JsonValue.iOS.jsonStringValue)
        XCTAssertEqual(header[JsonKey.Header.sdkVersion], IterableAPI.sdkVersion)
        XCTAssertEqual(header[JsonKey.Header.apiKey], apiKey)
    }
    
    static func validateEmailOrUserId(email: String? = nil, userId: String? = nil, inBody body: [String: Any]) {
        if let email = email {
            validateMatch(keyPath: KeyPath(JsonKey.email), value: email, inDictionary: body)
        }
        
        if let userId = userId {
            validateMatch(keyPath: KeyPath(JsonKey.userId), value: userId, inDictionary: body)
        }
    }
    
    static func validateMessageContext(messageId: String, email: String? = nil, userId: String? = nil, saveToInbox: Bool, silentInbox: Bool, location: InAppLocation?, inBody body: [String: Any]) {
        validateMatch(keyPath: KeyPath(JsonKey.messageId), value: messageId, inDictionary: body)
        
        validateEmailOrUserId(email: email, userId: userId, inBody: body)
        
        let contextKey = "\(JsonKey.inAppMessageContext.jsonKey)"
        validateMatch(keyPath: KeyPath("\(contextKey).\(JsonKey.saveToInbox.jsonKey)"), value: saveToInbox, inDictionary: body)
        validateMatch(keyPath: KeyPath("\(contextKey).\(JsonKey.silentInbox.jsonKey)"), value: silentInbox, inDictionary: body)
        if let location = location {
            validateMatch(keyPath: KeyPath("\(contextKey).\(JsonKey.inAppLocation.jsonKey)"), value: location.jsonValue as! String, inDictionary: body)
        } else {
            XCTAssertNil(body[keyPath: KeyPath("\(contextKey).\(JsonKey.inAppLocation.jsonKey)")])
        }
    }
    
    static func validateDeviceInfo(inBody body: [String: Any]) {
        validateMatch(keyPath: KeyPath(.deviceInfo, .deviceId), value: IterableAPIInternal.initializeForTesting().deviceId, inDictionary: body)
        validateMatch(keyPath: KeyPath(.deviceInfo, .platform), value: JsonValue.iOS.jsonStringValue, inDictionary: body)
        validateMatch(keyPath: KeyPath(.deviceInfo, .appPackageName), value: Bundle.main.appPackageName, inDictionary: body)
    }
    
    static func getTestUserDefaults() -> UserDefaults {
        TestHelper.getTestUserDefaults()
    }
    
    static func clearTestUserDefaults() {
        TestHelper.clearTestUserDefaults()
    }
    
    static func areEqual(dict1: [AnyHashable: Any], dict2: [AnyHashable: Any]) -> Bool {
        NSDictionary(dictionary: dict1).isEqual(to: dict2)
    }
    
    static func validateEqual(date1: Date?, date2: Date?) {
        if !areEqual(date1: date1, date2: date2) {
            XCTFail("date1: \(date1?.description ?? "nil") and date2: \(date2?.description ?? "nil") are not equal")
        }
    }
    
    static func areEqual(date1: Date?, date2: Date?) -> Bool {
        guard let date1 = date1 else {
            return date2 == nil
        }
        
        guard let date2 = date2 else {
            return false
        }
        
        return abs(date1.timeIntervalSinceReferenceDate - date2.timeIntervalSinceReferenceDate) < 0.001
    }
    
    private static func validateQueryParameters(inUrlComponents urlComponents: URLComponents, queryParams: [(name: String, value: String)]) {
        queryParams.forEach { name, value in
            validateQueryParameter(inUrlComponents: urlComponents, withName: name, andValue: value)
        }
    }
    
    private static func validateQueryParameter(inUrlComponents urlComponents: URLComponents, withName name: String, andValue value: String) {
        let foundValue = findQueryItem(inUrlComponents: urlComponents, withName: name).value!
        XCTAssertEqual(foundValue, value)
    }
    
    private static func findQueryItem(inUrlComponents urlComponents: URLComponents, withName name: String) -> URLQueryItem {
        urlComponents.queryItems!.first { (queryItem) -> Bool in
            queryItem.name == name
        }!
    }
}

struct KeyPath {
    let segments: [String]
    
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
    
    init(_ jsonKeys: JsonKey...) {
        segments = jsonKeys.map { $0.jsonKey }
    }
    
    init(segments: [String]) {
        self.segments = segments
    }
    
    var isEmpty: Bool {
        segments.isEmpty
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

extension JsonKey: StringKey {
    init(string: String) {
        self = JsonKey(rawValue: string)!
    }
}

extension Dictionary where Key: StringKey {
    subscript(keyPath keyPath: KeyPath) -> Any? {
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

public extension URLRequest {
    var bodyDict: [String: Any] {
        try! JSONSerialization.jsonObject(with: httpBody!, options: []) as! [String: Any]
    }
}
