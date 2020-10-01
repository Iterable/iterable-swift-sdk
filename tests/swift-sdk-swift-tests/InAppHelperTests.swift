//
//  Created by Tapash Majumder on 10/8/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppHelperTests: XCTestCase {
    func testGetInAppMessagesWithNoError() {
        class MyApiClient: MockApiClient {
            override func getInAppMessages(_: NSNumber) -> Future<SendRequestValue, SendRequestError> {
                let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)
                return Promise<SendRequestValue, SendRequestError>(value: payload)
            }
        }
        
        InAppHelper.getInAppMessagesFromServer(apiClient: MyApiClient(), number: 10).onSuccess { messages in
            XCTAssertEqual(messages.count, 3)
            XCTAssertEqual(messages[0].messageId, "message1")
            XCTAssertEqual(messages[1].messageId, "message2")
            XCTAssertEqual(messages[2].messageId, "message3")
        }
    }
    
    func testGetInAppMessagesWithErrorGetsConsumed() {
        // we will test with two messages, one is valid and second is invalid
        // the second message should be consumed because it has a message id
        let expectation1 = expectation(description: "in app consume is called for message with error")
        
        class MyApiClient: MockApiClient {
            let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            override func getInAppMessages(_: NSNumber) -> Future<SendRequestValue, SendRequestError> {
                // the second message has no content, so it should be consumed
                let payload = """
                {"inAppMessages":
                [
                    {
                        "saveToInbox": false,
                        "content": {"contentType": "html", "inAppDisplaySettings": {"bottom": {"displayOption": "AutoExpand"}, "backgroundAlpha": 0.5, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}, "html": "<a href=\'https://www.site1.com\'>Click Here</a>", "payload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}},
                        "trigger": {"type": "event", "details": "some event details"},
                        "messageId": "message1",
                        "campaignId": 1,
                        "customPayload": {"title": "Product 1 Available", "date": "2018-11-14T14:00:00:00.32Z"}
                    },
                    {
                        "saveToInbox": true,
                        "trigger": {"type": "never"},
                        "messageId": "message2",
                        "campaignId": 2,
                        "customPayload": {"title": "Product 2 Available", "date": "2018-11-14T14:00:00:00.32Z"}
                    },
                ]
                }
                """.toJsonDict()
                return Promise<SendRequestValue, SendRequestError>(value: payload)
            }
            
            override func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError> {
                if messageId == "message2" {
                    expectation.fulfill()
                }
                return Promise<SendRequestValue, SendRequestError>()
            }
        }
        
        InAppHelper.getInAppMessagesFromServer(apiClient: MyApiClient(expectation: expectation1), number: 10).onSuccess { messages in
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0].messageId, "message1")
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testParseURL() {
        let urlWithNoScheme = URL(string: "blah")!
        XCTAssertNil(InAppHelper.parse(inAppUrl: urlWithNoScheme))
        
        let urlWithInvalidAppleWebdata = URL(string: "applewebdata://")!
        XCTAssertNil(InAppHelper.parse(inAppUrl: urlWithInvalidAppleWebdata))
        
        let urlWithUnsupportedScheme = URL(string: "myscheme://host/path")!
        let parsed = InAppHelper.parse(inAppUrl: urlWithUnsupportedScheme)!
        if case let InAppHelper.InAppClickedUrl.regularUrl(url) = parsed {
            XCTAssertEqual(urlWithUnsupportedScheme, url)
        } else {
            XCTFail("expected regular url")
        }
    }
    
    private class MockApiClient: ApiClientProtocol {
        func register(hexToken _: String,
                      appName _: String,
                      deviceId _: String,
                      sdkVersion _: String?,
                      deviceAttributes _: [String: String],
                      pushServicePlatform _: String,
                      notificationsEnabled _: Bool) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func updateUser(_: [AnyHashable: Any], mergeNestedObjects _: Bool) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func updateEmail(newEmail _: String) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(purchase _: NSNumber, items _: [CommerceItem], dataFields _: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(pushOpen _: NSNumber, templateId _: NSNumber?, messageId _: String?, appAlreadyRunning _: Bool, dataFields _: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(pushOpen _: NSNumber, templateId _: NSNumber?, messageId _: String, appAlreadyRunning _: Bool, dataFields _: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(event _: String, dataFields _: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func updateSubscriptions(_: [NSNumber]?, unsubscribedChannelIds _: [NSNumber]?, unsubscribedMessageTypeIds _: [NSNumber]?, subscribedMessageTypeIds _: [NSNumber]?, campaignId _: NSNumber?, templateId _: NSNumber?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func getInAppMessages(_: NSNumber) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inAppOpen _: String) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inAppOpen _: InAppMessageContext) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inAppClick _: String, clickedUrl _: String) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inAppClick _: InAppMessageContext, clickedUrl _: String) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inAppClose _: InAppMessageContext, source _: InAppCloseSource?, clickedUrl _: String?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inAppDelivery _: InAppMessageContext) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func inAppConsume(messageId _: String) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func inAppConsume(inAppMessageContext _: InAppMessageContext, source _: InAppDeleteSource?) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func track(inboxSession _: IterableInboxSession) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
        
        func disableDevice(forAllUsers _: Bool, hexToken _: String) -> Future<SendRequestValue, SendRequestError> {
            fatalError()
        }
    }
}
