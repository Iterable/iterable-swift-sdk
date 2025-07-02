//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

class UITests: XCTestCase {
    
    // Skipping these tests until we have the time to update them.
    // https://iterable.atlassian.net/browse/MOB-10461
    
    
//    private static var timeout = 15.0
//    private static var monitor: NSObjectProtocol?
//    private var app: XCUIApplication!
//    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
//    
//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        
//        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false
//        
//        app = XCUIApplication()
//        app.launch()
//        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
//        
//        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
//    }
//    
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//    
//    func testSendNotificationOpenSafari() {
//        allowNotificationsIfNeeded()
//        
//        app.buttons["Send Notification"].tap()
//        
//        let springboardHelper = SpringBoardNotificationHelper(springboard: springboard)
//        let notification = springboardHelper.notification
//        XCTAssert(notification.waitForExistence(timeout: 10))
//        
//        notification.press(forDuration: 0.5)
//
//        // Give one second pause before interacting
//        sleep(10)
//        
//        let button = springboardHelper.buttonOpenSafari
//        button.tap()
//        
//        // Give some time to open
//        sleep(10)
//        
//        // Assert that Safari is Active
//        let safariApp = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
//        XCTAssertEqual(safariApp.state, .runningForeground, "Safari is not active")
//    }
//    
//    func testSendNotificationOpenDeepLink() {
//        allowNotificationsIfNeeded()
//                                
//        
//        app.buttons["Send Notification"].tap()
//        
//        let springboardHelper = SpringBoardNotificationHelper(springboard: springboard)
//        let notification = springboardHelper.notification
//        XCTAssert(notification.waitForExistence(timeout: 10))
//                
//        notification.press(forDuration: 1.0)
//        
//        // Give one second pause before interacting
//        sleep(1)
//        
//        let button = springboardHelper.buttonOpenDeepLink
//        button.tap()
//        
//        // Give some time to open
//        sleep(1)
//        
//        waitForElementToAppear(app.staticTexts["https://www.myuniqueurl.com"])
//    }
//    
//    func testSendNotificationCustomAction() {
//        allowNotificationsIfNeeded()
//        
//        app.buttons["Send Notification"].tap()
//        
//        let springboardHelper = SpringBoardNotificationHelper(springboard: springboard)
//        let notification = springboardHelper.notification
//        XCTAssert(notification.waitForExistence(timeout: 10))
//        
//        notification.press(forDuration: 1.0)
//
//        // Give one second pause before interacting
//        sleep(1)
//        
//        let button = springboardHelper.buttonCustomAction
//        button.tap()
//        
//        // Give some time to open
//        sleep(1)
//        
//        waitForElementToAppear(app.staticTexts["MyUniqueCustomAction"])
//    }
//    
//    func testShowInApp1() {
//        inAppTest(buttonName: "Show InApp#1", linkName: "Click Me", expectedCallbackUrl: "https://website/resource#something")
//    }
//    
//    // Full Screen
//    func testShowInApp2() {
//        inAppTest(buttonName: "Show InApp#2", linkName: "Click Here", expectedCallbackUrl: "https://www.google.com/q=something")
//    }
//    
//    // Center and Padding
//    func testShowInApp3() {
//        inAppTest(buttonName: "Show InApp#3", linkName: "Click Here", expectedCallbackUrl: "https://www.google.com/q=something")
//    }
//    
//    // Full Screen
//    func testShowInApp4() {
//        inAppTest(buttonName: "Show InApp#4", linkName: "Click Me", expectedCallbackUrl: "https://website/resource#something")
//    }
//    
//    // Full Screen
//    func testShowInApp5() {
//        inAppTest(buttonName: "Show InApp#5", linkName: "Click Me", expectedCallbackUrl: "https://website/resource#something")
//    }
    
//    private func inAppTest(buttonName: String, linkName: String, expectedCallbackUrl: String) {
//        // tap the inApp button
//        app.buttons[buttonName].tap()
//        
//        // click the link in inApp that shows up
//        let clickMe = app.links[linkName]
//        waitForElementToAppear(clickMe)
//        clickMe.tap()
//        
//        let callbackUrl = app.staticTexts[expectedCallbackUrl]
//        waitForElementToAppear(callbackUrl)
//    }
//    
//    private func waitForElementToAppear(_ element: XCUIElement, fail: Bool = true) {
//        let exists = element.waitForExistence(timeout: UITests.timeout)
//        
//        if fail, !exists {
//            XCTFail("expected element: \(element)")
//        }
//    }
//    
//    private func allowNotificationsIfNeeded() {
//        app.buttons["Setup Notifications"].tap()
//        UITests.monitor = addUIInterruptionMonitor(withDescription: "Getting Notification Permission") { (alert) -> Bool in
//            let okButton = alert.buttons["Allow"]
//            self.waitForElementToAppear(okButton)
//            okButton.tap()
//            if let monitor = UITests.monitor {
//                self.removeUIInterruptionMonitor(monitor)
//            }
//            return true
//        }
//        // Xcode bug?, need to make this app active
//        app.swipeUp()
//    }
}

//struct SpringBoardNotificationHelper {
//    let springboard: XCUIApplication
//    
//    var notification: XCUIElement {
//        springboard.otherElements["Notification"].descendants(matching: .any)["NotificationShortLookView"]
//    }
//    
//    var buttonOpenSafari: XCUIElement {
//        springboard.buttons["Open Safari"].firstMatch
//    }
//    
//    var buttonOpenDeepLink: XCUIElement {
//        springboard.buttons["Open Deeplink"].firstMatch
//    }
//    
//    var buttonCustomAction: XCUIElement {
//        springboard.buttons["Custom Action"].firstMatch
//    }
//}
