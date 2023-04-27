//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct DependencyContainer: DependencyContainerProtocol {
    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol {
        InAppFetcher(apiClient: apiClient)
    }
    
    let dateProvider: DateProviderProtocol = SystemDateProvider()
    let networkSession: NetworkSessionProtocol = URLSession(configuration: .default)
    let notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider()
    let localStorage: LocalStorageProtocol = LocalStorage()
    let inAppDisplayer: InAppDisplayerProtocol = InAppDisplayer()
    let inAppPersister: InAppPersistenceProtocol
    let urlOpener: UrlOpenerProtocol = AppUrlOpener()
    let applicationStateProvider: ApplicationStateProviderProtocol = AppExtensionHelper.applicationStateProvider
    let notificationCenter: NotificationCenterProtocol = NotificationCenter.default
    let apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()
    
    init(_ config: IterableConfig? = nil) {
        if let config = config, config.useInMemoryStorageForInApps {
            FileHelper.delete(filename: "itbl_inapp", ext: "json")
            
            self.inAppPersister = InAppInMemoryPersister()
        } else {
            self.inAppPersister = InAppFilePersister()
        }
    }
}
