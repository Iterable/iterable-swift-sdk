//
//  Created by Tapash Majumder on 1/14/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit
import Foundation

@testable import IterableSDK

final class DataManager {
    static let shared = DataManager()
    var mockNetworkSession: MockNetworkSession
    var mockInAppFetcher: MockInAppFetcher

    static func initializeIterableApi(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        IterableAPI.initializeForDemo(apiKey: "",
                                      launchOptions: launchOptions,
                                      networkSession: DataManager.shared.mockNetworkSession,
                                      inAppFetcher: DataManager.shared.mockInAppFetcher)
        IterableAPI.email = "user@example.com"
        DataManager.shared.loadMessages(from: "inbox-messages-1", withExtension: "json")
    }
    
    func loadMessages(from file: String, withExtension ext: String) {
        mockInAppFetcher.loadMessages(from: file, withExtension: ext)
    }
    
    static func loadData(from file: String, withExtension extension: String) -> Data {
        let path = Bundle(for: DataManager.self).path(forResource: file, ofType: `extension`)!
        return FileManager.default.contents(atPath: path)!
    }
    
    private init() {
        mockNetworkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: DataManager.createUrlToDataMapper())
        mockInAppFetcher = MockInAppFetcher()
    }
    
    private static func createUrlToDataMapper() -> [String: Data?] {
        var mapper = [String: Data?]()
        mapper[#"mocha.png"#] = DataManager.loadData(from: "mocha", withExtension: "png")
        mapper[#"black-coffee.png"#] = DataManager.loadData(from: "black-coffee", withExtension: "png")
        mapper[#"cappuccino.png"#] = DataManager.loadData(from: "cappuccino", withExtension: "png")
        mapper[#"latte.png"#] = DataManager.loadData(from: "latte", withExtension: "png")
        mapper[".*"] = nil
        return mapper
    }
}

struct DemoDependencyContainer: DependencyContainerProtocol {
    func createInAppFetcher(apiClient: ApiClientProtocol) -> InAppFetcherProtocol {
        return inAppFetcher
    }
    
    let dateProvider: DateProviderProtocol = SystemDateProvider()
    let networkSession: NetworkSessionProtocol
    let notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider()
    let localStorage: LocalStorageProtocol = UserDefaultsLocalStorage()
    let inAppDisplayer: InAppDisplayerProtocol = InAppDisplayer()
    let inAppPersister: InAppPersistenceProtocol = InAppFilePersister()
    let urlOpener: UrlOpenerProtocol = AppUrlOpener()
    let applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared
    let notificationCenter: NotificationCenterProtocol = NotificationCenter.default
    let apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker()

    init(networkSession: NetworkSessionProtocol, inAppFetcher: InAppFetcherProtocol) {
        self.networkSession = networkSession
        self.inAppFetcher = inAppFetcher
    }
    
    private let inAppFetcher: InAppFetcherProtocol
}

extension IterableAPI {
    // Internal Only used For demo.
    static func initializeForDemo(apiKey: String,
                                  launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                  config: IterableConfig = IterableConfig(),
                                  networkSession: NetworkSessionProtocol,
                                  inAppFetcher: InAppFetcherProtocol) {
        let demoDependencyContainer = DemoDependencyContainer(networkSession: networkSession, inAppFetcher: inAppFetcher)
        
        internalImplementation = IterableAPIInternal(apiKey: apiKey,
                                                     launchOptions: launchOptions,
                                                     config: config,
                                                     dependencyContainer: demoDependencyContainer)
        _ = internalImplementation?.start()
    }
}

