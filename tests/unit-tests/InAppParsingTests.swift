//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppParsingTests: XCTestCase {
    override class func setUp() {
        super.setUp()
    }
    
    func testGetPaddingInvalid() {
        let padding = HtmlContentParser.getPadding(fromInAppSettings: [:])
        XCTAssertEqual(padding, Padding.zero)
    }
    
    func testGetPaddingFull() {
        let payload: [AnyHashable: Any] = [
            "top": ["percentage": "0"],
            "left": ["percentage": "0"],
            "bottom": ["percentage": "0"],
            "right": ["right": "0"],
        ]
        
        let padding = HtmlContentParser.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(padding, Padding.zero)
        
        let top = PaddingParser.decodePaddingValue(payload["top"])
        let left = PaddingParser.decodePadding(payload["left"])
        let bottom = PaddingParser.decodePaddingValue(payload["bottom"])
        let right = PaddingParser.decodePadding(payload["right"])
        XCTAssertEqual(Padding(top: top,
                               left: left,
                               bottom: bottom,
                               right: right), Padding.zero)
    }
    
    func testGetPaddingCenter() {
        let payload: [AnyHashable: Any] = [
            "top": ["displayOption": "AutoExpand"],
            "left": ["percentage": "0"],
            "bottom": ["displayOption": "AutoExpand"],
            "right": ["right": "0"],
        ]
        let expected = Padding(top: .autoExpand,
                               left: 0,
                               bottom: .autoExpand,
                               right: 0)

        let padding = HtmlContentParser.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(padding, expected)

        let top = PaddingParser.decodePaddingValue(payload["top"])
        let left = PaddingParser.decodePadding(payload["left"])
        let bottom = PaddingParser.decodePaddingValue(payload["bottom"])
        let right = PaddingParser.decodePadding(payload["right"])
        XCTAssertEqual(Padding(top: top,
                               left: left,
                               bottom: bottom,
                               right: right), expected)
    }
    
    func testGetPaddingTop() {
        let payload: [AnyHashable: Any] = [
            "top": ["percentage": "0"],
            "left": ["percentage": "0"],
            "bottom": ["displayOption": "AutoExpand"],
            "right": ["right": "0"],
        ]
        let expected = Padding(top: .percent(value: 0),
                               left: 0,
                               bottom: .autoExpand,
                               right: 0)
        
        let padding = HtmlContentParser.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(padding, expected)

        let top = PaddingParser.decodePaddingValue(payload["top"])
        let left = PaddingParser.decodePadding(payload["left"])
        let bottom = PaddingParser.decodePaddingValue(payload["bottom"])
        let right = PaddingParser.decodePadding(payload["right"])
        XCTAssertEqual(Padding(top: top,
                               left: left,
                               bottom: bottom,
                               right: right), expected)
    }
    
    func testGetPaddingBottom() {
        let payload: [AnyHashable: Any] = [
            "top": ["displayOption": "AutoExpand"],
            "left": ["percentage": "0"],
            "bottom": ["percentage": "0"],
            "right": ["right": "0"],
        ]
        let expected = Padding(top: .autoExpand,
                               left: 0,
                               bottom: .percent(value: 0),
                               right: 0)
        
        let padding = HtmlContentParser.getPadding(fromInAppSettings: payload)
        XCTAssertEqual(padding, expected)

        let top = PaddingParser.decodePaddingValue(payload["top"])
        let left = PaddingParser.decodePadding(payload["left"])
        let bottom = PaddingParser.decodePaddingValue(payload["bottom"])
        let right = PaddingParser.decodePadding(payload["right"])
        XCTAssertEqual(Padding(top: top,
                               left: left,
                               bottom: bottom,
                               right: right), expected)
    }

    func testParseShouldAnimate1() {
        let inAppSettings = [
            "something": "nothing"
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, false)
    }

    func testParseShouldAnimate2() {
        let inAppSettings = [
            "shouldAnimate": true
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, true)
    }

    func testParseShouldAnimate3() {
        let inAppSettings = [
            "shouldAnimate": 1
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, true)
    }

    func testParseShouldAnimate4() {
        let inAppSettings = [
            "shouldAnimate": "1"
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, true)
    }

    func testParseShouldAnimate5() {
        let inAppSettings = [
            "shouldAnimate": false
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, false)
    }

    func testParseShouldAnimate6() {
        let inAppSettings = [
            "shouldAnimate": 0
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, false)
    }

    func testParseShouldAnimate7() {
        let inAppSettings = [
            "shouldAnimate": "0"
        ]
        let shouldAnimate = HtmlContentParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
        XCTAssertEqual(shouldAnimate, false)
    }

    func testBackgroundColor1() {
        let inAppSettings = [
            "something": "nothing"
        ]
        
        let color = HtmlContentParser.parseBackgroundColor(fromInAppSettings: inAppSettings)
        XCTAssertNil(color)
    }

    func testBackgroundColor2() {
        let inAppSettings = [
            "bgColor": [
                "hexXXX": "007788",
                "alpha": 0.5] as [String : Any],
        ]
        
        let color = HtmlContentParser.parseBackgroundColor(fromInAppSettings: inAppSettings)
        XCTAssertNil(color)
    }

    func testBackgroundColor3() {
        let inAppSettings = [
            "bgColor": [
                "hex": "xyz",
                "alpha": 0.5] as [String : Any],
        ]
        
        let color = HtmlContentParser.parseBackgroundColor(fromInAppSettings: inAppSettings)
        XCTAssertNil(color)
    }

    func testBackgroundColor4() {
        let inAppSettings = [
            "bgColor": [
                "hex": "007788",
                "alpha": 0.4] as [String : Any],
        ]
        
        let color = HtmlContentParser.parseBackgroundColor(fromInAppSettings: inAppSettings)!

        XCTAssertTrue(TestUtils.areEqual(color1: color, color2: UIColor(red: 0,
                                                                        green: CGFloat(Int("77", radix: 16)!) / 255,
                                                                        blue: CGFloat(Int("88", radix: 16)!) / 255,
                                                                        alpha: 0.4)))
    }

    func testBackgroundColor5() {
        let inAppSettings = [
            "bgColor": [
                "hex": "007788",
                "alphaXXX": 0.4] as [String : Any],
        ]
        
        let color = HtmlContentParser.parseBackgroundColor(fromInAppSettings: inAppSettings)!

        XCTAssertTrue(TestUtils.areEqual(color1: color, color2: UIColor(red: 0,
                                                                        green: CGFloat(Int("77", radix: 16)!) / 255,
                                                                        blue: CGFloat(Int("88", radix: 16)!) / 255,
                                                                        alpha: 0.0)))
    }

    func testBackgroundColor6() {
        let inAppSettings = [
            "bgColor": [
                "hex": "#007788",
                "alpha": 0.4] as [String : Any],
        ]
        
        let color = HtmlContentParser.parseBackgroundColor(fromInAppSettings: inAppSettings)!

        XCTAssertTrue(TestUtils.areEqual(color1: color, color2: UIColor(red: 0,
                                                                        green: CGFloat(Int("77", radix: 16)!) / 255,
                                                                        blue: CGFloat(Int("88", radix: 16)!) / 255,
                                                                        alpha: 0.4)))
    }

    func testNotificationPaddingFull() {
        let padding = Padding(top: .percent(value: 0),
                              left: 0,
                              bottom: .percent(value: 0),
                              right: 0)
        let notificationType = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        XCTAssertEqual(notificationType, .full)
    }
    
    func testNotificationPaddingTop() {
        let padding = Padding(top: .percent(value: 0),
                              left: 0,
                              bottom: .autoExpand,
                              right: 0)
        let notificationType = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        XCTAssertEqual(notificationType, .top)
    }
    
    func testNotificationPaddingBottom() {
        let padding = Padding(top: .autoExpand,
                              left: 0,
                              bottom: .percent(value: 0),
                              right: 0)
        let notificationType = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        XCTAssertEqual(notificationType, .bottom)
    }
    
    func testNotificationPaddingCenter() {
        let padding = Padding(top: .autoExpand,
                              left: 0,
                              bottom: .autoExpand,
                              right: 0)
        let notificationType = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        XCTAssertEqual(notificationType, .center)
    }
    
    func testNotificationPaddingDefault() {
        let padding = Padding(top: .percent(value: 10),
                              left: 0,
                              bottom: .percent(value: 20),
                              right: 0)
        let notificationType = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        XCTAssertEqual(notificationType, .center)
    }
    
    func testDoNotShowMultipleTimes() {
        let expectation1 = expectation(description: "error on second time")
        InAppDisplayer.showIterableHtmlMessage("", onClickCallback: nil)
        if case .notShown = InAppDisplayer.showIterableHtmlMessage("", onClickCallback: nil) {
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppClickWithClickedUrl() {
        let message = IterableInAppMessage(messageId: "message1",
                                           campaignId: 1,
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "immediate"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                           saveToInbox: false,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        let buttonUrl = "http://somewhere.com"
        let expectation1 = expectation(description: "track in app click")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: InAppParsingTests.apiKey, networkSession: networkSession)
        internalAPI.userId = InAppParsingTests.userId
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppClick) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppClick,
                               queryParams: [])
            TestUtils.validateMessageContext(messageId: message.messageId, userId: InAppParsingTests.userId, saveToInbox: false, silentInbox: false, location: .inApp, inBody: body)
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            TestUtils.validateMatch(keyPath: KeyPath(string: "clickedUrl"), value: buttonUrl, inDictionary: body)
            expectation1.fulfill()
        }
        internalAPI.trackInAppClick(message, clickedUrl: buttonUrl)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppOpen() {
        let message = IterableInAppMessage(messageId: "message1",
                                           campaignId: 1,
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                           saveToInbox: true,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        let expectation1 = expectation(description: "track in app open")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: InAppParsingTests.apiKey, networkSession: networkSession)
        internalAPI.email = InAppParsingTests.email
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppOpen) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppOpen,
                               queryParams: [])
            TestUtils.validateMessageContext(messageId: message.messageId, email: InAppParsingTests.email, saveToInbox: true, silentInbox: true, location: .inbox, inBody: body)
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            expectation1.fulfill()
        }
        internalAPI.trackInAppOpen(message, location: .inbox)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppClose() {
        let messageId = "message1"
        let expectation1 = expectation(description: "track inAppClose event")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: InAppParsingTests.apiKey, networkSession: networkSession)
        internalAPI.email = InAppParsingTests.email
        
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppClose) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppClose,
                               queryParams: [])
            
            TestUtils.validateMessageContext(messageId: messageId, email: InAppParsingTests.email, saveToInbox: true, silentInbox: true, location: .inbox, inBody: body)
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            TestUtils.validateMatch(keyPath: KeyPath(string: "\(JsonKey.closeAction)"), value: "back", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(string: "\(JsonKey.clickedUrl)"), value: "https://somewhere.com", inDictionary: body)
            
            expectation1.fulfill()
        }
        
        let message = IterableInAppMessage(messageId: messageId,
                                           campaignId: 1,
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                           saveToInbox: true,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        
        internalAPI.trackInAppClose(message, location: .inbox, source: .back, clickedUrl: "https://somewhere.com")
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppCloseWithNoSource() {
        let messageId = "message1"
        let expectation1 = expectation(description: "track inAppClose event")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: InAppParsingTests.apiKey, networkSession: networkSession)
        internalAPI.email = InAppParsingTests.email
        
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppClose) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppClose,
                               queryParams: [])
            
            TestUtils.validateMessageContext(messageId: messageId, email: InAppParsingTests.email, saveToInbox: true, silentInbox: true, location: .inbox, inBody: body)
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            XCTAssertNil(body[keyPath: KeyPath(string: "\(JsonKey.closeAction)")])
            TestUtils.validateMatch(keyPath: KeyPath(string: "\(JsonKey.clickedUrl)"), value: "https://somewhere.com", inDictionary: body)
            
            expectation1.fulfill()
        }
        
        let message = IterableInAppMessage(messageId: messageId,
                                           campaignId: 1,
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                           saveToInbox: true,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        
        internalAPI.trackInAppClose(message, location: .inbox, clickedUrl: "https://somewhere.com")
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppDelivery() {
        let messageId = "message1"
        let expectation1 = expectation(description: "track inAppDelivery event")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: InAppParsingTests.apiKey, networkSession: networkSession)
        internalAPI.email = InAppParsingTests.email
        
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppDelivery) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppDelivery,
                               queryParams: [])
            
            TestUtils.validateMessageContext(messageId: messageId, email: InAppParsingTests.email, saveToInbox: true, silentInbox: true, location: nil, inBody: body)
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            expectation1.fulfill()
        }
        
        let message = IterableInAppMessage(messageId: messageId,
                                           campaignId: 1,
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                           saveToInbox: true,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        
        internalAPI.track(inAppDelivery: message)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testCustomPayloadParsing() {
        let customPayload: [AnyHashable: Any] = ["string1": "value1", "bool1": true, "date1": Date()]
        
        let payload = createInAppPayload(withCustomPayload: customPayload)
        
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        
        XCTAssertEqual(messages.count, 1)
        let obtained = messages[0].customPayload
        XCTAssertEqual(obtained?["string1"] as? String, "value1")
        XCTAssertEqual(obtained?["bool1"] as? Bool, true)
    }
    
    func testInAppPayloadWithNoTrigger() {
        let id = TestHelper.generateIntGuid()
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId-\(id)",
                    "campaignId" : \(id)
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        XCTAssertEqual(messages[0].trigger.type, IterableInAppTriggerType.immediate)
    }
    
    func testInAppPayloadWithKnownTrigger() {
        let id = TestHelper.generateIntGuid()
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId-\(id)",
                    "campaignId" : \(id),
                    "trigger" : {
                        "type" : "event",
                        "something" : "else"
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        XCTAssertEqual(messages[0].trigger.type, IterableInAppTriggerType.event)
        XCTAssertEqual(messages[0].trigger.dict["something"] as? String, "else")
    }
    
    func testInAppPayloadWithUnKnownTrigger() {
        let id = TestHelper.generateIntGuid()
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId-\(id)",
                    "campaignId" : \(id),
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        XCTAssertEqual(messages[0].trigger.type, IterableInAppTriggerType.never)
        let dict = messages[0].trigger.dict as! [String: Any]
        TestUtils.validateMatch(keyPath: KeyPath(string: "myPayload.var1"), value: "val1", inDictionary: dict, message: "Expected to find val1")
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
        customPayload1["saveToInbox"] = false
        customPayload1["contentType"] = "html"
        customPayload1["trigger"] = """
        {
            "type" : "immediate",
            "obj1" : "something"
        }
        """.toJsonDict()
        
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
        customPayload2["saveToInbox"] = true
        customPayload2["contentType"] = "html"
        customPayload2["trigger"] = """
        {
            "type" : "never",
            "obj1" : "something"
        }
        """.toJsonDict()
        
        customPayload2["inboxMetadata"] = """
        {
            "title": "title",
            "subtitle": "subtitle",
            "icon": "icon",
        }
        """.toJsonDict()
        
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId1",
                    "campaignId" : 1,
                    "customPayload" : \(customPayload1.toJsonString())
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId2",
                    "campaignId" : 2,
                    "customPayload" : \(customPayload2.toJsonString())
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId3",
                    "campaignId" : 3,
                    "customPayload" : {}
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId4",
                    "campaignId" : 4,
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        
        XCTAssertEqual(messages.count, 4)
        let message1 = messages[0]
        XCTAssertEqual(message1.messageId, "messageId1")
        XCTAssertEqual(message1.saveToInbox, false)
        XCTAssertEqual(message1.trigger.type, IterableInAppTriggerType.immediate)
        XCTAssertTrue(TestUtils.areEqual(dict1: message1.customPayload!, dict2: customPayloadStr1.toJsonDict()))
        
        let message2 = messages[1]
        XCTAssertEqual(message2.messageId, "messageId2")
        XCTAssertEqual(message2.saveToInbox, true)
        XCTAssertEqual(message2.trigger.type, IterableInAppTriggerType.never)
        XCTAssertTrue(TestUtils.areEqual(dict1: message2.customPayload!, dict2: customPayloadStr2.toJsonDict()))
        
        let message3 = messages[2]
        XCTAssertEqual(message3.saveToInbox, false)
        
        let message4 = messages[3]
        XCTAssertEqual(message4.saveToInbox, false)
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
        let inboxSubtitle = "this is the subtitle"
        let inboxIcon = "https://somewhere.com/icon.jpg"
        let payload = """
        {
            "inAppMessages" : [
                {
                    "content" : {
                        "type" : "html",
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId1",
                    "campaignId" : 1,
                    "saveToInbox" : false,
                    "trigger" : {
                        "type" : "immediate",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "customPayload" : \(customPayloadStr1)
                },
                {
                    "saveToInbox" : true,
                    "content" : {
                        "type" : "html",
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>",
                    },
                    "messageId" : "messageId2",
                    "campaignId" : 2,
                    "trigger" : {
                        "type" : "never",
                        "myPayload" : {"var1" : "val1"}
                    },
                    "inboxMetadata": {
                        "title" : "\(inboxTitle)",
                        "subtitle" : "\(inboxSubtitle)",
                        "icon" : "\(inboxIcon)",
                    },
                    "customPayload" : \(customPayloadStr2)
                },
                {
                    "content" : {
                        "html" : "<a href=\\"http://somewhere.com\\">Click here</a>"
                    },
                    "messageId" : "messageId3",
                    "campaignId" : 3,
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
                    "campaignId" : 4,
                    "trigger" : {
                        "type" : "myNewKind",
                        "myPayload" : {"var1" : "val1"}
                    }
                }
            ]
        }
        """.toJsonDict()
        let messages = InAppTestHelper.inAppMessages(fromPayload: payload)
        
        XCTAssertEqual(messages.count, 4)
        let message1 = messages[0]
        XCTAssertEqual(message1.saveToInbox, false)
        XCTAssertEqual(message1.trigger.type, IterableInAppTriggerType.immediate)
        XCTAssertTrue(TestUtils.areEqual(dict1: message1.customPayload!, dict2: customPayloadStr1.toJsonDict()))
        
        let message2 = messages[1]
        XCTAssertEqual(message2.saveToInbox, true)
        let inboxMetadata = message2.inboxMetadata!
        XCTAssertEqual(message2.trigger.type, IterableInAppTriggerType.never)
        XCTAssertEqual(inboxMetadata.title, inboxTitle)
        XCTAssertEqual(inboxMetadata.subtitle, inboxSubtitle)
        XCTAssertEqual(inboxMetadata.icon, inboxIcon)
        XCTAssertTrue(TestUtils.areEqual(dict1: message2.customPayload!, dict2: customPayloadStr2.toJsonDict()))
        
        let message3 = messages[2]
        XCTAssertEqual(message3.saveToInbox, false)
        
        let message4 = messages[3]
        XCTAssertEqual(message4.saveToInbox, false)
    }
    
    private func createInAppPayload(withCustomPayload customPayload: [AnyHashable: Any]) -> [AnyHashable: Any] {
        let id = TestHelper.generateIntGuid()
        return [
            "inAppMessages": [[
                "content": [
                    "html": "<a href='href1'>Click Here</a>",
                    "inAppDisplaySettings": ["backgroundAlpha": 0.5, "left": ["percentage": 60], "right": ["percentage": 60], "bottom": ["displayOption": "AutoExpand"], "top": ["displayOption": "AutoExpand"]] as [String : Any],
                ] as [String : Any],
                "messageId": "messageId-\(id)",
                "campaignId": id,
                "customPayload": customPayload,
            ] as [String : Any]],
        ]
    }
    
    // nil host
    func testCallbackUrlParsingAppleWebdataScheme1() {
        let url = URL(string: "applewebdata://")!
        XCTAssertNil(InAppHelper.parse(inAppUrl: url))
    }
    
    func testCallbackUrlParsingAppleWebdataScheme2() {
        let url = URL(string: "applewebdata://this-is-uuid/the-real-url")!
        let parsed = InAppHelper.parse(inAppUrl: url)!
        if case let InAppHelper.InAppClickedUrl.localResource(name: name) = parsed {
            XCTAssertEqual(name, "the-real-url")
        } else {
            XCTFail("could not parse")
        }
    }
    
    func testCallbackUrlParsingCustomActionScheme() {
        let url = URL(string: "action://buyProduct")!
        if case let InAppHelper.InAppClickedUrl.customAction(name: name) = InAppHelper.parse(inAppUrl: url)! {
            XCTAssertEqual(name, "buyProduct")
        } else {
            XCTFail("Could not parse")
        }
    }
    
    func testCallbackUrlParsingRegularScheme() {
        let url = URL(string: "https://host/path")!
        if case let InAppHelper.InAppClickedUrl.regularUrl(parsedUrl) = InAppHelper.parse(inAppUrl: url)! {
            XCTAssertEqual(parsedUrl, url)
        } else {
            XCTFail("Could not parse")
        }
    }
    
    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let userId = "userId1"
}

