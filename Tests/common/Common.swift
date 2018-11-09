//
//
//  Created by Tapash Majumder on 11/9/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

struct TestHelper {
    // Initialize Tests with default mocks etc.
    static func initializeApi(apiKey: String = "zeeApiKey",
                           launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil,
                           config: IterableConfig = IterableConfig(),
                           dateProvider: DateProviderProtocol = SystemDateProvider(),
                           networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = MockNetworkSession(),
                           notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider() ,
                           inAppSynchronizer: InAppSynchronizerProtocol = MockInAppSynchronizer(),
                           urlOpener: UrlOpenerProtocol = MockUrlOpener()) {
        IterableAPI.initialize(apiKey: apiKey,
                               launchOptions: launchOptions,
                               config: config,
                               dateProvider: dateProvider,
                               networkSession: networkSession,
                               notificationStateProvider: notificationStateProvider,
                               inAppSynchronizer: inAppSynchronizer,
                               urlOpener: urlOpener)
    }
}

