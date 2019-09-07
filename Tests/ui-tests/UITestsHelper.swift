// This class should have generic helper methods for UI testing.
// It should not contain Iterable specific helper methods.
//
//  Created by Tapash Majumder on 9/7/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import XCTest

struct UITestsHelper {
    // singleton application instance
    static var globalApplication: XCUIApplication = {
        let app = XCUIApplication()
        app.launch()
        return app
    }()
    
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
    
    static func link(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        return app.links[text]
    }
    
    static func button(withText text: String, inApp app: XCUIApplication) -> XCUIElement {
        return app.buttons[text]
    }
    
    static func tapButton(withName name: String, inApp app: XCUIApplication) {
        app.buttons[name].tap()
    }
    
    static func navButton(withName name: String, inApp app: XCUIApplication) -> XCUIElement {
        return app.navigationBars.buttons[name]
    }
    
    static func tapNavButton(withName name: String, inApp app: XCUIApplication) {
        app.navigationBars.buttons[name].tap()
    }
}

extension XCUIApplication {
    func gotoTab(_ tabName: String) {
        UITestsHelper.gotoTab(tabName, inApp: self)
    }
    
    func tableCell(withText text: String) -> XCUIElement {
        return UITestsHelper.tableCell(withText: text, inApp: self)
    }
    
    func link(withText text: String) -> XCUIElement {
        return UITestsHelper.link(withText: text, inApp: self)
    }
    
    func button(withText text: String) -> XCUIElement {
        return UITestsHelper.button(withText: text, inApp: self)
    }
    
    func tapButton(withName name: String) {
        UITestsHelper.tapButton(withName: name, inApp: self)
    }
    
    func navButton(withName name: String) -> XCUIElement {
        return UITestsHelper.navButton(withName: name, inApp: self)
    }
    
    func tapNavButton(withName name: String) {
        UITestsHelper.tapNavButton(withName: name, inApp: self)
    }
}

extension XCUIElement {
    func deleteSwipe() {
        UITestsHelper.deleteSwipe(self)
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

protocol IterableUITestsProtocol: class {}

extension IterableUITestsProtocol where Self: XCTestCase {
    var app: XCUIApplication { // Just a shortcut to global app
        return UITestsHelper.globalApplication
    }
    
    func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
        let exists = element.waitForExistence(timeout: uiElementWaitTimeout)
        
        if fail, !exists {
            XCTFail("expected element: \(element)")
        }
    }
}
