//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class BlankApiClient: ApiClientProtocol {
    func register(registerTokenInfo: IterableSDK.RegisterTokenInfo, notificationsEnabled: Bool) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func updateUser(_ dataFields: [AnyHashable : Any], mergeNestedObjects: Bool) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func updateEmail(newEmail: String) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func updateCart(items: [IterableSDK.CommerceItem]) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(purchase total: NSNumber, items: [IterableSDK.CommerceItem], dataFields: [AnyHashable : Any]?, campaignId: NSNumber?, templateId: NSNumber?) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(pushOpen campaignId: NSNumber, templateId: NSNumber?, messageId: String, appAlreadyRunning: Bool, dataFields: [AnyHashable : Any]?) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(event eventName: String, dataFields: [AnyHashable : Any]?) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func updateSubscriptions(_ emailListIds: [NSNumber]?, unsubscribedChannelIds: [NSNumber]?, unsubscribedMessageTypeIds: [NSNumber]?, subscribedMessageTypeIds: [NSNumber]?, campaignId: NSNumber?, templateId: NSNumber?) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func getInAppMessages(_ count: NSNumber) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(inAppOpen inAppMessageContext: IterableSDK.InAppMessageContext) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(inAppClick inAppMessageContext: IterableSDK.InAppMessageContext, clickedUrl: String) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(inAppClose inAppMessageContext: IterableSDK.InAppMessageContext, source: IterableSDK.InAppCloseSource?, clickedUrl: String?) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(inAppDelivery inAppMessageContext: IterableSDK.InAppMessageContext) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func inAppConsume(messageId: String) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func inAppConsume(inAppMessageContext: IterableSDK.InAppMessageContext, source: IterableSDK.InAppDeleteSource?) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func track(inboxSession: IterableSDK.IterableInboxSession) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func disableDevice(forAllUsers allUsers: Bool, hexToken: String) -> IterableSDK.Pending<IterableSDK.SendRequestValue, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func getRemoteConfiguration() -> IterableSDK.Pending<IterableSDK.RemoteConfiguration, IterableSDK.SendRequestError> {
        Pending()
    }
    
    func getEmbeddedMessages() -> IterableSDK.Pending<IterableSDK.EmbeddedMessagesPayload, IterableSDK.SendRequestError> {
        Pending()
    }
}
