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

// Used only by ojbc tests. Remove after converting to Swift.
extension IterableAPI {
    @objc public static func initializeForObjcTesting() {
        IterableAPI.initializeForTesting()
    }

    @objc public static func initializeForObjcTesting(apiKey: String) {
        IterableAPI.initializeForTesting(apiKey: apiKey)
    }

    @objc public static func initializeForObjcTesting(config: IterableConfig) {
        IterableAPI.initializeForTesting(config: config)
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
                           inAppPersister: InAppPersistenceProtocol = MockInAppPesister(),
                           urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                           applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                           notificationCenter: NotificationCenterProtocol = NotificationCenter.default) {
        
        internalImplementation = IterableAPIInternal(apiKey: apiKey,
                                                                launchOptions: launchOptions,
                                                                config: config,
                                                                dateProvider: dateProvider,
                                                                networkSession: networkSession,
                                                                notificationStateProvider: notificationStateProvider,
                                                                localStorage: UserDefaultsLocalStorage(userDefaults: TestHelper.getTestUserDefaults()),
                                                                inAppSynchronizer: inAppSynchronizer,
                                                                inAppDisplayer: inAppDisplayer,
                                                                inAppPersister: inAppPersister,
                                                                urlOpener: urlOpener,
                                                                applicationStateProvider: applicationStateProvider,
                                                                notificationCenter: notificationCenter)
        internalImplementation?.start()
    }
}
