//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

import UserNotifications
import UniformTypeIdentifiers

@testable import IterableAppExtensions

class NotificationExtensionTests: XCTestCase {
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
                ] as [String : Any]],
            ] as [String : Any],
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
    
    @available(iOS 14.0, *)
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
            XCTAssertEqual(firstAttachment.type, UTType.png.identifier)

            condition1.fulfill()
        }

        wait(for: [condition1], timeout: timeout)
    }
    
    @available(iOS 14.0, *)
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

            XCTAssertEqual(firstAttachment.type, UTType.mpeg4Movie.identifier)

            condition1.fulfill()
        }

        wait(for: [condition1], timeout: timeout)
    }
    
    func testPushIncorrectAttachment() {
        let content = UNMutableNotificationContent()
        content.userInfo = [
            "itbl": [
                "messageId": "12345",
                "attachment-url": "Invalid URL!"
            ]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        let expectation1 = expectation(description: "contentHandler is called")
        
        appExtension.didReceive(request) { contentToDeliver in
            XCTAssertEqual(contentToDeliver.attachments.count, 0)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: timeout)
    }

    func testPushDynamicCategory() {
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [
                    [
                        "identifier": "openAppButton",
                        "title": "Open App",
                        "buttonType": "default",
                        "openApp": true,
                        "action": []
                    ],
                    [
                        "identifier": "deepLinkButton",
                        "title": "Open DeepLink",
                        "buttonType": "default",
                        "openApp": true,
                        "action": [
                            "type": "openUrl",
                            "data": "http://maps.apple.com/?ll=37.7828,-122.3984"
                        ]
                    ],
                    [
                        "identifier": "silentActionButton",
                        "title": "Silent Action",
                        "buttonType": "default",
                        "openApp": false,
                        "action": [
                            "type": "customActionName",
                        ]
                    ] as [String : Any],
                    [
                        "identifier": "textInputButton",
                        "title": "Text Input",
                        "buttonType": "textInput",
                        "openApp": false,
                        "inputPlaceHolder": "Type your message here",
                        "inputTitle": "Send",
                        "action": [
                            "type": "handleTextInput",
                        ]
                    ],
                ]
            ] as [String : Any]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        let expectation1 = expectation(description: "contentHandler is called")
        
        appExtension.didReceive(request) { contentToDeliver in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                let center = UNUserNotificationCenter.current()
                center.getNotificationCategories { categories in
                    var createdCategory: UNNotificationCategory? = nil
                    for category in categories {
                        if category.identifier == messageId {
                            createdCategory = category
                        }
                    }
                    XCTAssertNotNil(createdCategory, "Category exists")
                    
                    let metadata = content.userInfo["itbl"] as! [AnyHashable: Any]
                    let buttonsJsonArray = metadata["actionButtons"] as! [[AnyHashable: Any]]
                    XCTAssertEqual(createdCategory!.actions.count, 4, "Number of buttons matches")
                    for i in 0..<4 {
                        let buttonPayload = buttonsJsonArray[i]
                        let actionButton = createdCategory!.actions[i]
                        XCTAssertEqual(actionButton.identifier, buttonPayload["identifier"] as! String, "Identifiers match")
                        XCTAssertEqual(actionButton.title, buttonPayload["title"] as! String, "Button titles match")
                    }
                    
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: timeout)
    }

    func testPushDestructiveSilentActionButton() {
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [
                    [
                        "identifier": "destructiveButton",
                        "title": "Unsubscribe",
                        "buttonType": "destructive",
                        "openApp": false,
                        "action": []
                    ] as [String : Any],
                ]
            ] as [String : Any]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        let expectation1 = expectation(description: "contentHandler is called")
        
        appExtension.didReceive(request) { contentToDeliver in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                let center = UNUserNotificationCenter.current()
                center.getNotificationCategories { categories in
                    var createdCategory: UNNotificationCategory? = nil
                    for category in categories {
                        if category.identifier == messageId {
                            createdCategory = category
                        }
                    }
                    XCTAssertNotNil(createdCategory, "Category exists")
                    
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matches")
                    XCTAssertTrue(createdCategory!.actions.first!.options.contains(.destructive), "Action is destructie")
                    XCTAssertFalse(createdCategory!.actions.first!.options.contains(.foreground), "Action is not foreground")
                    
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: timeout)
    }
    
    func testPushTextInputSilentButton() {
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [
                    [
                        "identifier": "textInputButton",
                        "title": "Text Input",
                        "buttonType": "textInput",
                        "openApp": false,
                        "action": []
                    ] as [String : Any],
                ]
            ] as [String : Any]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        let expectation1 = expectation(description: "contentHandler is called")
        
        appExtension.didReceive(request) { contentToDeliver in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                let center = UNUserNotificationCenter.current()
                center.getNotificationCategories { categories in
                    var createdCategory: UNNotificationCategory? = nil
                    for category in categories {
                        if category.identifier == messageId {
                            createdCategory = category
                        }
                    }
                    XCTAssertNotNil(createdCategory, "Category exists")
                    
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matches")
                    let textInputNotificationAction = createdCategory!.actions.first! as? UNTextInputNotificationAction
                    XCTAssertNotNil(textInputNotificationAction)
                    XCTAssertFalse(createdCategory!.actions.first!.options.contains(.foreground), "Action is not foreground")
                    
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: timeout)
    }
    
    func testPushTextInputForegroundButton() {
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [
                    [
                        "identifier": "textInputButton",
                        "title": "Text Input",
                        "buttonType": "textInput",
                        "openApp": true,
                        "action": []
                    ] as [String : Any],
                ]
            ] as [String : Any]
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        let expectation1 = expectation(description: "contentHandler is called")
        
        appExtension.didReceive(request) { contentToDeliver in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                let center = UNUserNotificationCenter.current()
                center.getNotificationCategories { categories in
                    var createdCategory: UNNotificationCategory? = nil
                    for category in categories {
                        if category.identifier == messageId {
                            createdCategory = category
                        }
                    }
                    XCTAssertNotNil(createdCategory, "Category exists")
                    
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matches")
                    let textInputNotificationAction = createdCategory!.actions.first! as? UNTextInputNotificationAction
                    XCTAssertNotNil(textInputNotificationAction)
                    XCTAssertTrue(createdCategory!.actions.first!.options.contains(.foreground), "Action is foreground")
                    
                    expectation1.fulfill()
                }
            }
        }

        wait(for: [expectation1], timeout: timeout)
    }

    @available(iOS 15.0, *)
    func testNilActionButtonIcon() {
        let expectation1 = expectation(description: #function)
        
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [[
                    "identifier": "openAppButton",
                    "title": "Open App",
                    "action": [
                        "type": "openUrl",
                        "data": "http://maps.apple.com/?ll=37.7828,-122.3984"
                    ],
                ] as [String : Any]],
            ] as [String : Any],
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        
        appExtension.didReceive(request) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { categories in
                    let createdCategory = categories.first(where: { $0.identifier == messageId })
                    
                    XCTAssertNotNil(createdCategory)
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matched")
                    let actionButton = createdCategory!.actions.first!
                    XCTAssertNil(actionButton.icon)
                    expectation1.fulfill()
                })
            }
        }
        
        wait(for: [expectation1], timeout: timeout)
    }

    
    @available(iOS 15.0, *)
    func testAddActionButtonWithSystemImageIcon() {
        let expectation1 = expectation(description: #function)
        
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [[
                    "identifier": "openAppButton",
                    "title": "Open App",
                    "action": [
                        "type": "openUrl",
                        "data": "http://maps.apple.com/?ll=37.7828,-122.3984"
                    ],
                    "actionIcon": [
                        "iconType": "systemImage",
                        "imageName": "hand.thumbsup",
                    ],
                ] as [String : Any]],
            ] as [String : Any],
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        
        appExtension.didReceive(request) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { categories in
                    let createdCategory = categories.first(where: { $0.identifier == messageId })
                    
                    XCTAssertNotNil(createdCategory)
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matched")
                    let actionButton = createdCategory!.actions.first!
                    XCTAssertNotNil(actionButton.icon)
                    expectation1.fulfill()
                })
            }
        }
        
        wait(for: [expectation1], timeout: timeout)
    }

    @available(iOS 15.0, *)
    func testAddActionButtonWithTemplateImageIcon() {
        let expectation1 = expectation(description: #function)
        
        let content = UNMutableNotificationContent()
        let messageId = UUID().uuidString
        
        content.userInfo = [
            "itbl": [
                "messageId": messageId,
                "actionButtons": [[
                    "identifier": "openAppButton",
                    "title": "Open App",
                    "action": [
                        "type": "openUrl",
                        "data": "http://maps.apple.com/?ll=37.7828,-122.3984"
                    ],
                    "actionIcon": [
                        "iconType": "templateImage",
                        "imageName": "custom.thumbsup",
                    ],
                ] as [String : Any]],
            ] as [String : Any],
        ]
        
        let request = UNNotificationRequest(identifier: "request", content: content, trigger: nil)
        
        appExtension.didReceive(request) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                UNUserNotificationCenter.current().getNotificationCategories(completionHandler: { categories in
                    let createdCategory = categories.first(where: { $0.identifier == messageId })
                    
                    XCTAssertNotNil(createdCategory)
                    XCTAssertEqual(createdCategory!.actions.count, 1, "Number of buttons matched")
                    let actionButton = createdCategory!.actions.first!
                    XCTAssertNotNil(actionButton.icon)
                    expectation1.fulfill()
                })
            }
        }
        
        wait(for: [expectation1], timeout: timeout)
    }
}
