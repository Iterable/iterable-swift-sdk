//
//  IterableAPI+Internal.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 7/10/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

extension IterableAPI {
    // Internal Only used in unit tests.
    static func initialize(apiKey: String,
                           launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil,
                           config: IterableConfig = IterableConfig(),
                           dateProvider: DateProviderProtocol = SystemDateProvider(),
                           networkSession: @escaping @autoclosure () -> NetworkSessionProtocol = URLSession(configuration: URLSessionConfiguration.default)) {
        implementation = IterableAPIImplementation.init(apiKey: apiKey, launchOptions: launchOptions, config: config, dateProvider: dateProvider, networkSession: networkSession)
    }
}
