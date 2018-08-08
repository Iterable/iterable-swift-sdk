//
//  IterableInAppNotificationTests.swift
//  swift-sdk-swift-tests

//  Created by David Truong on 10/3/17.
//  Migrated to Swift by Tapash Majumder on 7/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class IterableInAppNotificationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetNextNotificationNil() {
        let message = IterableInAppManager.getNextMessageFromPayload(nil)
        XCTAssertNil(message)
    }
    
    func testGetNextNotificationEmpty() {
        let message = IterableInAppManager.getNextMessageFromPayload([:])
        XCTAssertNil(message)
    }
    
    func testNotificationCreation() {
        //call showIterableNotificationHTML with fake data
        //Check the top level dialog
        
        let htmlString = "<a href=\"http://www.iterable.com\" target=\"http://www.iterable.com\">test</a>"
        let baseNotification = IterableInAppHTMLViewController(data: htmlString)
        let html = baseNotification.getHtml()
        XCTAssertEqual(html, htmlString)
    }
    
    func testGetPaddingInvalid() {
        let insets = IterableInAppManager.getPaddingFromPayload([:])
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsets.zero))
    }
    
    func testGetPaddingFull() {
        let payload: [AnyHashable : Any] = [
            "top" : ["percentage" : "0"],
            "left" : ["percentage" : "0"],
            "bottom" : ["percentage" : "0"],
            "right" : ["right" : "0"],
        ]
        
        let insets = IterableInAppManager.getPaddingFromPayload(payload)
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsets.zero))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(IterableInAppManager.decodePadding(payload["top"]))
        padding.left = CGFloat(IterableInAppManager.decodePadding(payload["left"]))
        padding.bottom = CGFloat(IterableInAppManager.decodePadding(payload["bottom"]))
        padding.right = CGFloat(IterableInAppManager.decodePadding(payload["right"]))
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(padding, UIEdgeInsets.zero))
    }
    
    func testGetPaddingCenter() {
        let payload: [AnyHashable : Any] = [
            "top" : ["displayOption" : "AutoExpand"],
            "left" : ["percentage" : "0"],
            "bottom" : ["displayOption" : "AutoExpand"],
            "right" : ["right" : "0"],
            ]
        
        let insets = IterableInAppManager.getPaddingFromPayload(payload)
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(IterableInAppManager.decodePadding(payload["top"]))
        padding.left = CGFloat(IterableInAppManager.decodePadding(payload["left"]))
        padding.bottom = CGFloat(IterableInAppManager.decodePadding(payload["bottom"]))
        padding.right = CGFloat(IterableInAppManager.decodePadding(payload["right"]))
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(padding, UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)))
    }
    
    func testGetPaddingTop() {
        let payload: [AnyHashable : Any] = [
            "top" : ["percentage" : "0"],
            "left" : ["percentage" : "0"],
            "bottom" : ["displayOption" : "AutoExpand"],
            "right" : ["right" : "0"],
            ]
        
        let insets = IterableInAppManager.getPaddingFromPayload(payload)
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0)))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(IterableInAppManager.decodePadding(payload["top"]))
        padding.left = CGFloat(IterableInAppManager.decodePadding(payload["left"]))
        padding.bottom = CGFloat(IterableInAppManager.decodePadding(payload["bottom"]))
        padding.right = CGFloat(IterableInAppManager.decodePadding(payload["right"]))
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(padding, UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0)))
    }
    
    func testGetPaddingBottom() {
        let payload: [AnyHashable : Any] = [
            "top" : ["displayOption" : "AutoExpand"],
            "left" : ["percentage" : "0"],
            "bottom" : ["percentage" : "0"],
            "right" : ["right" : "0"],
            ]
        
        let insets = IterableInAppManager.getPaddingFromPayload(payload)
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)))
        
        var padding = UIEdgeInsets.zero
        padding.top = CGFloat(IterableInAppManager.decodePadding(payload["top"]))
        padding.left = CGFloat(IterableInAppManager.decodePadding(payload["left"]))
        padding.bottom = CGFloat(IterableInAppManager.decodePadding(payload["bottom"]))
        padding.right = CGFloat(IterableInAppManager.decodePadding(payload["right"]))
        XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(padding, UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)))
    }
    
    func testNotificationPaddingFull() {
        let notificationType = IterableInAppHTMLViewController.setLocation(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        XCTAssertEqual(notificationType, .full)
    }

    func testNotificationPaddingTop() {
        let notificationType = IterableInAppHTMLViewController.setLocation(UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0))
        XCTAssertEqual(notificationType, .top)
    }
    
    func testNotificationPaddingBottom() {
        let notificationType = IterableInAppHTMLViewController.setLocation(UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0))
        XCTAssertEqual(notificationType, .bottom)
    }

    func testNotificationPaddingCenter() {
        let notificationType = IterableInAppHTMLViewController.setLocation(UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0))
        XCTAssertEqual(notificationType, .center)
    }

    func testNotificationPaddingDefault() {
        let notificationType = IterableInAppHTMLViewController.setLocation(UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0))
        XCTAssertEqual(notificationType, .center)
    }
    
    func testDoNotShowMultipleTimes() {
        let shownFirstTime = IterableInAppManager.showIterableNotificationHTML("", callbackBlock: nil)
        let shownSecondTime = IterableInAppManager.showIterableNotificationHTML("", callbackBlock: nil)
        XCTAssertTrue(shownFirstTime)
        XCTAssertFalse(shownSecondTime)
    }
}
