//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
@testable import IterableSDK

struct IterableAPISupport {
    static func sendDeleteUserRequest(email: String) -> Pending<SendRequestValue, SendRequestError> {
        guard let url = URL(string: Path.apiEndpoint + Path.deleteUser + email) else {
            return SendRequestError.createErroredFuture(reason: "could not create post request")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(serverApiKey, forHTTPHeaderField: JsonKey.Header.apiKey)
        
        return RequestSender.sendRequest(urlRequest, usingSession: urlSession)
    }
    
    static func sendInApp(to email: String, withCampaignId campaignId: Int) -> Pending<SendRequestValue, SendRequestError> {
        let body: [String: Any] = [
            Key.inAppRecipientEmail: email,
            Key.inAppCampaignId: campaignId,
        ]
        let iterablePostRequest = PostRequest(path: Path.inAppTarget,
                                              args: nil,
                                              body: body)
        guard let urlRequest = createPostRequest(iterablePostRequest: iterablePostRequest) else {
            return SendRequestError.createErroredFuture(reason: "could not create post request")
        }
        
        return RequestSender.sendRequest(urlRequest, usingSession: urlSession)
    }
    
    private enum Path {
        static let apiEndpoint = "https://api.iterable.com/api"
        static let deleteUser = "/users/"
        static let inAppTarget = "/inApp/target"
    }
    
    private enum Key {
        static let inAppRecipientEmail = "recipientEmail"
        static let inAppCampaignId = "campaignId"
    }
    
    private static let apiKey = Environment.apiKey!
    private static let serverApiKey = Environment.serverApiKey!
    
    private static func createPostRequest(iterablePostRequest: PostRequest) -> URLRequest? {
        IterableRequestUtil.createPostRequest(forApiEndPoint: Path.apiEndpoint,
                                              path: iterablePostRequest.path,
                                              headers: createIterableHeaders(),
                                              args: iterablePostRequest.args,
                                              body: iterablePostRequest.body)
    }
    
    private static func createIterableHeaders() -> [String: String] {
        [JsonKey.contentType: JsonValue.applicationJson,
         JsonKey.Header.sdkPlatform: JsonValue.iOS,
         JsonKey.Header.sdkVersion: IterableAPI.sdkVersion,
         JsonKey.Header.apiKey: serverApiKey]
    }
    
    private static var urlSession: URLSession = {
        URLSession(configuration: URLSessionConfiguration.default)
    }()
}
