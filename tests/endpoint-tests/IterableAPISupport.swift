//
//  Created by Tapash Majumder on 2020-06-30.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
@testable import IterableSDK

struct IterableAPISupport {
    static func sendDeleteUserRequest(email: String) -> Future<SendRequestValue, SendRequestError> {
        guard let url = URL(string: Path.apiEndpoint + Path.deleteUser + email) else {
            return SendRequestError.createErroredFuture(reason: "could not create post request")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue(apiKey, forHTTPHeaderField: JsonKey.Header.apiKey)
        
        return NetworkHelper.sendRequest(urlRequest, usingSession: urlSession)
    }
    
    private enum Path {
        static let apiEndpoint = "https://api.iterable.com/api"
        static let deleteUser = "/users/"
    }
    
    private static let apiKey = Environment.get(key: .apiKey)!
    
    private static func createPostRequest(iterablePostRequest: PostRequest) -> URLRequest? {
        IterableRequestUtil.createPostRequest(forApiEndPoint: Path.apiEndpoint,
                                              path: iterablePostRequest.path,
                                              headers: createIterableHeaders(),
                                              args: iterablePostRequest.args,
                                              body: iterablePostRequest.body)
    }
    
    private static func createIterableHeaders() -> [String: String] {
        [JsonKey.contentType.jsonKey: JsonValue.applicationJson.jsonStringValue,
         JsonKey.Header.sdkPlatform: JsonValue.iOS.jsonStringValue,
         JsonKey.Header.sdkVersion: IterableAPI.sdkVersion,
         JsonKey.Header.apiKey: apiKey]
    }
    
    private static var urlSession: URLSession = {
        URLSession(configuration: URLSessionConfiguration.default)
    }()
}
