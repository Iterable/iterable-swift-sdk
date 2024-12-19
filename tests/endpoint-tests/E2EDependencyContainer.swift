//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation
import UIKit

@testable import IterableSDK


class E2EDependencyContainer: DependencyContainerProtocol {
    let dateProvider: DateProviderProtocol
    let networkSession: NetworkSessionProtocol
    let notificationStateProvider: NotificationStateProviderProtocol
    let localStorage: LocalStorageProtocol
    let inAppDisplayer: InAppDisplayerProtocol
    let inAppPersister: InAppPersistenceProtocol
    let urlOpener: UrlOpenerProtocol
    let applicationStateProvider: ApplicationStateProviderProtocol
    let notificationCenter: NotificationCenterProtocol
    let apnsTypeChecker: APNSTypeCheckerProtocol

    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol {
        InAppFetcher(apiClient: apiClient)
    }
    
    init(dateProvider: DateProviderProtocol = SystemDateProvider(),
         networkSession: NetworkSessionProtocol = URLSession(configuration: .default),
         notificationStateProvider: NotificationStateProviderProtocol = MockNotificationStateProvider(enabled: true),
         localStorage: LocalStorageProtocol = LocalStorage(),
         inAppDisplayer: InAppDisplayerProtocol = InAppDisplayer(),
         inAppPersister: InAppPersistenceProtocol = InAppFilePersister(),
         urlOpener: UrlOpenerProtocol = AppUrlOpener(),
         applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
         notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
         apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()) {
        self.dateProvider = dateProvider
        self.networkSession = networkSession
        self.notificationStateProvider = notificationStateProvider
        self.localStorage = localStorage
        self.inAppDisplayer = inAppDisplayer
        self.inAppPersister = inAppPersister
        self.urlOpener = urlOpener
        self.applicationStateProvider = applicationStateProvider
        self.notificationCenter = notificationCenter
        self.apnsTypeChecker = apnsTypeChecker
    }
}

extension InternalIterableAPI {
    @discardableResult static func initializeForE2E(apiKey: String,
                                                    launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                                    config: IterableConfig = IterableConfig(),
                                                    localStorage: LocalStorageProtocol = MockLocalStorage()) -> InternalIterableAPI {
        AppExtensionHelper.initialize()
        let e2eDependencyContainer = E2EDependencyContainer()
        let internalImplementation = InternalIterableAPI(apiKey: apiKey,
                                                         launchOptions: launchOptions,
                                                         config: config,
                                                         dependencyContainer: e2eDependencyContainer)
        
        internalImplementation.start().wait()
        
        return internalImplementation
    }
}
