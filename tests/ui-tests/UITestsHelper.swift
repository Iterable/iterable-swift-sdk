//
//  Created by Tapash Majumder on 9/7/19.
//  Copyright © 2019 Iterable. All rights reserved.
//
// This class should have generic helper methods for UI testing.
// It should not contain Iterable specific helper methods.

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
    
    static func pullToRefresh(_ cell: XCUIElement) {
        let firstCell = cell
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 25))
        start.press(forDuration: 0, thenDragTo: finish)
    }
    
    static func tableCell(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        app.tables.cells.staticTexts[text]
    }
    
    static func lastElement(query: XCUIElementQuery) -> XCUIElement {
        let count = query.count
        return query.element(boundBy: count - 1)
    }
    
    static func lastCell(inApp app: XCUIApplication) -> XCUIElement {
        lastElement(query: app.tables.cells)
    }
    
    static func link(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        app.links[text]
    }
    
    static func button(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        app.buttons[text]
    }
    
    static func navButton(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        app.navigationBars.buttons[text]
    }
}

extension XCUIApplication {
    func gotoTab(_ tabName: String) {
        UITestsHelper.gotoTab(tabName, inApp: self)
    }
    
    func tableCell(withText text: String) -> XCUIElement {
        UITestsHelper.tableCell(withText: text, inApp: self)
    }
    
    func lastCell() -> XCUIElement {
        UITestsHelper.lastCell(inApp: self)
    }
    
    func link(withText text: String) -> XCUIElement {
        UITestsHelper.link(withText: text, inApp: self)
    }
    
    func button(withText text: String) -> XCUIElement {
        UITestsHelper.button(withText: text, inApp: self)
    }
    
    func navButton(withText text: String) -> XCUIElement {
        UITestsHelper.navButton(withText: text, inApp: self)
    }
}

extension XCUIElement {
    func deleteSwipe() {
        UITestsHelper.deleteSwipe(self)
    }
    
    func pullToRefresh() {
        UITestsHelper.pullToRefresh(self)
    }
    
    @discardableResult func waitToAppear(fail: Bool = true) -> XCUIElement {
        let exists = waitForExistence(timeout: uiElementWaitTimeout)
        
        if fail, !exists {
            XCTFail("expected element: \(self)")
        }
        
        return self
    }
}

let uiElementWaitTimeout = 15.0

protocol IterableUITestsProtocol: AnyObject {
    var app: XCUIApplication! { get }
}

extension IterableUITestsProtocol where Self: XCTestCase {
    func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let exists = element.waitForExistence(timeout: uiElementWaitTimeout)
        
        if fail, !exists {
            XCTFail("expected element: \(element)")
        }
    }
}

struct UITestsGlobal {
    static let application: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()
}
