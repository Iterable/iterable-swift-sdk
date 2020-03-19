//
//  Created by Tapash Majumder on 10/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

import UserNotifications

@testable import IterableAppExtensions

class NotificationExtensionSwiftTests: XCTestCase {
    private var appExtension: ITBNotificationServiceExtension!
    private let delay = 0.05
    private let timeout = 15.0
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        UNUserNotificationCenter.current().setNotificationCategories([])
        appExtension = ITBNotificationServiceExtension()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        appExtension = nil
        super.tearDown()
    }
    
    func testPushButtonWithNoType() {
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [[
                    "identifier": "openAppButton",
                    "title": "Open App",
                    "action": [:],
                ]],
            ],
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        let expectation1 = expectation(description: "contentHandler is called")
        
        appExtension.didReceive(request) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { categories in
                    let createdCategory = categories.first(where: { $0.identifier == messageId })
                    XCTAssertNotNil(createdCategory)
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matched")
                    XCTAssertTrue(createdCategory!.actions.first!.options.contains(.foreground), "Action is foreground")
                    expectation1.fulfill()
                })
            }
        }
        
        wait(for: [expectation1], timeout: timeout)
    }
}
