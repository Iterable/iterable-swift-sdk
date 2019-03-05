//
//
//  Created by David Truong on 10/3/17.
//  Migrated to Swift by Tapash Majumder on 7/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppHelperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNotificationCreation() {
        //call showIterableNotificationHTML with fake data
        //Check the top level dialog
        
        let htmlString = "<a href=\"http://www.iterable.com\" target=\"http://www.iterable.com\">test</a>"
        let baseNotification = IterableInAppHTMLViewController(data: htmlString)
        let html = baseNotification.getHtml()
        XCTAssertEqual(html, htmlString)
    }
    
    func testGetPaddingInvalid() {
        let insets = HtmlContentCreator.getPadding(fromInAppSettings: [:])
        XCTAssertEqual(insets, UIEdgeInsets.zero)
    }
    
    func testGetPaddingFull() {
        let payload: [AnyHashable : Any] = [
            "top" : ["percentage" : "0"],
            "left" : ["percentage" : "0"],
            "bottom" : ["percentage" : "0"],
            "right" : ["right" : "0"],
        ]
        
        let insets = HtmlContentCreator.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(insets, UIEdgeInsets.zero)
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(HtmlContentCreator.decodePadding(payload["top"]))
        padding.left = CGFloat(HtmlContentCreator.decodePadding(payload["left"]))
        padding.bottom = CGFloat(HtmlContentCreator.decodePadding(payload["bottom"]))
        padding.right = CGFloat(HtmlContentCreator.decodePadding(payload["right"]))
        XCTAssertEqual(padding, UIEdgeInsets.zero)
    }
    
    func testGetPaddingCenter() {
        let payload: [AnyHashable : Any] = [
            "top" : ["displayOption" : "AutoExpand"],
            "left" : ["percentage" : "0"],
            "bottom" : ["displayOption" : "AutoExpand"],
            "right" : ["right" : "0"],
            ]
        
        let insets = HtmlContentCreator.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(insets, UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(HtmlContentCreator.decodePadding(payload["top"]))
        padding.left = CGFloat(HtmlContentCreator.decodePadding(payload["left"]))
        padding.bottom = CGFloat(HtmlContentCreator.decodePadding(payload["bottom"]))
        padding.right = CGFloat(HtmlContentCreator.decodePadding(payload["right"]))
        XCTAssertEqual(padding, UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0))
    }
    
    func testGetPaddingTop() {
        let payload: [AnyHashable : Any] = [
            "top" : ["percentage" : "0"],
            "left" : ["percentage" : "0"],
            "bottom" : ["displayOption" : "AutoExpand"],
            "right" : ["right" : "0"],
            ]
        
        let insets = HtmlContentCreator.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(insets, UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(HtmlContentCreator.decodePadding(payload["top"]))
        padding.left = CGFloat(HtmlContentCreator.decodePadding(payload["left"]))
        padding.bottom = CGFloat(HtmlContentCreator.decodePadding(payload["bottom"]))
        padding.right = CGFloat(HtmlContentCreator.decodePadding(payload["right"]))
        XCTAssertEqual(padding, UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0))
    }
    
    func testGetPaddingBottom() {
        let payload: [AnyHashable : Any] = [
            "top" : ["displayOption" : "AutoExpand"],
            "left" : ["percentage" : "0"],
            "bottom" : ["percentage" : "0"],
            "right" : ["right" : "0"],
            ]
        
        let insets = HtmlContentCreator.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(insets, UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(HtmlContentCreator.decodePadding(payload["top"]))
        padding.left = CGFloat(HtmlContentCreator.decodePadding(payload["left"]))
        padding.bottom = CGFloat(HtmlContentCreator.decodePadding(payload["bottom"]))
        padding.right = CGFloat(HtmlContentCreator.decodePadding(payload["right"]))
        XCTAssertEqual(padding, UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0))
    }
    
    func testNotificationPaddingFull() {
        let notificationType = IterableInAppHTMLViewController.location(fromPadding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        XCTAssertEqual(notificationType, .full)
    }

    func testNotificationPaddingTop() {
        let notificationType = IterableInAppHTMLViewController.location(fromPadding: UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0))
        XCTAssertEqual(notificationType, .top)
    }
    
    func testNotificationPaddingBottom() {
        let notificationType = IterableInAppHTMLViewController.location(fromPadding: UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0))
        XCTAssertEqual(notificationType, .bottom)
    }

    func testNotificationPaddingCenter() {
        let notificationType = IterableInAppHTMLViewController.location(fromPadding: UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0))
        XCTAssertEqual(notificationType, .center)
    }

    func testNotificationPaddingDefault() {
        let notificationType = IterableInAppHTMLViewController.location(fromPadding: UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0))
        XCTAssertEqual(notificationType, .center)
    }
    
    func testDoNotShowMultipleTimes() {
        let shownFirstTime = InAppDisplayer.showIterableHtmlMessage("", callbackBlock: nil)
        let shownSecondTime = InAppDisplayer.showIterableHtmlMessage("", callbackBlock: nil)
        XCTAssertTrue(shownFirstTime)
        XCTAssertFalse(shownSecondTime)
    }
    
    func testGetBackgroundAlpha() {
        XCTAssert(HtmlContentCreator.getBackgroundAlpha(fromInAppSettings: nil) == 0)
        XCTAssert(HtmlContentCreator.getBackgroundAlpha(fromInAppSettings: ["backgroundAlpha" : "x"]) == 0)
        XCTAssert(HtmlContentCreator.getBackgroundAlpha(fromInAppSettings: ["backgroundAlpha" : 0.5]) == 0.5)
        XCTAssert(HtmlContentCreator.getBackgroundAlpha(fromInAppSettings: ["backgroundAlpha" : 1]) == 1.0)
    }
    
    func testTrackInAppClickWithButtonUrl() {
        let messageId = "message1"
        let buttonUrl = "http://somewhere.com"
        let expectation1 = expectation(description: "track in app click")

        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: InAppHelperTests.apiKey, networkSession: networkSession)
        IterableAPI.userId = InAppHelperTests.userId
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: .ITBL_ENDPOINT_API,
                               path: .ITBL_PATH_TRACK_INAPP_CLICK,
                               queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: InAppHelperTests.apiKey),
                ])
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("urlClick"), value: buttonUrl, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("userId"), value: InAppHelperTests.userId, inDictionary: body)
            expectation1.fulfill()
        }
        IterableAPI.track(inAppClick: messageId, buttonURL: buttonUrl)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackInAppClickWithButtonIndex() {
        let messageId = "message1"
        let buttonIndex = "1"
        let expectation1 = expectation(description: "track in app click")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: InAppHelperTests.apiKey, networkSession: networkSession)
        IterableAPI.email = InAppHelperTests.email
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: .ITBL_ENDPOINT_API,
                               path: .ITBL_PATH_TRACK_INAPP_CLICK,
                               queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: InAppHelperTests.apiKey),
                                             ])
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath("messageId"), value: messageId, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("buttonIndex"), value: buttonIndex, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath("email"), value: InAppHelperTests.email, inDictionary: body)
            expectation1.fulfill()
        }
        IterableAPI.track(inAppClick: messageId, buttonIndex: buttonIndex)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackInAppOpen() {
        let messageId = "message1"
        let expectation1 = expectation(description: "track in app open")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: InAppHelperTests.apiKey, networkSession: networkSession)
        IterableAPI.email = InAppHelperTests.email
        networkSession.callback = {(_, _, _) in
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: .ITBL_ENDPOINT_API,
                               path: .ITBL_PATH_TRACK_INAPP_OPEN,
                               queryParams: [(name: AnyHashable.ITBL_KEY_API_KEY, value: InAppHelperTests.apiKey),
                                             ])
            let body = networkSession.getRequestBody() as! [String : Any]
            TestUtils.validateMatch(keyPath: KeyPath(AnyHashable.ITBL_KEY_MESSAGE_ID), value: messageId, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(AnyHashable.ITBL_KEY_EMAIL), value: InAppHelperTests.email, inDictionary: body)
            expectation1.fulfill()
        }
        IterableAPI.track(inAppOpen: messageId)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testCustomPayloadParsing() {
        IterableAPI.initializeForTesting()
        
        let customPayload: [AnyHashable : Any] = ["string1" : "value1", "bool1" : true, "date1" : Date()]
        
        let payload = createInAppPayload(withCustomPayload: customPayload)
        
        let messages = InAppHelper.inAppMessages(fromPayload: payload, internalApi: IterableAPI.internalImplementation!)
        
        XCTAssertEqual(messages.count, 1)
        let obtained = messages[0].customPayload
        XCTAssertEqual(obtained?["string1"] as? String, "value1")
        XCTAssertEqual(obtained?["bool1"] as? Bool, true)
    }
    
    func testInAppPayloadWithNoTrigger() {
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx"
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppHelper.inAppMessages(fromPayload: payload, internalApi: IterableAPI.internalImplementation!)
        XCTAssertEqual((messages[0] as! IterableInAppMessage).trigger.type, IterableInAppTriggerType.immediate)
    }
    
    func testInAppPayloadWithKnownTrigger() {
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "event",
                        "something" : "else"
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppHelper.inAppMessages(fromPayload: payload, internalApi: IterableAPI.internalImplementation!)
        XCTAssertEqual((messages[0] as! IterableInAppMessage).trigger.type, IterableInAppTriggerType.event)
        XCTAssertEqual((messages[0] as! IterableInAppMessage).trigger.dict["something"] as? String, "else")
    }

    func testInAppPayloadWithUnKnownTrigger() {
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppHelper.inAppMessages(fromPayload: payload, internalApi: IterableAPI.internalImplementation!)
        XCTAssertEqual((messages[0] as! IterableInAppMessage).trigger.type, IterableInAppTriggerType.never)
        let dict = (messages[0] as! IterableInAppMessage).trigger.dict as! [String : Any]
        TestUtils.validateMatch(keyPath: KeyPath("myPayload.var1"), value: "val1", inDictionary: dict, message: "Expected to find val1")
    }
    
    // Remove this test when backend is fixed
    // This test assumes that certain parts of payload
    // are in 'customPayload' element instead of the right places.
    func testInAppPayloadParsingWithPreprocessing() {
        let customPayloadStr1 = """
        {
            "messageId": "overridden",
            "var1" : "value1",
            "obj1" : {
                "something" : true,
                "nothing" : "is nothing"
            },
        }
        """
        var customPayload1 = customPayloadStr1.toJsonDict()
        customPayload1["inAppType"] = "default"
        customPayload1["contentType"] = "html"
        
        let customPayloadStr2 = """
        {
            "messageId": "overridden",
            "var1" : "value1",
            "obj1" : {
                "something" : true,
                "nothing" : "is nothing"
            },
        }
        """
        var customPayload2 = customPayloadStr2.toJsonDict()
        customPayload2["inAppType"] = "inbox"
        customPayload2["contentType"] = "inboxHtml"
        customPayload2["title"] = "title"
        customPayload2["subTitle"] = "subTitle"
        customPayload2["icon"] = "icon"
        
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId1",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : \(customPayload1.toJsonString())
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId2",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : \(customPayload2.toJsonString())
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId3",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : {}
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId4",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppHelper.inAppMessages(fromPayload: payload, internalApi: IterableAPI.internalImplementation!)
        
        XCTAssertEqual(messages.count, 4)
        let message1 = messages[0]
        XCTAssertEqual(message1.messageId, "messageId1")
        XCTAssertEqual(message1.inAppType, .default)
        XCTAssertTrue(TestUtils.areEqual(dict1: message1.customPayload!, dict2: customPayloadStr1.toJsonDict()))
        
        let message2 = messages[1]
        XCTAssertEqual(message2.messageId, "messageId2")
        XCTAssertEqual(message2.inAppType, .inbox)
        XCTAssertTrue(TestUtils.areEqual(dict1: message2.customPayload!, dict2: customPayloadStr2.toJsonDict()))
        
        let message3 = messages[2]
        XCTAssertEqual(message3.inAppType, .default)
        
        let message4 = messages[3]
        XCTAssertEqual(message4.inAppType, .default)
    }

    
    func testInAppPayloadParsing() {
        let customPayloadStr1 = """
        {
            "var1" : "value1",
            "obj1" : {
                "something" : true,
                "nothing" : "is nothing"
            }
        }
        """
        let customPayloadStr2 = """
        {
            "obj2" : {
                "var1" : "value2",
                "var2" : "value2",
                "var3" : "value3"
            }
        }
        """

        let inboxTitle = "this is the title"
        let inboxSubTitle = "this is the subtitle"
        let inboxIcon = "https://somewhere.com/icon.jpg"
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "contentType" : "html",
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx",
                    "inAppType" : "default",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : \(customPayloadStr1)
                },
                {
                    "inAppType" : "inbox",
                    "content" : {
                        "contentType" : "inboxHtml",
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>",
                        "title" : "\(inboxTitle)",
                        "subTitle" : "\(inboxSubTitle)",
                        "icon" : "\(inboxIcon)",
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : \(customPayloadStr2)
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : {}
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageIdxxx",
                    "campaignId" : "campaignIdxxx",
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppHelper.inAppMessages(fromPayload: payload, internalApi: IterableAPI.internalImplementation!)
        
        XCTAssertEqual(messages.count, 4)
        let message1 = messages[0]
        XCTAssertEqual(message1.inAppType, .default)
        XCTAssertTrue(TestUtils.areEqual(dict1: message1.customPayload!, dict2: customPayloadStr1.toJsonDict()))
        
        let message2 = messages[1] as! IterableInboxMessage
        XCTAssertEqual(message2.inAppType, .inbox)
        let content = message2.content as! IterableInboxHtmlContent
        XCTAssertEqual(content.title, inboxTitle)
        XCTAssertEqual(content.subTitle, inboxSubTitle)
        XCTAssertEqual(content.icon, inboxIcon)
        XCTAssertTrue(TestUtils.areEqual(dict1: message2.customPayload!, dict2: customPayloadStr2.toJsonDict()))
        
        let message3 = messages[2]
        XCTAssertEqual(message3.inAppType, .default)

        let message4 = messages[3]
        XCTAssertEqual(message4.inAppType, .default)
    }

    private func createInAppPayload(withCustomPayload customPayload: [AnyHashable : Any]) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : [[
                "content" : [
                    "html" : "<a href='href1'>Click Here</a>",
                    "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]],
                ],
                "messageId" : "messageIdxxx",
                "campaignId" : "campaignIdxxx",
                "customPayload" : customPayload
            ]]
        ]
    }
    
    // nil host
    func testCallbackUrlParsingCustomScheme1() {
        let url = URL(string: "applewebdata://")!
        XCTAssertNil(InAppHelper.getCallbackAndDestinationUrl(url: url))
    }

    
    func testCallbackUrlParsingCustomScheme2() {
        let url = URL(string: "applewebdata://this-is-uuid/the-real-url")!
        let (callbackUrl, destinationUrl) = InAppHelper.getCallbackAndDestinationUrl(url: url)!
        XCTAssertEqual(callbackUrl, "the-real-url")
        XCTAssertEqual(destinationUrl, "the-real-url")
    }

    func testCallbackUrlParsingIterableScheme() {
        let url = URL(string: "itbl://buyProduct")!
        let (callbackUrl, destinationUrl) = InAppHelper.getCallbackAndDestinationUrl(url: url)!
        XCTAssertEqual(callbackUrl, "buyProduct")
        XCTAssertEqual(destinationUrl, "itbl://buyProduct")
    }

    func testCallbackUrlParsingRegularScheme() {
        let url = URL(string: "https://host/path")!
        let (callbackUrl, destinationUrl) = InAppHelper.getCallbackAndDestinationUrl(url: url)!
        XCTAssertEqual(callbackUrl, "https://host/path")
        XCTAssertEqual(destinationUrl, "https://host/path")
    }

    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let userId = "userId1"
}
