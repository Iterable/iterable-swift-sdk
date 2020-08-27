//
//  Created by Tapash Majumder on 10/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

import WebKit

@testable import IterableSDK

extension String {
    func toJsonDict() -> [AnyHashable: Any] {
        try! JSONSerialization.jsonObject(with: data(using: .utf8)!, options: []) as! [AnyHashable: Any]
    }
}

extension Dictionary where Key == AnyHashable {
    func toJsonData() -> Data {
        try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func toJsonString() -> String {
        String(data: toJsonData(), encoding: .utf8)!
    }
}

extension URLRequest {
    var serializedString: String {
        let serializableRequest = createSerializableRequest()
        let encodedData = try! JSONEncoder().encode(serializableRequest)
        return String(bytes: encodedData, encoding: .utf8)!
    }
    
    func createSerializableRequest() -> SerializableRequest {
        let url = self.url!
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        return SerializableRequest(method: httpMethod!,
                                   host: urlComponents.host!,
                                   path: urlComponents.path,
                                   queryParameters: mapQueryItems(urlComponents: urlComponents),
                                   headers: allHTTPHeaderFields,
                                   bodyString: getBodyString())
    }
    
    private func mapQueryItems(urlComponents: URLComponents) -> [String: String]? {
        guard let queryItems = urlComponents.queryItems else {
            return nil
        }
        
        var result = [String: String]()
        
        queryItems.forEach { queryItem in
            if let value = queryItem.value {
                result[queryItem.name] = value
            }
        }
        
        return result
    }
    
    private func getBodyString() -> String? {
        guard let bodyData = httpBody else {
            return nil
        }
        
        return String(data: bodyData, encoding: .utf8)!
    }
}

class MockDependencyContainer: DependencyContainerProtocol {
    let dateProvider: DateProviderProtocol
    let networkSession: NetworkSessionProtocol
    let notificationStateProvider: NotificationStateProviderProtocol
    let localStorage: LocalStorageProtocol
    let inAppFetcher: InAppFetcherProtocol
    let inAppDisplayer: InAppDisplayerProtocol
    let inAppPersister: InAppPersistenceProtocol
    let urlOpener: UrlOpenerProtocol
    let applicationStateProvider: ApplicationStateProviderProtocol
    let notificationCenter: NotificationCenterProtocol
    let apnsTypeChecker: APNSTypeCheckerProtocol
    
    init(dateProvider: DateProviderProtocol,
         networkSession: NetworkSessionProtocol,
         notificationStateProvider: NotificationStateProviderProtocol,
         localStorage: LocalStorageProtocol,
         inAppFetcher: InAppFetcherProtocol,
         inAppDisplayer: InAppDisplayerProtocol,
         inAppPersister: InAppPersistenceProtocol,
         urlOpener: UrlOpenerProtocol,
         applicationStateProvider: ApplicationStateProviderProtocol,
         notificationCenter: NotificationCenterProtocol,
         apnsTypeChecker: APNSTypeCheckerProtocol) {
        self.dateProvider = dateProvider
        self.networkSession = networkSession
        self.notificationStateProvider = notificationStateProvider
        self.localStorage = localStorage
        self.inAppFetcher = inAppFetcher
        self.inAppDisplayer = inAppDisplayer
        self.inAppPersister = inAppPersister
        self.urlOpener = urlOpener
        self.applicationStateProvider = applicationStateProvider
        self.notificationCenter = notificationCenter
        self.apnsTypeChecker = apnsTypeChecker
    }
    
    func createInAppFetcher(apiClient _: ApiClientProtocol) -> InAppFetcherProtocol {
        inAppFetcher
    }
}

extension IterableAPI {
    // Internal Only used in UI tests.
    static func initializeForTesting(apiKey: String = "zeeApiKey",
                                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                     config: IterableConfig = IterableConfig(),
                                     dateProvider: DateProviderProtocol = SystemDateProvider(),
                                     networkSession: NetworkSessionProtocol = MockNetworkSession(),
                                     notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                                     
                                     inAppFetcher: InAppFetcherProtocol = MockInAppFetcher(),
                                     inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                                     inAppPersister: InAppPersistenceProtocol = MockInAppPesister(),
                                     urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                                     applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                                     notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
                                     apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()) {
        let mockDependencyContainer = MockDependencyContainer(dateProvider: dateProvider,
                                                              networkSession: networkSession,
                                                              notificationStateProvider: notificationStateProvider,
                                                              localStorage: UserDefaultsLocalStorage(userDefaults: TestHelper.getTestUserDefaults()),
                                                              inAppFetcher: inAppFetcher,
                                                              inAppDisplayer: inAppDisplayer,
                                                              inAppPersister: inAppPersister,
                                                              urlOpener: urlOpener,
                                                              applicationStateProvider: applicationStateProvider,
                                                              notificationCenter: notificationCenter,
                                                              apnsTypeChecker: apnsTypeChecker)
        
        internalImplementation = IterableAPIInternal(apiKey: apiKey,
                                                     launchOptions: launchOptions,
                                                     config: config,
                                                     dependencyContainer: mockDependencyContainer)
        
        internalImplementation?.start().wait()
    }
}

extension IterableAPIInternal {
    // Internal Only used in unit tests.
    @discardableResult static func initializeForTesting(apiKey: String = "zeeApiKey",
                                                        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                                        config: IterableConfig = IterableConfig(),
                                                        dateProvider: DateProviderProtocol = SystemDateProvider(),
                                                        networkSession: NetworkSessionProtocol = MockNetworkSession(),
                                                        notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                                                        localStorage: LocalStorageProtocol = UserDefaultsLocalStorage(userDefaults: TestHelper.getTestUserDefaults()),
                                                        inAppFetcher: InAppFetcherProtocol = MockInAppFetcher(),
                                                        inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                                                        inAppPersister: InAppPersistenceProtocol = MockInAppPesister(),
                                                        urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                                                        applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                                                        notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
                                                        apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()) -> IterableAPIInternal {
        let mockDependencyContainer = MockDependencyContainer(dateProvider: dateProvider,
                                                              networkSession: networkSession,
                                                              notificationStateProvider: notificationStateProvider,
                                                              localStorage: localStorage,
                                                              inAppFetcher: inAppFetcher,
                                                              inAppDisplayer: inAppDisplayer,
                                                              inAppPersister: inAppPersister,
                                                              urlOpener: urlOpener,
                                                              applicationStateProvider: applicationStateProvider,
                                                              notificationCenter: notificationCenter,
                                                              apnsTypeChecker: apnsTypeChecker)
        
        let internalImplementation = IterableAPIInternal(apiKey: apiKey,
                                                         launchOptions: launchOptions,
                                                         config: config,
                                                         dependencyContainer: mockDependencyContainer)
        
        internalImplementation.start().wait()
        
        return internalImplementation
    }
}
