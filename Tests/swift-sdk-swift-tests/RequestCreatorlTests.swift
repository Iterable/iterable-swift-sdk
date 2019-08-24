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
        let startTotalMessageCount = 15
        let endTotalMessageCount = 10
        let startUnreadMessageCount = 5
        let endUnreadMessageCount = 3
        let urlRequest = convertToUrlRequest(createRequestCreator().createTrackInboxSessionRequest(sessionStart: startDate,
                                                                                                   sessionEnd: endDate,
                                                                                                   startTotalMessageCount: startTotalMessageCount,
                                                                                                   endTotalMessageCount: endTotalMessageCount,
                                                                                                   startUnreadMessageCount: startUnreadMessageCount,
                                                                                                   endUnreadMessageCount: endUnreadMessageCount))
        TestUtils.validate(request: urlRequest, requestType: .post, apiEndPoint: .ITBL_ENDPOINT_API, path: .ITBL_PATH_TRACK_INBOX_SESSION)
        let body = urlRequest.bodyDict
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.email), value: auth.email, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.inboxSessionStart), value: IterableUtil.int(fromDate: startDate), inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.inboxSessionEnd), value: IterableUtil.int(fromDate: endDate), inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.startTotalMessageCount), value: startTotalMessageCount, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.startUnreadMessageCount), value: startUnreadMessageCount, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.endTotalMessageCount), value: endTotalMessageCount, inDictionary: body)
        TestUtils.validateMatch(keyPath: KeyPath(JsonKey.endUnreadMessageCount), value: endUnreadMessageCount, inDictionary: body)
    }
    
    private let apiKey = "zee-api-key"
    
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
