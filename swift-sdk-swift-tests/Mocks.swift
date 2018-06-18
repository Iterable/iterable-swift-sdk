//
//  MockActionRunner.swift
//  swift-sdk-objc-tests
//
//  Created by Tapash Majumder on 6/13/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications

import IterableSDK

struct MockNotificationResponse : NotificationResponseProtocol {
    let userInfo: [AnyHashable : Any]
    let actionIdentifier: String
    
    init(userInfo: [AnyHashable : Any], actionIdentifier: String) {
        self.userInfo = userInfo;
        self.actionIdentifier = actionIdentifier
    }
    
    var textInputResponse: UNTextInputNotificationResponse? {
        return nil
    }
}


@objc public class MockUrlDelegate : NSObject, IterableURLDelegate {
    // returnValue = true if we handle the url, else false
    private override convenience init() {
        self.init(returnValue: false)
    }
    
    @objc public init(returnValue: Bool) {
        self.returnValue = returnValue
    }
    
    @objc var returnValue: Bool
    @objc var url: URL?
    @objc var action: IterableAction?

    @objc public func handleIterableURL(_ url: URL, fromAction action: IterableAction) -> Bool {
        self.url = url
        self.action = action
        return returnValue
    }
}

@objc public class MockUrlOpener : NSObject, UrlOpenerProtocol {
    @objc var ios10OpenedUrl: URL?
    @objc var preIos10openedUrl: URL?
    
    public func open(url: URL) {
        if #available(iOS 10.0, *) {
            ios10OpenedUrl = url
        } else {
            preIos10openedUrl = url
        }
    }
}

@objc public class MockCustomActionDelegate : NSObject, IterableCustomActionDelegate {
    // returnValue = true if we handle the url, else false
    private override convenience init() {
        self.init(returnValue: false)
    }
    
    @objc public init(returnValue: Bool) {
        self.returnValue = returnValue
    }
    
    @objc var returnValue: Bool
    @objc var action: IterableAction?
    
    public func handleIterableCustomAction(_ action: IterableAction) -> Bool {
        self.action = action
        return returnValue
    }
}

@objc public class MockPushTracker : NSObject, PushTrackerProtocol {
    @objc var campaignId: NSNumber?
    @objc var templateId: NSNumber?
    @objc var messageId: String?
    @objc var appAlreadyRunnnig: Bool = false
    @objc var dataFields: [AnyHashable : Any]?
    @objc var onSuccess: OnSuccessHandler?
    @objc var onFailure: OnFailureHandler?
    
    @objc public func trackPushOpen(_ userInfo: [AnyHashable : Any]) {
        trackPushOpen(userInfo, dataFields: nil)
    }
    
    public func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?) {
        trackPushOpen(userInfo, dataFields: dataFields, onSuccess: nil, onFailure: nil)
    }
    
    public func trackPushOpen(_ userInfo: [AnyHashable : Any], dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        if let metadata = IterableNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onFailure?("Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push", nil)
        }
    }
    
    public func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) {
        trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: nil, onFailure: nil)
    }
    
    public func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        self.appAlreadyRunnnig = appAlreadyRunning
        self.dataFields = dataFields
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
}

@objc public class MockApplicationStateProvider : NSObject, ApplicationStateProviderProtocol {
    private override convenience init() {
        self.init(applicationState: .active)
    }
    
    @objc public init(applicationState: UIApplicationState) {
        self.applicationState = applicationState
    }
    
    public var applicationState: UIApplicationState
}

@objc public class MockVersionInfo : NSObject, VersionInfoProtocol {
    @objc public init(version: Int) {
        self.version = version
    }
    
    public func isAvailableIOS10() -> Bool {
        return version >= 10
    }
    
    private override convenience init() {
        self.init(version: 10)
    }

    private let version: Int
    
}
