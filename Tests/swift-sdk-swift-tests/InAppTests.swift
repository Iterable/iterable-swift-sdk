//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testShowInAppSingle() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            expectation1.fulfill()
        }
        
        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testShowInAppSingleOverride() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    func testShowInAppMultiple() {
        let expectation1 = expectation(description: "testShowInAppMultiple")

        let payload = createPayload(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            expectation1.fulfill()
        }
        
        IterableAPI.initializeForTesting(
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testShowInAppMultipleOverride() {
        let expectation1 = expectation(description: "testShowInAppMultipleOverride")
        expectation1.isInverted = true
        
        let payload = createPayload(numMessages: 3)
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            expectation1.fulfill()
        }
        
        let config = IterableConfig()
        config.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer
        )

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }

    
    func testShowInAppOpenUrlByDefault() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, self.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            mockInAppDisplayer.click(url: self.getClickUrl(index: 1))
        }
        
        IterableAPI.initializeForTesting(
                                 inAppSynchronizer: mockInAppSynchronizer,
                                 inAppDisplayer: mockInAppDisplayer,
                                 urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testShowInAppUrlDelegateOverride() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        expectation1.isInverted = true
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, self.getClickUrl(index: 1))
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            mockInAppDisplayer.click(url: self.getClickUrl(index: 1))
        }
        
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        let config = IterableConfig()
        config.urlDelegate = mockUrlDelegate
        IterableAPI.initializeForTesting(
            config: config,
            inAppSynchronizer: mockInAppSynchronizer,
            inAppDisplayer: mockInAppDisplayer,
            urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(createPayload(numMessages: 1))
        
        wait(for: [expectation1], timeout: testExpectationTimeoutForInverted)
    }
    
    private func createPayload(numMessages: Int) -> [AnyHashable : Any] {
        return [
            "inAppMessages" : (1...numMessages).reduce(into: [[AnyHashable : Any]]()) { (result, index) in
                result.append(createOneInAppDict(index: index))
            }
        ]
    }

    private func createOneInAppDict(index: Int) -> [AnyHashable : Any] {
        return [
            "content" : [
                "html" : "<a href='\(getClickUrl(index: index))'>Click Here</a>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]]
            ],
            "messageId" : getMessageId(index: index),
            "campaignId" : getCampaignId(index: index),
        ]
    }
    
    private func getMessageId(index: Int) -> String {
        return "message\(index)"
    }

    private func getCampaignId(index: Int) -> String {
        return "campaign\(index)"
    }

    private func getClickUrl(index: Int) -> String {
        return "https://www.site\(index).com"
    }
}
