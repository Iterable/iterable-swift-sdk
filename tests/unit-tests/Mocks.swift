//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications
import XCTest

@testable import IterableSDK

// Note: This is used only by swift tests. So can't put this in Common
class MockNotificationStateProvider: NotificationStateProviderProtocol {
    var enabled: Bool
    private let expectation: XCTestExpectation?
    
    init(enabled: Bool, expectation: XCTestExpectation? = nil) {
        self.enabled = enabled
        self.expectation = expectation
    }
    
    func isNotificationsEnabled(withCallback callback: @escaping (Bool) -> Void) {
        callback(enabled)
    }
    
    func registerForRemoteNotifications() {
        expectation?.fulfill()
    }
}
