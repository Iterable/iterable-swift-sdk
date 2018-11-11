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

extension IterableAPI {
    // Internal Only used in unit tests.
    static func initialize(apiKey: String,
                           launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil,
                           config: IterableConfig = IterableConfig(),
                           dateProvider: DateProviderProtocol = SystemDateProvider(),
                           networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = URLSession(configuration: URLSessionConfiguration.default),
                           notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                           inAppSynchronizer: InAppSynchronizerProtocol = DefaultInAppSynchronizer(),
                           urlOpener: UrlOpenerProtocol = AppUrlOpener()) {
        internalImplementation = IterableAPIInternal.initialize(apiKey: apiKey,
                                                                launchOptions: launchOptions,
                                                                config: config,
                                                                dateProvider: dateProvider,
                                                                networkSession: networkSession,
                                                                notificationStateProvider: notificationStateProvider,
                                                                inAppSynchronizer: inAppSynchronizer,
                                                                urlOpener: urlOpener)
    }
}


extension IterableAPIInternal {
    @discardableResult static func initialize(apiKey: String,
                                              launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil,
                                              config: IterableConfig = IterableConfig(),
                                              dateProvider: DateProviderProtocol = SystemDateProvider(),
                                              networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = URLSession(configuration: URLSessionConfiguration.default),
                                              notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                                              inAppSynchronizer: InAppSynchronizerProtocol = DefaultInAppSynchronizer(),
                                              urlOpener: UrlOpenerProtocol = AppUrlOpener()
                                              ) -> IterableAPIInternal {
        queue.sync {
            _sharedInstance = IterableAPIInternal(apiKey: apiKey,
                                                  launchOptions: launchOptions,
                                                  config: config,
                                                  dateProvider: dateProvider,
                                                  networkSession: networkSession,
                                                  notificationStateProvider: notificationStateProvider,
                                                  inAppSynchronizer: inAppSynchronizer,
                                                  urlOpener: urlOpener)
        }
        return _sharedInstance!
    }
}
