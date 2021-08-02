//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// This struct encapsulates all the data that needs to be sent to Iterable backend.
/// This struct must be `Codable`.
@available(iOSApplicationExtension, unavailable)
struct IterableAPICallRequest {
    let apiKey: String
    let endPoint: String
    let auth: Auth
    let deviceMetadata: DeviceMetadata
    let iterableRequest: IterableRequest
    
    enum ProcessorType {
        case offline
        case online
    }
    
    func convertToURLRequest(sentAt: Date, processorType: ProcessorType = .online) -> URLRequest? {
        switch iterableRequest {
        case let .get(getRequest):
            return IterableRequestUtil.createGetRequest(forApiEndPoint: endPoint,
                                                        path: getRequest.path,
                                                        headers: createIterableHeaders(sentAt: sentAt,
                                                                                       processorType: processorType),
                                                        args: getRequest.args)
        case let .post(postRequest):
            return IterableRequestUtil.createPostRequest(forApiEndPoint: endPoint,
                                                         path: postRequest.path,
                                                         headers: createIterableHeaders(sentAt: sentAt,
                                                                                        processorType: processorType),
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
    
    func addingCreatedAt(_ createdAt: Date) -> IterableAPICallRequest {
        addingBodyField(key: JsonKey.Body.createdAt,
                        value: IterableUtil.secondsFromEpoch(for: createdAt))
    }
    
    private func addingBodyField(key: AnyHashable, value: Any) -> IterableAPICallRequest {
        IterableAPICallRequest(apiKey: apiKey,
                               endPoint: endPoint,
                               auth: auth,
                               deviceMetadata: deviceMetadata,
                               iterableRequest: iterableRequest.addingBodyField(key: key, value: value))
    }
    
    private func createIterableHeaders(sentAt: Date, processorType: ProcessorType) -> [String: String] {
        var headers = [JsonKey.contentType: JsonValue.applicationJson,
                       JsonKey.Header.sdkPlatform: JsonValue.iOS,
                       JsonKey.Header.sdkVersion: IterableAPI.sdkVersion,
                       JsonKey.Header.apiKey: apiKey,
                       JsonKey.Header.sentAt: Self.format(sentAt: sentAt),
                       JsonKey.Header.requestProcessor: Self.name(for: processorType)
        ]
        
        if let authToken = auth.authToken {
            headers[JsonKey.Header.authorization] = "Bearer \(authToken)"
        }
        
        return headers
    }
    
    private static func format(sentAt: Date) -> String {
        return "\(IterableUtil.secondsFromEpoch(for: sentAt))"
    }
    
    private static func name(for processorType: ProcessorType) -> String {
        switch processorType {
        case .online:
            return Const.ProcessorTypeName.online
        case .offline:
            return Const.ProcessorTypeName.offline
        }
    }
}

@available(iOSApplicationExtension, unavailable)
extension IterableAPICallRequest: Codable {}
