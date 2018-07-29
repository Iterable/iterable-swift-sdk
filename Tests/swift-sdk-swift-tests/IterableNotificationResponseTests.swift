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
        IterableAPIImplementation.initialize(apiKey:"", config: IterableConfig(), dateProvider: dateProvider)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        dateProvider.currentDate = Date()
    }
    
    private func customActionHandler(fromPromise promise: Promise<String, Error>, inContext context:IterableActionContext) -> CustomActionHandler {
        return {(customActionName) in
            promise.resolve(with: customActionName)
            return true
        }
    }
    
    private func contextToCustomActionHandler(fromPromise promise: Promise<String, Error>) -> (IterableActionContext) -> CustomActionHandler {
        return IterableUtil.curry(customActionHandler(fromPromise:inContext:))(promise)
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
        var calledCustomActionName:String?
        let contextToCustomActionHandler: ((IterableActionContext) -> CustomActionHandler) = {(context) in { (customActionName) in
                calledCustomActionName = customActionName
                return true
            }
        }
        
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker,
                                                            versionInfo: MockVersionInfo(version: 10),
                                                            contextToUrlHandler: nil,
                                                            contextToCustomActionHandler: contextToCustomActionHandler,
                                                            urlOpener: MockUrlOpener())
        appIntegration.userNotificationCenter(nil, didReceive: response, withCompletionHandler: nil)
        
        XCTAssertEqual(calledCustomActionName, "customAction");
        
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
        
        let promise = Promise<String, Error>()
        promise.observe { (result) in
            switch (result) {
            case .error(let error):
                XCTFail(error.localizedDescription)
            case .value(let customActionName):
                XCTAssertEqual(customActionName, "customAction")
            }
        }
        
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker,
                                                            versionInfo: MockVersionInfo(version: 10),
                                                            contextToUrlHandler: nil,
                                                            contextToCustomActionHandler: contextToCustomActionHandler(fromPromise: promise),
                                                            urlOpener: MockUrlOpener())
        appIntegration.userNotificationCenter(nil, didReceive: response, withCompletionHandler: nil)

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

        let promise = Promise<String, Error>()
        promise.observe { (result) in
            switch (result) {
            case .error(let error):
                XCTFail(error.localizedDescription)
            case .value(let customActionName):
                XCTAssertEqual(customActionName, "customAction")
            }
        }

        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker,
                                                            versionInfo: MockVersionInfo(version: 9),
                                                            contextToUrlHandler: nil,
                                                            contextToCustomActionHandler: contextToCustomActionHandler(fromPromise: promise),
                                                            urlOpener: MockUrlOpener())
        appIntegration.application(MockApplicationStateProvider(applicationState: .inactive), didReceiveRemoteNotification: userInfo, fetchCompletionHandler: nil)
        
        
        XCTAssertEqual(pushTracker.campaignId, 1234)
        XCTAssertEqual(pushTracker.templateId, 4321)
        XCTAssertEqual(pushTracker.messageId, messageId)
        XCTAssertFalse(pushTracker.appAlreadyRunnnig);
    }
    
    func testSavePushPayload() {
        let api = IterableAPIImplementation.sharedInstance!
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
        let api = IterableAPIImplementation.sharedInstance!
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
        let appIntegration = IterableAppIntegrationInternal(tracker: pushTracker,
                                                            versionInfo: MockVersionInfo(version: 10),
                                                            contextToUrlHandler: nil,
                                                            contextToCustomActionHandler: nil,
                                                            urlOpener: urlOpener)
        appIntegration.userNotificationCenter(nil, didReceive: response, withCompletionHandler: nil)
        
        XCTAssertEqual(pushTracker.campaignId, 1234)
        XCTAssertEqual(pushTracker.templateId, 4321)
        XCTAssertEqual(pushTracker.messageId, messageId)
        
        XCTAssertEqual(urlOpener.ios10OpenedUrl?.absoluteString, "https://example.com")
    }
}
