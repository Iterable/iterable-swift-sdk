// This class should have generic helper methods for UI testing.
// It should not contain Iterable specific helper methods.
//
//  Created by Tapash Majumder on 9/7/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import XCTest

struct UITestsHelper {
    static func gotoTab(_ tabName: String, inApp app: XCUIApplication) {
        app.tabBars.buttons[tabName].tap()
    }
    
    static func deleteSwipe(_ cell: XCUIElement) {
        let startPoint = cell.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.0))
        let endPoint = cell.coordinate(withNormalizedOffset: .zero)
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
    }
    
    static func tableCell(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        return app.tables.cells.staticTexts[text]
    }
    
    static func tapButton(withName name: String, inApp app: XCUIApplication) {
        return app.buttons[name].tap()
    }
}

extension XCUIApplication {
    func gotoTab(_ tabName: String) {
        UITestsHelper.gotoTab(tabName, inApp: self)
    }
    
    func tableCell(withText text: String) -> XCUIElement {
        return UITestsHelper.tableCell(withText: text, inApp: self)
    }
    
    func tapButton(withName name: String) {
        return UITestsHelper.tapButton(withName: name, inApp: self)
    }
}

extension XCUIElement {
    func deleteSwipe() {
        UITestsHelper.deleteSwipe(self)
    }
}
