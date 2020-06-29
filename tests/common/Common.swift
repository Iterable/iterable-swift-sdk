//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

struct TestConsts {
    static let userDefaultsSuiteName = "testUserDefaults"
}

/// Add Utility methods common to multiple targets here.
/// We can't use TestUtils in all tests because TestUtils targets Swift tests only.
struct TestHelper {
    static func getTestUserDefaults() -> UserDefaults {
        UserDefaults(suiteName: TestConsts.userDefaultsSuiteName)!
    }
    
    static func clearTestUserDefaults() {
        getTestUserDefaults().removePersistentDomain(forName: TestConsts.userDefaultsSuiteName)
    }
    
    static func generateIntGuid() -> Int {
        var numbers = [Int]()
        16.times {
            numbers.append(generateRandomInt(max: 10))
        }
        
        let stringGuid = numbers.map(String.init).reduce(into: "") { result, value in
            result.append(value)
        }
        
        return Int(stringGuid)!
    }
    
    private static func generateRandomInt(max: Int) -> Int {
        Int(arc4random_uniform(UInt32(max)))
    }
}

struct InAppTestHelper {
    static func inAppMessages(fromPayload payload: [AnyHashable: Any]) -> [IterableInAppMessage] {
        InAppMessageParser.parse(payload: payload).compactMap(parseResultToOptionalMessage)
    }
    
    private static func parseResultToOptionalMessage(result: Result<IterableInAppMessage, InAppMessageParser.ParseError>) -> IterableInAppMessage? {
        switch result {
        case .failure:
            return nil
        case let .success(message):
            return message
        }
    }
}

struct SerializableRequest: Codable {
    let method: String
    let host: String
    let path: String
    let queryParameters: [String: String]?
    let headers: [String: String]?
    let bodyString: String? // because we can't serialize dictionary with value of type 'Any'
    
    var serializedString: String {
        let encodedData = try! JSONEncoder().encode(self)
        return String(bytes: encodedData, encoding: .utf8)!
    }
    
    var body: [AnyHashable: Any]? {
        guard let bodyString = bodyString else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: bodyString.data(using: .utf8)!, options: []) as? [AnyHashable: Any]
    }
    
    static func create(from string: String) -> SerializableRequest {
        try! JSONDecoder().decode(SerializableRequest.self, from: string.data(using: .utf8)!)
    }
}

extension SerializableRequest: CustomStringConvertible {
    var description: String {
        """
        method: \(method),
        host: \(host),
        path: \(path),
        headers: \(headers?.description ?? "nil"),
        queryParameters: \(queryParameters?.description ?? "nil"),
        body: \(body?.description ?? "nil")
        """
    }
}
