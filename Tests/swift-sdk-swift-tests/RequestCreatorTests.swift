//
//  Created by Tapash Majumder on 8/24/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class RequestCreatorTests: XCTestCase {
    func testTrackInboxSession() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(60 * 5)
        let impressions = [
            IterableInboxImpression(messageId: "message1", silentInbox: true, displayCount: 2, displayDuration: 1.23),
            IterableInboxImpression(messageId: "message2", silentInbox: false, displayCount: 3, displayDuration: 2.34),
        ]
        let inboxSession = IterableInboxSession(sessionStartTime: startDate,
                                                sessionEndTime: endDate,
                                                startTotalMessageCount: 15,
                                                startUnreadMessageCount: 5,
                                                endTotalMessageCount: 10,
                                                endUnreadMessageCount: 3,
                                                impressions: impressions)
        let urlRequest = convertToUrlRequest(createRequestCreator().createTrackInboxSessionRequest(inboxSession: inboxSession))
        TestUtils.validate(request: urlRequest, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK_INBOX_SESSION)
        let body = urlRequest.bodyDict
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.email), value: auth.email, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.inboxSessionStart), value: IterableUtil.int(fromDate: startDate), inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.inboxSessionEnd), value: IterableUtil.int(fromDate: endDate), inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.startTotalMessageCount), value: inboxSession.startTotalMessageCount, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.startUnreadMessageCount), value: inboxSession.startUnreadMessageCount, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.endTotalMessageCount), value: inboxSession.endTotalMessageCount, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.endUnreadMessageCount), value: inboxSession.endUnreadMessageCount, inDictionary: body)
        
        validateImpressions(impressions, inBody: body)
    }
    
    func testGetInAppMessagesRequestFailure() {
        let auth = Auth(userId: nil, email: nil)
        let requestCreator = RequestCreator(apiKey: apiKey, auth: auth)
        
        let failingRequest = requestCreator.createGetInAppMessagesRequest(1)
        
        if let _ = try? failingRequest.get() {
            XCTFail("request succeeded despite userId and email being nil")
        }
    }
    
    func testGetInAppMessagesRequest() {
        let inAppMessageRequestCount: NSNumber = 42
        
        let request = createRequestCreator().createGetInAppMessagesRequest(inAppMessageRequestCount)
        let urlRequest = convertToUrlRequest(request)
        
        TestUtils.validate(request: urlRequest, requestType: .get, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_GET_INAPP_MESSAGES)
        
        // TODO: consider refactoring this header check into its own unit test and remove from here
        guard let header = urlRequest.allHTTPHeaderFields else {
            XCTFail("no header")
            return
        }
        
        XCTAssertEqual(header[AnyHashable.ITBL_HEADER_SDK_PLATFORM], String.ITBL_PLATFORM_IOS)
        XCTAssertEqual(header[AnyHashable.ITBL_HEADER_SDK_VERSION], IterableAPI.sdkVersion)
        XCTAssertEqual(header[AnyHashable.ITBL_HEADER_API_KEY], apiKey)
        
        guard case let .success(.get(getRequest)) = request, let args = getRequest.args else {
            XCTFail("could not unwrap to a get request and its arguments")
            return
        }
        
        XCTAssertEqual(args[AnyHashable.ITBL_KEY_EMAIL], auth.email)
        XCTAssertEqual(args[AnyHashable.ITBL_KEY_PACKAGE_NAME], Bundle.main.appPackageName)
        XCTAssertEqual(args[AnyHashable.ITBL_KEY_COUNT], inAppMessageRequestCount.stringValue)
    }
    
    private let apiKey = "zee-api-key"
    
    private func validateImpressions(_ impressions: [IterableInboxImpression], inBody body: [String: Any]) {
        guard let impressionsFromBody = body["impressions"] as? [[String: Any]] else {
            XCTFail("Could not find impressions element")
            return
        }
        
        XCTAssertEqual(impressionsFromBody.count, impressions.count)
        impressions.forEach {
            validateImpression($0, impressionsFromBody: impressionsFromBody)
        }
    }
    
    private func validateImpression(_ impression: IterableInboxImpression, impressionsFromBody: [[String: Any]]) {
        guard let matchedImpression = impressionsFromBody.first(where: { impression.messageId == $0["messageId"] as? String }) else {
            XCTFail()
            return
        }
        XCTAssertEqual(matchedImpression["silentInbox"] as? Bool, impression.silentInbox)
        XCTAssertEqual(matchedImpression["displayCount"] as? Int, impression.displayCount)
        XCTAssertEqual(matchedImpression["displayDuration"] as? TimeInterval, impression.displayDuration)
    }
    
    private func convertToUrlRequest(_ requestCreationResult: Result<IterableRequest, IterableError>) -> URLRequest {
        if case let Result.success(iterableRequest) = requestCreationResult {
            return createApiClient(networkSession: MockNetworkSession(statusCode: 200)).convertToURLRequest(iterableRequest: iterableRequest)!
        } else {
            fatalError()
        }
    }
    
    private func createRequestCreator() -> RequestCreator {
        return RequestCreator(apiKey: apiKey, auth: auth)
    }
    
    private func createApiClient(networkSession: NetworkSessionProtocol) -> ApiClient {
        return ApiClient(apiKey: apiKey,
                         authProvider: self,
                         endPoint: .ITBL_ENDPOINT_API,
                         networkSession: networkSession)
    }
}

extension RequestCreatorTests: AuthProvider {
    var auth: Auth {
        return Auth(userId: nil, email: "user@example.com")
    }
}
