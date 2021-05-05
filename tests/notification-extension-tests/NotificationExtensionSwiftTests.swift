//
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
        let condition1 = expectation(description: "contentHandler is called")
        
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
        
        appExtension.didReceive(request) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { categories in
                    let createdCategory = categories.first(where: { $0.identifier == messageId })
                    
                    XCTAssertNotNil(createdCategory)
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matched")
                    XCTAssertTrue(createdCategory!.actions.first!.options.contains(.foreground), "Action is foreground")
                    
                    condition1.fulfill()
                })
            }
        }
        
        wait(for: [condition1], timeout: timeout)
    }
    
    func testPushImageAttachment() {
        let condition1 = expectation(description: "image attachment didn't function as expected")
        
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "attachment-url": "https://github.com/Iterable/swift-sdk/raw/master/images/Iterable-Logo.png"
            ]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        
        appExtension.didReceive(request) { content in
            XCTAssertEqual(content.attachments.count, 1)
            
            guard let firstAttachment = content.attachments.first else {
                XCTFail("attachment doesn't exist")
                return
            }
            
            XCTAssertNotNil(firstAttachment.url)
            XCTAssertEqual(firstAttachment.url.scheme, "file")
            
            // at some point, fix this to use proper typing through the UniformTypeIdentifiers framework
            XCTAssertEqual(firstAttachment.type, "public.png")
            
            condition1.fulfill()
        }
        
        wait(for: [condition1], timeout: timeout)
    }
    
    func testPushVideoAttachment() {
        let condition1 = expectation(description: "video attachment didn't function as expected")
        
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "attachment-url": "https://github.com/Iterable/swift-sdk/raw/master/tests/notification-extension-tests/swirl.mp4"
            ]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        
        appExtension.didReceive(request) { content in
            guard let firstAttachment = content.attachments.first else {
                XCTFail("attachment doesn't exist")
                return
            }
            
            XCTAssertNotNil(firstAttachment.url)
            XCTAssertEqual(firstAttachment.url.scheme, "file")
            
            // at some point, fix this to use proper typing through the UniformTypeIdentifiers framework
            XCTAssertEqual(firstAttachment.type, "public.mpeg-4")
            
            condition1.fulfill()
        }
        
        wait(for: [condition1], timeout: timeout)
    }
}
