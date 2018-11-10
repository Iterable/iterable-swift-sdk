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

    func notestShowInAppByDefault() {
        let expectation1 = expectation(description: "testShowInAppByDefault")
        let payload: [AnyHashable : Any] = ["inAppMessages" : [[
            "content" : [
                "html" : "<a href='https://www.google.com/q=something'>Click Here</a>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]]
            ],
            "messageId" : "messageId",
            "campaignId" : "campaignId",
            ]
            ]]
        let networkSession = MockNetworkSession(
            statusCode: 200,
            json: ["inAppMessages" : [[
                "content" : [
                    "html" : "<a href='https://www.google.com/q=something'>Click Here</a>",
                    "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]]
                ],
                "messageId" : "messageId",
                "campaignId" : "campaignId",
                ]
                ]])
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        TestHelper.initializeApi(
                                 inAppSynchronizer: mockInAppSynchronizer
        )
        
        networkSession.callback = {(_, _, _) in
            networkSession.data = [:].toData()
        }
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        

    }

}
