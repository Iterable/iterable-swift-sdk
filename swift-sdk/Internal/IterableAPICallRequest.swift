//
//  Created by Tapash Majumder on 7/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// This struct encapsulates all the data that needs to be sent to Iterable backend.
/// This struct must be `Codable`.
struct IterableAPICallRequest {
    let apiKey: String
    let endPoint: String
    let auth: Auth
    let deviceMetadata: DeviceMetadata
    let iterableRequest: IterableRequest
    
    func convertToURLRequest(currentDate: Date) -> URLRequest? {
        switch iterableRequest {
        case let .get(getRequest):
            return IterableRequestUtil.createGetRequest(forApiEndPoint: endPoint,
                                                        path: getRequest.path,
                                                        headers: createIterableHeaders(currentDate: currentDate),
                                                        args: getRequest.args)
        case let .post(postRequest):
            return IterableRequestUtil.createPostRequest(forApiEndPoint: endPoint,
                                                         path: postRequest.path,
                                                         headers: createIterableHeaders(currentDate: currentDate),
                                                         args: postRequest.args,
                                                         body: postRequest.body)
        }
    }
    
    func getPath() -> String {
        switch iterableRequest {
        case .get(let request):
            return request.path
        case .post(let request):
            return request.path
        }
    }
    
    func addingBodyField(key: AnyHashable, value: Any) -> IterableAPICallRequest {
        IterableAPICallRequest(apiKey: apiKey,
                               endPoint: endPoint,
                               auth: auth,
                               deviceMetadata: deviceMetadata,
                               iterableRequest: iterableRequest.addingBodyField(key: key, value: value))
    }
    
    private func createIterableHeaders(currentDate: Date) -> [String: String] {
        var headers = [JsonKey.contentType.jsonKey: JsonValue.applicationJson.jsonStringValue,
                       JsonKey.Header.sdkPlatform: JsonValue.iOS.jsonStringValue,
                       JsonKey.Header.sdkVersion: IterableAPI.sdkVersion,
                       JsonKey.Header.apiKey: apiKey,
                       JsonKey.Header.sentAt: Self.format(sentAt: currentDate),
        ]
        
        if let authToken = auth.authToken {
            headers[JsonKey.Header.authorization] = "Bearer \(authToken)"
        }
        
        return headers
    }
    
    private static func format(sentAt: Date) -> String {
        return "\(IterableUtil.int(fromDate: sentAt))"
    }
}

extension IterableAPICallRequest: Codable {}
