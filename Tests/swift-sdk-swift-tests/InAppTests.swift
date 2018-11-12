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

    func testShowInAppOpenUrlByDefault() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        
        let payloadUrl = "https://www.google.com/q=something"
        let payload: [AnyHashable : Any] = ["inAppMessages" : [[
            "content" : [
                "html" : "<a href='\(payloadUrl)'>Click Here</a>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]]
            ],
            "messageId" : "messageId",
            "campaignId" : "campaignId",
            ]
            ]]
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockUrlOpener = MockUrlOpener { (url) in
            XCTAssertEqual(url.absoluteString, payloadUrl)
            expectation1.fulfill()
        }
        
        let mockInAppDisplayer = MockInAppDisplayer()
        mockInAppDisplayer.onShowCallback = {(_, _, _) in
            mockInAppDisplayer.click(url: payloadUrl)
        }
        
        IterableAPI.initializeForTesting(
                                 inAppSynchronizer: mockInAppSynchronizer,
                                 inAppDisplayer: mockInAppDisplayer,
                                 urlOpener: mockUrlOpener
        )
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

}
