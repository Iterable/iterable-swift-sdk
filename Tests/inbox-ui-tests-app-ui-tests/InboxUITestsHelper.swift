//
//  Created by Tapash Majumder on 9/7/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import IterableSDK
import XCTest

enum TabName: String {
    case
        home = "Home",
        inbox = "Inbox",
        customInbox = "Custom Inbox",
        network = "Network"
}

protocol IterableInboxUITestsProtocol: IterableUITestsProtocol {}

extension IterableInboxUITestsProtocol where Self: XCTestCase {
    func clearNetwork() {
        gotoTab(.network)
        app.button(withText: "Clear").tap()
    }
    
    func body(forEvent event: String) -> [String: Any] {
        let request = serializableRequest(forEvent: event)
        return request.body! as! [String: Any]
    }
    
    func serializableRequest(forEvent event: String) -> SerializableRequest {
        let serializedString = lastElement(forEvent: event).staticTexts["serializedString"].label
        return SerializableRequest.create(from: serializedString)
    }
    
    private func lastElement(forEvent event: String) -> XCUIElement {
        let eventRows = app.tables.cells.containing(.staticText, identifier: Const.apiPath + event)
        let count = eventRows.count
        return eventRows.element(boundBy: count - 1)
    }
    
    func gotoTab(_ tabName: TabName) {
        app.gotoTab(tabName.rawValue)
    }
}
