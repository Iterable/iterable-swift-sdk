//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppHelperTests: XCTestCase {
    func testGetInAppMessagesWithNoError() {
        class MyApiClient: BlankApiClient {
            override func getInAppMessages(_: NSNumber) -> Pending<SendRequestValue, SendRequestError> {
                let payload = TestInAppPayloadGenerator.createPayloadWithUrl(numMessages: 3)
                return Fulfill<SendRequestValue, SendRequestError>(value: payload)
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
        
        class MyApiClient: BlankApiClient {
            let expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }
            
            override func getInAppMessages(_: NSNumber) -> Pending<SendRequestValue, SendRequestError> {
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
                return Fulfill<SendRequestValue, SendRequestError>(value: payload)
            }
            
            override func inAppConsume(messageId: String) -> Pending<SendRequestValue, SendRequestError> {
                if messageId == "message2" {
                    expectation.fulfill()
                }
                return Fulfill<SendRequestValue, SendRequestError>()
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
}
