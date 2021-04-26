//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol DependencyContainerProtocol {
    var dateProvider: DateProviderProtocol { get }
    var networkSession: NetworkSessionProtocol { get }
    var notificationStateProvider: NotificationStateProviderProtocol { get }
    var localStorage: LocalStorageProtocol { get }
    var inAppDisplayer: InAppDisplayerProtocol { get }
    var inAppPersister: InAppPersistenceProtocol { get }
    var urlOpener: UrlOpenerProtocol { get }
    var applicationStateProvider: ApplicationStateProviderProtocol { get }
    var notificationCenter: NotificationCenterProtocol { get }
    var apnsTypeChecker: APNSTypeCheckerProtocol { get }
    
    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol
    func createPersistenceContextProvider() -> IterablePersistenceContextProvider?
    func createRequestHandler(apiKey: String,
                              config: IterableConfig,
                              endPoint: String,
                              authProvider: AuthProvider?,
                              authManager: IterableInternalAuthManagerProtocol,
                              deviceMetadata: DeviceMetadata,
                              offlineMode: Bool) -> RequestHandlerProtocol
    func createHealthMonitorDataProvider(persistenceContextProvider: IterablePersistenceContextProvider) -> HealthMonitorDataProviderProtocol
}

extension DependencyContainerProtocol {
    func createInAppManager(config: IterableConfig,
                            apiClient: ApiClientProtocol,
                            requestHandler: RequestHandlerProtocol,
                            deviceMetadata: DeviceMetadata) -> IterableInternalInAppManagerProtocol {
        InAppManager(requestHandler: requestHandler,
                     deviceMetadata: deviceMetadata,
                     fetcher: createInAppFetcher(apiClient: apiClient),
                     displayer: inAppDisplayer,
                     persister: inAppPersister,
                     inAppDelegate: config.inAppDelegate,
                     urlDelegate: config.urlDelegate,
                     customActionDelegate: config.customActionDelegate,
                     urlOpener: urlOpener,
                     applicationStateProvider: applicationStateProvider,
                     notificationCenter: notificationCenter,
                     dateProvider: dateProvider,
                     retryInterval: config.inAppDisplayInterval)
    }
    
    func createAuthManager(config: IterableConfig) -> IterableInternalAuthManagerProtocol {
        AuthManager(delegate: config.authDelegate,
                    expirationRefreshPeriod: config.expiringAuthTokenRefreshPeriod,
                    localStorage: localStorage,
                    dateProvider: dateProvider)
    }
    
    func createRequestHandler(apiKey: String,
                              config: IterableConfig,
                              endPoint: String,
                              authProvider: AuthProvider?,
                              authManager: IterableInternalAuthManagerProtocol,
                              deviceMetadata: DeviceMetadata,
                              offlineMode: Bool) -> RequestHandlerProtocol {
        if #available(iOS 10.0, *) {
            let onlineProcessor = OnlineRequestProcessor(apiKey: apiKey,
                                                         authProvider: authProvider,
                                                         authManager: authManager,
                                                         endPoint: endPoint,
                                                         networkSession: networkSession,
                                                         deviceMetadata: deviceMetadata,
                                                         dateProvider: dateProvider)
            let offlineProcessor: OfflineRequestProcessor?
            let healthMonitor: HealthMonitor?
            if let persistenceContextProvider = createPersistenceContextProvider() {
                let healthMonitorDataProvider = createHealthMonitorDataProvider(persistenceContextProvider: persistenceContextProvider)
                healthMonitor = HealthMonitor(dataProvider: healthMonitorDataProvider)
                offlineProcessor = OfflineRequestProcessor(apiKey: apiKey,
                                                           authProvider: authProvider,
                                                           authManager: authManager,
                                                           endPoint: endPoint,
                                                           deviceMetadata: deviceMetadata,
                                                           taskScheduler: createTaskScheduler(persistenceContextProvider: persistenceContextProvider),
                                                           taskRunner: createTaskRunner(persistenceContextProvider: persistenceContextProvider),
                                                           notificationCenter: notificationCenter)
            } else {
                healthMonitor = nil
                offlineProcessor = nil
            }
            return RequestHandler(onlineProcessor: onlineProcessor,
                                  offlineProcessor: offlineProcessor,
                                  healthMonitor: healthMonitor,
                                  offlineMode: offlineMode)
        } else {
            return LegacyRequestHandler(apiKey: apiKey,
                                        authProvider: authProvider,
                                        authManager: authManager,
                                        endPoint: endPoint,
                                        networkSession: networkSession,
                                        deviceMetadata: deviceMetadata,
                                        dateProvider: dateProvider)
        }
    }
    
    func createHealthMonitorDataProvider(persistenceContextProvider: IterablePersistenceContextProvider) -> HealthMonitorDataProviderProtocol {
        HealthMonitorDataProvider(maxTasks: 1000, persistenceContextProvider: persistenceContextProvider)
    }
    
    func createPersistenceContextProvider() -> IterablePersistenceContextProvider? {
        if #available(iOS 10.0, *) {
            return CoreDataPersistenceContextProvider(dateProvider: dateProvider)
        } else {
            fatalError("Unable to create persistence container for iOS < 10")
        }
    }
    
    @available(iOS 10.0, *)
    private func createTaskScheduler(persistenceContextProvider: IterablePersistenceContextProvider) -> IterableTaskScheduler {
        IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                              notificationCenter: notificationCenter,
                              dateProvider: dateProvider)
    }
    
    @available(iOS 10.0, *)
    private func createTaskRunner(persistenceContextProvider: IterablePersistenceContextProvider) -> IterableTaskRunner {
        IterableTaskRunner(networkSession: networkSession,
                           persistenceContextProvider: persistenceContextProvider,
                           notificationCenter: notificationCenter,
                           connectivityManager: NetworkConnectivityManager())
    }
}

struct DependencyContainer: DependencyContainerProtocol {
    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol {
        InAppFetcher(apiClient: apiClient)
    }
    
    let dateProvider: DateProviderProtocol = SystemDateProvider()
    let networkSession: NetworkSessionProtocol = URLSession(configuration: .default)
    let notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider()
    let localStorage: LocalStorageProtocol = UserDefaultsLocalStorage()
    let inAppDisplayer: InAppDisplayerProtocol = InAppDisplayer()
    let inAppPersister: InAppPersistenceProtocol = InAppFilePersister()
    let urlOpener: UrlOpenerProtocol = AppUrlOpener()
    let applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared
    let notificationCenter: NotificationCenterProtocol = NotificationCenter.default
    let apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()
}
