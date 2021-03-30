//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class DeprecatedFunctionsTests: XCTestCase {
    private let apiKey = "123123123"
    private let email = "user@example.com"
    private let userId = "full-metal-alchemist"
    
    override class func setUp() {
        super.setUp()
    }
    
    func testDeprecatedTrackInAppOpen() {
        let message = IterableInAppMessage(messageId: "message1", campaignId: 1, content: getEmptyInAppContent())
        
        let expectation1 = expectation(description: "track in app open (DEPRECATED VERSION)")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, networkSession: networkSession)
        internalAPI.email = email
        
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppOpen) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppOpen,
                               queryParams: [])
            
            TestUtils.validateHeader(request, self.apiKey)
            
            TestUtils.validateDeprecatedMessageContext(messageId: message.messageId,
                                                       email: self.email,
                                                       saveToInbox: message.saveToInbox,
                                                       silentInbox: message.silentInbox,
                                                       inBody: body)
            
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            
            expectation1.fulfill()
        }
        
        internalAPI.trackInAppOpen(message.messageId)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDeprecatedTrackInAppClick() {
        let message = IterableInAppMessage(messageId: "message1",
                                           campaignId: 1,
                                           trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "immediate"]),
                                           createdAt: nil,
                                           expiresAt: nil,
                                           content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                           saveToInbox: false,
                                           inboxMetadata: nil,
                                           customPayload: nil)
        let buttonUrl = "http://somewhere.com"
        let expectation1 = expectation(description: "track in app click (DEPRECATED VERSION)")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, networkSession: networkSession)
        internalAPI.userId = userId
        
        networkSession.callback = { _, response, _ in
            guard let (request, body) = TestUtils.matchingRequest(networkSession: networkSession,
                                                                  response: response,
                                                                  endPoint: Const.Path.trackInAppClick) else {
                return
            }
            TestUtils.validate(request: request,
                               requestType: .post,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.trackInAppClick,
                               queryParams: [])
            
            TestUtils.validateHeader(request, self.apiKey)
            
            TestUtils.validateDeprecatedMessageContext(messageId: message.messageId,
                                                       userId: self.userId,
                                                       saveToInbox: false,
                                                       silentInbox: false,
                                                       inBody: body)
            
            TestUtils.validateDeviceInfo(inBody: body, withDeviceId: internalAPI.deviceId)
            
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.clickedUrl), value: buttonUrl, inDictionary: body)
            
            expectation1.fulfill()
        }
        
        internalAPI.trackInAppClick(message.messageId, clickedUrl: buttonUrl)
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func getEmptyInAppContent() -> IterableHtmlInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    }
}

extension TestUtils {
    static func validateDeprecatedMessageContext(messageId: String, email: String? = nil, userId: String? = nil, saveToInbox: Bool, silentInbox: Bool, inBody body: [String: Any]) {
        validateMatch(keyPath: KeyPath(keys: JsonKey.messageId), value: messageId, inDictionary: body)
        
        validateEmailOrUserId(email: email, userId: userId, inBody: body)
        
        let contextKey = "\(JsonKey.inAppMessageContext)"
        validateMatch(keyPath: KeyPath(string: "\(contextKey).\(JsonKey.saveToInbox)"), value: saveToInbox, inDictionary: body)
        validateMatch(keyPath: KeyPath(string: "\(contextKey).\(JsonKey.silentInbox)"), value: silentInbox, inDictionary: body)
    }
}
