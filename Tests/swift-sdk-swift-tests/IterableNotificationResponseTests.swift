//
//  IterableNotificationResponseTests.swift
//  swift-sdk-swift-tests
//
//  Created by Tapash Majumder on 6/14/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest
import UserNotifications

@testable import IterableSDK

class MockDateProvider : DateProviderProtocol {
    var currentDate = Date()
}

class IterableNotificationResponseTests: XCTestCase {
    private let dateProvider = MockDateProvider()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        IterableAPIInternal.initialize(apiKey:"", config: IterableConfig(), dateProvider: dateProvider)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        dateProvider.currentDate = Date()
    }
    
    func testTrackOpenPushWithCustomAction() {
        guard #available(iOS 10.0, *) else {
            return
        }
        
        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
                "defaultAction": [
                    "type": "customAction"
                ]
            ]
        ]

        let response = MockNotificationResponse(userInfo: userInfo, actionIdentifier: UNNotificationDefaultActionIdentifier)
        let pushTracker = MockPushTracker()
        let customActionDelegate = MockCustomActionDelegate(returnValue: true)
        
        let actionRunner = IterableActionRunner(urlDelegate: nil, customActionDelegate: customActionDelegate, urlOpener: MockUrlOpener())
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker, actionRunner: actionRunner, versionInfo: MockVersionInfo(version: 10))
        appIntegration.userNotificationCenter(nil, didReceive: response, withCompletionHandler: nil)
        
        XCTAssertEqual(customActionDelegate.action?.type, "customAction");
        
        XCTAssertEqual(pushTracker.campaignId, 1234)
        XCTAssertEqual(pushTracker.templateId, 4321)
        XCTAssertEqual(pushTracker.messageId, messageId)
        XCTAssertFalse(pushTracker.appAlreadyRunnnig)

        XCTAssertEqual(pushTracker.dataFields?[ITBL_KEY_ACTION_IDENTIFIER] as? String, ITBL_VALUE_DEFAULT_PUSH_OPEN_ACTION_ID)
    }
    
    func testActionButtonDismiss() {
        guard #available(iOS 10.0, *) else {
            return
        }
        
        let messageId = UUID().uuidString
        let userInfo = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
                "actionButtons": [[
                    "identifier": "buttonIdentifier",
                    "buttonType": "dismiss",
                    "action": [
                        "type": "customAction"
                    ]]
                ]
            ]
        ]
        
        let response = MockNotificationResponse(userInfo: userInfo, actionIdentifier: "buttonIdentifier")
        let pushTracker = MockPushTracker()
        let customActionDelegate = MockCustomActionDelegate(returnValue: true)
        
        let actionRunner = IterableActionRunner(urlDelegate: nil, customActionDelegate: customActionDelegate, urlOpener: MockUrlOpener())
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker, actionRunner: actionRunner, versionInfo: MockVersionInfo(version: 10))
        appIntegration.userNotificationCenter(nil, didReceive: response, withCompletionHandler: nil)

        XCTAssertEqual(customActionDelegate.action?.type, "customAction");
        
        XCTAssertEqual(pushTracker.campaignId, 1234)
        XCTAssertEqual(pushTracker.templateId, 4321)
        XCTAssertEqual(pushTracker.messageId, messageId)
        
        XCTAssertEqual(pushTracker.dataFields?[ITBL_KEY_ACTION_IDENTIFIER] as? String, "buttonIdentifier")
    }
    
    func testForegroundPushActionBeforeiOS10() {
        let messageId = UUID().uuidString
        let userInfo = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
                "defaultAction": [
                    "type": "customAction"
                ]
            ]
        ]
        
        let pushTracker = MockPushTracker()
        let customActionDelegate = MockCustomActionDelegate(returnValue: true)
        
        let actionRunner = IterableActionRunner(urlDelegate: nil, customActionDelegate: customActionDelegate, urlOpener: MockUrlOpener())
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker, actionRunner: actionRunner, versionInfo: MockVersionInfo(version: 9))
        appIntegration.application(MockApplicationStateProvider(applicationState: .inactive), didReceiveRemoteNotification: userInfo, fetchCompletionHandler: nil)
        
        
        XCTAssertEqual(customActionDelegate.action?.type, "customAction");
        
        XCTAssertEqual(pushTracker.campaignId, 1234)
        XCTAssertEqual(pushTracker.templateId, 4321)
        XCTAssertEqual(pushTracker.messageId, messageId)
        XCTAssertFalse(pushTracker.appAlreadyRunnnig);
    }
    
    func testSavePushPayload() {
        let api = IterableAPIInternal.sharedInstance!
        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
                "defaultAction": [
                    "type": "customAction"
                ]
            ]
        ]
        
        // call track push open
        api.trackPushOpen(userInfo)

        // check the push payload for messageId
        var pushPayload = api.lastPushPayload
        var itbl = pushPayload?["itbl"] as? [String : Any]
        XCTAssertEqual(itbl?["messageId"] as? String, messageId)
        
        // 23 hours, not expired, still present
        dateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: Date())!
        pushPayload = api.lastPushPayload
        itbl = pushPayload?["itbl"] as? [String : Any]
        XCTAssertEqual(itbl?["messageId"] as? String, messageId)

        // 24 hours, expired, nil payload
        dateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: Date())!
        pushPayload = api.lastPushPayload
        XCTAssertNil(pushPayload)
    }
    
    func testSaveAttributionInfo() {
        let api = IterableAPIInternal.sharedInstance!
        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
                "defaultAction": [
                    "type": "customAction"
                ]
            ]
        ]
        
        // call track push open
        api.trackPushOpen(userInfo)
        
        // check attribution info
        var attributionInfo = api.attributionInfo
        XCTAssertEqual(attributionInfo?.campaignId, 1234)
        XCTAssertEqual(attributionInfo?.templateId, 4321)
        XCTAssertEqual(attributionInfo?.messageId, messageId)

        // 23 hours, not expired, still present
        dateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 23, to: Date())!
        attributionInfo = api.attributionInfo
        XCTAssertEqual(attributionInfo?.campaignId, 1234)
        XCTAssertEqual(attributionInfo?.templateId, 4321)
        XCTAssertEqual(attributionInfo?.messageId, messageId)
        
        // 24 hours, expired, nil payload
        dateProvider.currentDate = Calendar.current.date(byAdding: Calendar.Component.hour, value: 24, to: Date())!
        XCTAssertNil(api.attributionInfo)
    }

    func testLegacyDeeplinkPayload() {
        guard #available(iOS 10.0, *) else {
            return
        }

        let messageId = UUID().uuidString
        let userInfo: [AnyHashable : Any] = [
            "itbl" : [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
            ],
            "url" : "https://example.com"
        ]
        
        let response = MockNotificationResponse(userInfo: userInfo, actionIdentifier: UNNotificationDefaultActionIdentifier)
        let urlOpener = MockUrlOpener()
        let pushTracker = MockPushTracker()
        let actionRunner = IterableActionRunner(urlDelegate: nil,
                                                customActionDelegate: nil,
                                                urlOpener: urlOpener)
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker, actionRunner: actionRunner, versionInfo: MockVersionInfo(version: 10))
        appIntegration.userNotificationCenter(nil, didReceive: response, withCompletionHandler: nil)
        
        XCTAssertEqual(pushTracker.campaignId, 1234)
        XCTAssertEqual(pushTracker.templateId, 4321)
        XCTAssertEqual(pushTracker.messageId, messageId)
        
        XCTAssertEqual(urlOpener.ios10OpenedUrl?.absoluteString, "https://example.com")
    }
}
