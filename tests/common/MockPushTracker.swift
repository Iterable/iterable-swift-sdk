//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

public class MockPushTracker: NSObject, PushTrackerProtocol {
    var campaignId: NSNumber?
    var templateId: NSNumber?
    var messageId: String?
    var appAlreadyRunnnig: Bool = false
    var dataFields: [AnyHashable: Any]?
    var onSuccess: OnSuccessHandler?
    var onFailure: OnFailureHandler?
    public var lastPushPayload: [AnyHashable: Any]?
    
    public func trackPushOpen(_ userInfo: [AnyHashable: Any],
                              dataFields: [AnyHashable: Any]?,
                              onSuccess: OnSuccessHandler?,
                              onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError> {
        // save payload
        lastPushPayload = userInfo
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            return trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            return SendRequestError.createErroredFuture(reason: "Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push")
        }
    }
    
    public func trackPushOpen(_ campaignId: NSNumber,
                              templateId: NSNumber?,
                              messageId: String,
                              appAlreadyRunning: Bool,
                              dataFields: [AnyHashable: Any]?,
                              onSuccess: OnSuccessHandler?,
                              onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError> {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        appAlreadyRunnnig = appAlreadyRunning
        self.dataFields = dataFields
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        
        return Fulfill<SendRequestValue, SendRequestError>(value: [:])
    }
}
