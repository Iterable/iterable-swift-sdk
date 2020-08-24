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
    
    static func sendInApp(to email: String, withCampaignId campaignId: Int) -> Future<SendRequestValue, SendRequestError> {
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
        
        return NetworkHelper.sendRequest(urlRequest, usingSession: urlSession)
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

class E2EDependencyContainer: DependencyContainerProtocol {
    let dateProvider: DateProviderProtocol = SystemDateProvider()
    let networkSession: NetworkSessionProtocol = URLSession(configuration: .default)
    let notificationStateProvider: NotificationStateProviderProtocol = MockNotificationStateProvider(enabled: true)
    let localStorage: LocalStorageProtocol = UserDefaultsLocalStorage()
    let inAppDisplayer: InAppDisplayerProtocol = InAppDisplayer()
    let inAppPersister: InAppPersistenceProtocol = InAppFilePersister()
    let urlOpener: UrlOpenerProtocol = AppUrlOpener()
    let applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared
    let notificationCenter: NotificationCenterProtocol = NotificationCenter.default
    let apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()
    
    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol {
        InAppFetcher(apiClient: apiClient)
    }
}

extension IterableAPIInternal {
    @discardableResult static func initializeForE2E(apiKey: String,
                                                    launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                                    config: IterableConfig = IterableConfig()) -> IterableAPIInternal {
        let e2eDependencyContainer = E2EDependencyContainer()
        let internalImplementation = IterableAPIInternal(apiKey: apiKey,
                                                         launchOptions: launchOptions,
                                                         config: config,
                                                         dependencyContainer: e2eDependencyContainer)
        
        internalImplementation.start().wait()
        
        return internalImplementation
    }
}
