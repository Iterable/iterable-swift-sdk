//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

import WebKit

@testable import IterableSDK

extension String {
    func toJsonDict() -> [AnyHashable: Any] {
        try! JSONSerialization.jsonObject(with: data(using: .utf8)!, options: []) as! [AnyHashable: Any]
    }
}

extension Data {
    func json() -> [AnyHashable: Any] {
        try! JSONSerialization.jsonObject(with: self, options: []) as! [AnyHashable: Any]
    }
}
extension Dictionary where Key == AnyHashable {
    func toJsonData() -> Data {
        try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func toJsonString() -> String {
        String(data: toJsonData(), encoding: .utf8)!
    }
}

extension URLRequest {
    var serializedString: String {
        let serializableRequest = createSerializableRequest()
        let encodedData = try! JSONEncoder().encode(serializableRequest)
        return String(bytes: encodedData, encoding: .utf8)!
    }
    
    func createSerializableRequest() -> SerializableRequest {
        let url = self.url!
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        return SerializableRequest(method: httpMethod!,
                                   host: urlComponents.host!,
                                   path: urlComponents.path,
                                   queryParameters: mapQueryItems(urlComponents: urlComponents),
                                   headers: allHTTPHeaderFields,
                                   bodyString: getBodyString())
    }
    
    private func mapQueryItems(urlComponents: URLComponents) -> [String: String]? {
        guard let queryItems = urlComponents.queryItems else {
            return nil
        }
        
        var result = [String: String]()
        
        queryItems.forEach { queryItem in
            if let value = queryItem.value {
                result[queryItem.name] = value
            }
        }
        
        return result
    }
    
    private func getBodyString() -> String? {
        guard let bodyData = httpBody else {
            return nil
        }
        
        return String(data: bodyData, encoding: .utf8)!
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
    let maxTasks: Int
    let apnsTypeChecker: APNSTypeCheckerProtocol
    let persistenceContextProvider: IterablePersistenceContextProvider?
    
    init(dateProvider: DateProviderProtocol,
         networkSession: NetworkSessionProtocol,
         notificationStateProvider: NotificationStateProviderProtocol,
         localStorage: LocalStorageProtocol,
         inAppFetcher: InAppFetcherProtocol,
         inAppDisplayer: InAppDisplayerProtocol,
         inAppPersister: InAppPersistenceProtocol,
         urlOpener: UrlOpenerProtocol,
         applicationStateProvider: ApplicationStateProviderProtocol,
         notificationCenter: NotificationCenterProtocol,
         maxTasks: Int,
         apnsTypeChecker: APNSTypeCheckerProtocol,
         persistenceContextProvider: IterablePersistenceContextProvider?) {
        ITBInfo()
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
        self.maxTasks = maxTasks
        self.apnsTypeChecker = apnsTypeChecker
        self.persistenceContextProvider = persistenceContextProvider
    }
    
    deinit {
        ITBInfo()
    }
    
    func createInAppFetcher(apiClient _: ApiClientProtocol) -> InAppFetcherProtocol {
        inAppFetcher
    }
    
    func createHealthMonitorDataProvider(persistenceContextProvider: IterablePersistenceContextProvider) -> HealthMonitorDataProviderProtocol {
        HealthMonitorDataProvider(maxTasks: maxTasks, persistenceContextProvider: persistenceContextProvider)
    }
    
    func createPersistenceContextProvider() -> IterablePersistenceContextProvider {
        if let persistenceContextProvider = persistenceContextProvider {
            return persistenceContextProvider
        } else {
            return CoreDataPersistenceContextProvider(dateProvider: dateProvider)
        }
    }
    
    func createRedirectNetworkSession(delegate: RedirectNetworkSessionDelegate) -> NetworkSessionProtocol {
        MockRedirectNetworkSession(networkSession: networkSession, redirectDelegate: delegate)
    }
}

struct MockRedirectNetworkSession: NetworkSessionProtocol {
    var timeout: TimeInterval = 60.0
    
    init(networkSession: NetworkSessionProtocol, redirectDelegate: RedirectNetworkSessionDelegate) {
        self.networkSession = Self.createRedirectNetworkSession(fromNetworkSession: networkSession, redirectDelegate: redirectDelegate)
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler) {
        networkSession.makeRequest(request, completionHandler: completionHandler)
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping CompletionHandler) {
        networkSession.makeDataRequest(with: url, completionHandler: completionHandler)
    }
    
    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        networkSession.createDataTask(with: url, completionHandler: completionHandler)
    }
    
    private static func createRedirectNetworkSession(fromNetworkSession networkSession: NetworkSessionProtocol,
                                                     redirectDelegate: RedirectNetworkSessionDelegate) -> NetworkSessionProtocol {
        let redirectSession = MockNetworkSession()
        let callback: (URL) -> MockNetworkSession.MockResponse? = { [weak redirectDelegate] url in
            if let response = (networkSession as? MockNetworkSession)?.responseCallback?(url) {
                let headerFields = response.headerFields!
                let location = headerFields[Const.HttpHeader.location]
                let deepLinkLocation = location.map { URL(string: $0) } ?? nil
                let (campaignId, templateId, messageId) = Self.getIterableValues(fromCookies: HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url))
                redirectDelegate?.onRedirect(deepLinkLocation: deepLinkLocation,
                                             campaignId: campaignId,
                                             templateId: templateId,
                                             messageId: messageId)
                return response
            } else {
                redirectDelegate?.onRedirect(deepLinkLocation: url, campaignId: nil, templateId: nil, messageId: nil)
                return nil
            }
        }
        redirectSession.responseCallback = callback
        return redirectSession
    }
    
