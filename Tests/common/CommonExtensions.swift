//
//
//  Created by Tapash Majumder on 10/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

extension String {
    func toJsonDict() -> [AnyHashable : Any] {
        return try! JSONSerialization.jsonObject(with: self.data(using: .utf8)!, options: []) as! [AnyHashable : Any]
    }
}

extension Dictionary where Key == AnyHashable {
    func toJsonData() -> Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func toJsonString() -> String {
        return String(data: toJsonData(), encoding: .utf8)!
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

    init(dateProvider: DateProviderProtocol,
         networkSession: NetworkSessionProtocol,
         notificationStateProvider: NotificationStateProviderProtocol,
         localStorage: LocalStorageProtocol,
         inAppFetcher: InAppFetcherProtocol,
         inAppDisplayer: InAppDisplayerProtocol,
         inAppPersister: InAppPersistenceProtocol,
         urlOpener: UrlOpenerProtocol,
         applicationStateProvider: ApplicationStateProviderProtocol,
         notificationCenter: NotificationCenterProtocol) {
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
    }
    
    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol {
        return self.inAppFetcher
    }
}

extension IterableAPI {
    // Internal Only used in unit tests.
    static func initializeForTesting(apiKey: String = "zeeApiKey",
                           launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil,
                           config: IterableConfig = IterableConfig(),
                           dateProvider: DateProviderProtocol = SystemDateProvider(),
                           networkSession: NetworkSessionProtocol = MockNetworkSession(),
                           notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                           inAppFetcher: InAppFetcherProtocol = MockInAppFetcher(),
                           inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                           inAppPersister: InAppPersistenceProtocol = MockInAppPesister(),
                           urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                           applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                           notificationCenter: NotificationCenterProtocol = NotificationCenter.default) {
        
        let mockDependencyContainer = MockDependencyContainer(dateProvider: dateProvider,
                                                              networkSession: networkSession,
                                                              notificationStateProvider: notificationStateProvider,
                                                              localStorage: UserDefaultsLocalStorage(userDefaults: TestHelper.getTestUserDefaults()),
                                                              inAppFetcher: inAppFetcher,
                                                              inAppDisplayer: inAppDisplayer,
                                                              inAppPersister: inAppPersister,
                                                              urlOpener: urlOpener,
                                                              applicationStateProvider: applicationStateProvider,
                                                              notificationCenter: notificationCenter)
        
        internalImplementation = IterableAPIInternal(apiKey: apiKey,
                                                                launchOptions: launchOptions,
                                                                config: config,
                                                                dependencyContainer: mockDependencyContainer)
        internalImplementation?.start()
    }
}
