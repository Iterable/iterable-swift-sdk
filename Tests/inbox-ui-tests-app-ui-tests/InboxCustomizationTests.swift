//
//
//  Created by Tapash Majumder on 1/7/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxCustomizationTests: XCTestCase, IterableInboxUITestsProtocol {
    var app: XCUIApplication!
    
    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        clearNetwork()
    }
    
    override func tearDown() {}
    
    func testLoadMessages() {
        let messages = loadMessages(from: "customization-1", withExtension: "json")
        XCTAssertEqual(messages.count, 4)
    }
    
    private func loadMessages(from file: String, withExtension extension: String) -> [IterableInAppMessage] {
        let path = Bundle(for: type(of: self)).path(forResource: file, ofType: `extension`)!
        let data = FileManager.default.contents(atPath: path)!
        let payload = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
        return InAppTestHelper.inAppMessages(fromPayload: payload)
    }
}
