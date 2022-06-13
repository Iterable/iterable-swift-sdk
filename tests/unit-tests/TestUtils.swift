//
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
    
    static func validateHeader(_ request: URLRequest, _ apiKey: String, processorType: IterableAPICallRequest.ProcessorType = .online) {
        guard let header = request.allHTTPHeaderFields else {
            XCTFail("no header for request")
            return
        }
        
        XCTAssertEqual(header[JsonKey.contentType], JsonValue.applicationJson)
        XCTAssertEqual(header[JsonKey.Header.sdkPlatform], JsonValue.iOS)
        XCTAssertEqual(header[JsonKey.Header.sdkVersion], IterableAPI.sdkVersion)
        XCTAssertEqual(header[JsonKey.Header.apiKey], apiKey)
        XCTAssertEqual(header[JsonKey.Header.requestProcessor], processorType == .online ? "Online" : "Offline")
    }
    
    static func validateEmailOrUserId(email: String? = nil, userId: String? = nil, inBody body: [String: Any]) {
        if let email = email {
            validateMatch(keyPath: KeyPath(keys: JsonKey.email), value: email, inDictionary: body)
        }
        
        if let userId = userId {
            validateMatch(keyPath: KeyPath(keys: JsonKey.userId), value: userId, inDictionary: body)
        }
    }
    
    static func validateMessageContext(messageId: String, email: String? = nil, userId: String? = nil, saveToInbox: Bool, silentInbox: Bool, location: InAppLocation?, inBody body: [String: Any]) {
        validateMatch(keyPath: KeyPath(keys: JsonKey.messageId), value: messageId, inDictionary: body)
        
        validateEmailOrUserId(email: email, userId: userId, inBody: body)
        
        let contextKey = "\(JsonKey.inAppMessageContext)"
        validateMatch(keyPath: KeyPath(string: "\(contextKey).\(JsonKey.saveToInbox)"), value: saveToInbox, inDictionary: body)
        validateMatch(keyPath: KeyPath(string: "\(contextKey).\(JsonKey.silentInbox)"), value: silentInbox, inDictionary: body)
        if let location = location {
            validateMatch(keyPath: KeyPath(string: "\(contextKey).\(JsonKey.inAppLocation)"), value: location.jsonValue as! String, inDictionary: body)
        } else {
            XCTAssertNil(body[keyPath: KeyPath(string: "\(contextKey).\(JsonKey.inAppLocation)")])
        }
    }
    
    static func validateDeviceInfo(inBody body: [String: Any], withDeviceId deviceId: String) {
        validateMatch(keyPath: KeyPath(keys: JsonKey.deviceInfo, JsonKey.deviceId), value: deviceId, inDictionary: body)
        validateMatch(keyPath: KeyPath(keys: JsonKey.deviceInfo, JsonKey.platform), value: JsonValue.iOS, inDictionary: body)
        validateMatch(keyPath: KeyPath(keys: JsonKey.deviceInfo, JsonKey.appPackageName), value: Bundle.main.appPackageName, inDictionary: body)
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
    
    static func areEqual(color1: UIColor?, color2: UIColor?, accuracy: Double = 0.001) -> Bool {
        guard let color1 = color1 else {
            return color2 == nil
        }
        guard let color2 = color2 else {
            return false
        }
        
        let (r1, g1, b1, a1) = color1.rgba
        let (r2, g2, b2, a2) = color2.rgba
        
        return
            abs(Double(r1) - Double(r2)) < accuracy
            &&
            abs(Double(g1) - Double(g2)) < accuracy
            &&
            abs(Double(b1) - Double(b2)) < accuracy
            &&
            abs(Double(a1) - Double(a2)) < accuracy
    }
    
    static func getRequestBody(request: URLRequest) -> [String: Any]? {
        guard let body = request.httpBody else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: body, options: []) as? [String: Any]
    }
    
    static func matchingRequest(networkSession: MockNetworkSession, response: URLResponse?, endPoint: String) -> (request: URLRequest, body: [String: Any])? {
        guard response?.url?.absoluteString.contains(endPoint) == true else {
            return nil
        }
        guard let request = networkSession.getRequest(withEndPoint: endPoint) else {
            return nil
        }
        guard let body = TestUtils.getRequestBody(request: request) else {
            return nil
        }

        return (request: request, body: body)
    }
    
    static func tryUntil(attempts: Int,
                         closure: (() -> Void)? = nil,
                         test: () -> Bool) -> Bool {
        ITBInfo("attempt: \(attempts)")
        if attempts == 0 {
            return false
        }
        
        closure?()
        
        if test() {
            return true
        } else {
            Thread.sleep(forTimeInterval: 1.0)
            return tryUntil(attempts: attempts-1, closure: closure, test: test)
        }
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
    
    init(string: String) {
        segments = string.components(separatedBy: ".")
    }

    init(keys: String...) {
        segments = keys.map { $0 }
    }

    private init(segments: [String]) {
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

extension Dictionary where Key == String {
    subscript(keyPath keyPath: KeyPath) -> Any? {
        switch keyPath.firstAndRest() {
        case nil:
            return nil
        case let (first, rest)? where rest.isEmpty:
            // nothing else left
            return self[first]
        case let (first, rest)?:
            if let value = self[first] as? [Key: Any] {
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
