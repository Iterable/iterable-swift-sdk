//
//  Created by Jay Kim on 10/8/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class DeprecatedFunctionsTests: XCTestCase {
    private var apiKey = "123123123"
    private var email = "user@example.com"
    private var userId = "full-metal-alchemist"
    
    func testDeprecatedTrackInAppOpen() {
        let message = IterableInAppMessage(messageId: "message1", campaignId: "", content: getEmptyInAppContent())
        
        let expectation1 = expectation(description: "track in app open (DEPRECATED VERSION)")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: apiKey, networkSession: networkSession)
        IterableAPI.email = email
        
        networkSession.callback = { _, _, _ in
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppOpen,
                               queryParams: [])
            
            TestUtils.validateHeader(networkSession.request!, self.apiKey)
            
            let body = networkSession.getRequestBody() as! [String: Any]
            
            TestUtils.validateDeprecatedMessageContext(messageId: message.messageId,
                                                       email: self.email,
                                                       saveToInbox: message.saveToInbox,
                                                       silentInbox: message.silentInbox,
                                                       inBody: body)
            
            TestUtils.validateDeviceInfo(inBody: body)
            
            expectation1.fulfill()
        }
        
        IterableAPI.track(inAppOpen: message.messageId)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDeprecatedTrackInAppClick() {
        let message = IterableInAppMessage(messageId: "message1",
                                           campaignId: "",
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "immediate"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                           saveToInbox: false,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        let buttonUrl = "http://somewhere.com"
        let expectation1 = expectation(description: "track in app click (DEPRECATED VERSION)")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        IterableAPI.initializeForTesting(apiKey: apiKey, networkSession: networkSession)
        IterableAPI.userId = userId
        
        networkSession.callback = { _, _, _ in
            TestUtils.validate(request: networkSession.request!,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppClick,
                               queryParams: [])
            
            TestUtils.validateHeader(networkSession.request!, self.apiKey)
            
            let body = networkSession.getRequestBody() as! [String: Any]
            
            TestUtils.validateDeprecatedMessageContext(messageId: message.messageId,
                                                       userId: self.userId,
                                                       saveToInbox: false,
                                                       silentInbox: false,
                                                       inBody: body)
            
            TestUtils.validateDeviceInfo(inBody: body)
            
            TestUtils.validateMatch(keyPath: KeyPath(.clickedUrl), value: buttonUrl, inDictionary: body)
            
            expectation1.fulfill()
        }
        
        IterableAPI.track(inAppClick: message.messageId, buttonURL: buttonUrl)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func getEmptyInAppContent() -> IterableHtmlInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
}

extension TestUtils {
    static func validateDeprecatedMessageContext(messageId: String, email: String? = nil, userId: String? = nil, saveToInbox: Bool, silentInbox: Bool, inBody body: [String: Any]) {
        validateMatch(keyPath: KeyPath(JsonKey.messageId), value: messageId, inDictionary: body)
        
        validateEmailOrUserId(email: email, userId: userId, inBody: body)
        
        let contextKey = "\(JsonKey.inAppMessageContext.jsonKey)"
        validateMatch(keyPath: KeyPath("\(contextKey).\(JsonKey.saveToInbox.jsonKey)"), value: saveToInbox, inDictionary: body)
        validateMatch(keyPath: KeyPath("\(contextKey).\(JsonKey.silentInbox.jsonKey)"), value: silentInbox, inDictionary: body)
    }
}
