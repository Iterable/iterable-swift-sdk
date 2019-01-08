//
//
//  Created by Tapash Majumder on 10/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

extension Dictionary where Key == AnyHashable {
    func toData() -> Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
}

// Used only by ojbc tests. Remove after converting to Swift.
extension IterableAPI {
    @objc public static func initializeForObjcTesting() {
        internalImplementation = IterableAPIInternal.initializeForTesting()
    }

    @objc public static func initializeForObjcTesting(apiKey: String) {
        internalImplementation = IterableAPIInternal.initializeForTesting(apiKey: apiKey)
    }

    @objc public static func initializeForObjcTesting(config: IterableConfig) {
        internalImplementation = IterableAPIInternal.initializeForTesting(config: config)
    }
}

extension IterableAPI {
    // Internal Only used in unit tests.
    static func initializeForTesting(apiKey: String = "zeeApiKey",
                           launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil,
                           config: IterableConfig = IterableConfig(),
                           dateProvider: DateProviderProtocol = SystemDateProvider(),
                           networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = MockNetworkSession(),
                           notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                           inAppSynchronizer: InAppSynchronizerProtocol = MockInAppSynchronizer(),
                           inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                           urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                           applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                           notificationCenter: NotificationCenterProtocol = NotificationCenter.default) {
        internalImplementation = IterableAPIInternal.initializeForTesting(apiKey: apiKey,
                                                                launchOptions: launchOptions,
                                                                config: config,
                                                                dateProvider: dateProvider,
                                                                networkSession: networkSession,
                                                                notificationStateProvider: notificationStateProvider,
                                                                inAppSynchronizer: inAppSynchronizer,
                                                                inAppDisplayer: inAppDisplayer,
                                                                urlOpener: urlOpener,
                                                                applicationStateProvider: applicationStateProvider,
                                                                notificationCenter: notificationCenter)
    }
}


extension IterableAPIInternal {
    @discardableResult static func initializeForTesting(apiKey: String = "zeeApiKey",
                                                        launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil,
                                                        config: IterableConfig = IterableConfig(),
                                                        dateProvider: DateProviderProtocol = SystemDateProvider(),
                                                        networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = MockNetworkSession(),
                                                        notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                                                        inAppSynchronizer: InAppSynchronizerProtocol = MockInAppSynchronizer(),
                                                        inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                                                        urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                                                        applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                                                        notificationCenter: NotificationCenterProtocol = NotificationCenter.default) -> IterableAPIInternal {
        queue.sync {
            _sharedInstance = IterableAPIInternal(apiKey: apiKey,
                                                  launchOptions: launchOptions,
                                                  config: config,
                                                  dateProvider: dateProvider,
                                                  networkSession: networkSession,
                                                  notificationStateProvider: notificationStateProvider,
                                                  inAppSynchronizer: inAppSynchronizer,
                                                  inAppDisplayer: inAppDisplayer,
                                                  urlOpener: urlOpener,
                                                  applicationStateProvider: applicationStateProvider,
                                                  notificationCenter: notificationCenter)
        }
        return _sharedInstance!
    }
}