    private static func getIterableValues(fromCookies cookies: [HTTPCookie]) -> (campaignId: NSNumber?, templateId: NSNumber?, messageId: String?) {
        let values: (campaignId: NSNumber?, templateId: NSNumber?, messageId: String?) = (nil, nil, nil)
        return cookies.reduce(into: values) { result, cookie in
            if cookie.name == Const.CookieName.campaignId {
                result.campaignId = number(fromString: cookie.value)
            } else if cookie.name == Const.CookieName.templateId {
                result.templateId = number(fromString: cookie.value)
            } else if cookie.name == Const.CookieName.messageId {
                result.messageId = cookie.value
            }
        }
    }
    
    private static func number(fromString str: String) -> NSNumber {
        if let intValue = Int(str) {
            return NSNumber(value: intValue)
        }
        
        return NSNumber(value: 0)
    }
    
    private let networkSession: NetworkSessionProtocol
}

extension IterableAPI {
    // Internal Only used in UI tests.
    static func initializeForTesting(apiKey: String = "zeeApiKey",
                                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                     config: IterableConfig = IterableConfig(),
                                     apiEndPointOverride: String? = nil,
                                     dateProvider: DateProviderProtocol = SystemDateProvider(),
                                     networkSession: NetworkSessionProtocol = MockNetworkSession(),
                                     notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                                     localStorage: LocalStorageProtocol = MockLocalStorage(),
                                     inAppFetcher: InAppFetcherProtocol = MockInAppFetcher(),
                                     inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                                     inAppPersister: InAppPersistenceProtocol = MockInAppPersister(),
                                     urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                                     applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                                     notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
                                     maxTasks: Int = 1000,
                                     apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker(),
                                     persistenceContextProvider: IterablePersistenceContextProvider? = nil) {
        AppExtensionHelper.initialize()
        let mockDependencyContainer = MockDependencyContainer(dateProvider: dateProvider,
                                                              networkSession: networkSession,
                                                              notificationStateProvider: notificationStateProvider,
                                                              localStorage: localStorage,
                                                              inAppFetcher: inAppFetcher,
                                                              inAppDisplayer: inAppDisplayer,
                                                              inAppPersister: inAppPersister,
                                                              urlOpener: urlOpener,
                                                              applicationStateProvider: applicationStateProvider,
                                                              notificationCenter: notificationCenter,
                                                              maxTasks: maxTasks,
                                                              apnsTypeChecker: apnsTypeChecker,
                                                              persistenceContextProvider: persistenceContextProvider)
        
        implementation = InternalIterableAPI(apiKey: apiKey,
                                             launchOptions: launchOptions,
                                             config: config,
                                             apiEndPointOverride: apiEndPointOverride,
                                             dependencyContainer: mockDependencyContainer)
        
        implementation?.start().wait()
    }
}

extension InternalIterableAPI {
    // Internal Only used in unit tests.
    @discardableResult static func initializeForTesting(apiKey: String = "zeeApiKey",
                                                        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil,
                                                        config: IterableConfig = IterableConfig(),
                                                        apiEndPointOverride: String? = nil,
                                                        dateProvider: DateProviderProtocol = SystemDateProvider(),
                                                        networkSession: NetworkSessionProtocol = MockNetworkSession(),
                                                        notificationStateProvider: NotificationStateProviderProtocol = SystemNotificationStateProvider(),
                                                        localStorage: LocalStorageProtocol = MockLocalStorage(),
                                                        inAppFetcher: InAppFetcherProtocol = MockInAppFetcher(),
                                                        inAppDisplayer: InAppDisplayerProtocol = MockInAppDisplayer(),
                                                        inAppPersister: InAppPersistenceProtocol = MockInAppPersister(),
                                                        urlOpener: UrlOpenerProtocol = MockUrlOpener(),
                                                        applicationStateProvider: ApplicationStateProviderProtocol = UIApplication.shared,
                                                        notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
                                                        maxTasks: Int = 1000,
                                                        apnsTypeChecker: APNSTypeCheckerProtocol = APNSTypeChecker(),
                                                        persistenceContextProvider: IterablePersistenceContextProvider? = nil) -> InternalIterableAPI {
        AppExtensionHelper.initialize()
        let mockDependencyContainer = MockDependencyContainer(dateProvider: dateProvider,
                                                              networkSession: networkSession,
                                                              notificationStateProvider: notificationStateProvider,
                                                              localStorage: localStorage,
                                                              inAppFetcher: inAppFetcher,
                                                              inAppDisplayer: inAppDisplayer,
                                                              inAppPersister: inAppPersister,
                                                              urlOpener: urlOpener,
                                                              applicationStateProvider: applicationStateProvider,
                                                              notificationCenter: notificationCenter,
                                                              maxTasks: maxTasks,
                                                              apnsTypeChecker: apnsTypeChecker,
                                                              persistenceContextProvider: persistenceContextProvider)
        
        let internalImplementation = InternalIterableAPI(apiKey: apiKey,
                                                         launchOptions: launchOptions,
                                                         config: config,
                                                         apiEndPointOverride: apiEndPointOverride,
                                                         dependencyContainer: mockDependencyContainer)
        
        internalImplementation.start().wait()
        
        return internalImplementation
    }
}
