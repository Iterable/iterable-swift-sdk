//
//  Created by Jay Kim on 7/8/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

protocol ApiClientProtocol: AnyObject {
    func register(hexToken: String,
                  appName: String,
                  deviceId: String,
                  sdkVersion: String?,
                  deviceAttributes: [String: String],
                  pushServicePlatform: String,
                  notificationsEnabled: Bool) -> Future<SendRequestValue, SendRequestError>
    
    func updateUser(_ dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) -> Future<SendRequestValue, SendRequestError>
    
    func updateEmail(newEmail: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(purchase total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError>
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError>
    
    func track(event eventName: String, dataFields: [AnyHashable: Any]?) -> Future<SendRequestValue, SendRequestError>
    
    func updateSubscriptions(_ emailListIds: [NSNumber]?,
                             unsubscribedChannelIds: [NSNumber]?,
                             unsubscribedMessageTypeIds: [NSNumber]?,
                             subscribedMessageTypeIds: [NSNumber]?,
                             campaignId: NSNumber?,
                             templateId: NSNumber?) -> Future<SendRequestValue, SendRequestError>
    
    func getInAppMessages(_ count: NSNumber) -> Future<SendRequestValue, SendRequestError>
    
    // deprecated - will be removed in version 6.3.x or above
    func track(inAppOpen messageId: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppOpen inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError>
    
    // deprecated - will be removed in version 6.3.x or above
    func track(inAppClick messageId: String, clickedUrl: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppClick inAppMessageContext: InAppMessageContext, clickedUrl: String) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppClose inAppMessageContext: InAppMessageContext, source: InAppCloseSource?, clickedUrl: String?) -> Future<SendRequestValue, SendRequestError>
    
    func track(inAppDelivery inAppMessageContext: InAppMessageContext) -> Future<SendRequestValue, SendRequestError>
    
    @discardableResult func inAppConsume(messageId: String) -> Future<SendRequestValue, SendRequestError>
    
    @discardableResult func inAppConsume(inAppMessageContext: InAppMessageContext, source: InAppDeleteSource?) -> Future<SendRequestValue, SendRequestError>
    
    func track(inboxSession: IterableInboxSession) -> Future<SendRequestValue, SendRequestError>
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> Future<SendRequestValue, SendRequestError>
}
