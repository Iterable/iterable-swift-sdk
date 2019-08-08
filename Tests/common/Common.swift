//
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
        return UserDefaults(suiteName: TestConsts.userDefaultsSuiteName)!
    }
    
    static func clearTestUserDefaults() {
        getTestUserDefaults().removePersistentDomain(forName: TestConsts.userDefaultsSuiteName)
    }
}

struct InAppTestHelper {
    static func inAppMessages(fromPayload payload: [AnyHashable: Any]) -> [IterableInAppMessage] {
        return InAppMessageParser.parse(payload: payload).compactMap(parseResultToOptionalMessage)
    }
    
    private static func parseResultToOptionalMessage(result: IterableResult<IterableInAppMessage, InAppMessageParser.ParseError>) -> IterableInAppMessage? {
        switch result {
        case .failure:
            return nil
        case let .success(message):
            return message
        }
    }
}
