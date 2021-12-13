//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications
import WebKit

@testable import IterableSDK

class MockDateProvider: DateProviderProtocol {
    var currentDate = Date()

    func reset() {
        currentDate = Date()
    }
}

struct MockNotificationResponse: NotificationResponseProtocol {
    let userInfo: [AnyHashable: Any]
    let actionIdentifier: String
    
    init(userInfo: [AnyHashable: Any], actionIdentifier: String) {
        self.userInfo = userInfo
        self.actionIdentifier = actionIdentifier
    }
    
    var userText: String? {
        nil
    }
}

@objcMembers
public class MockUrlDelegate: NSObject, IterableURLDelegate {
    // returnValue = true if we handle the url, else false
    override private convenience init() {
        self.init(returnValue: false)
    }
    
    public init(returnValue: Bool) {
        self.returnValue = returnValue
    }
    
    private(set) var returnValue: Bool
    private(set) var url: URL?
    private(set) var context: IterableActionContext?
    var callback: ((URL, IterableActionContext) -> Void)?
    
    public func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        self.url = url
        self.context = context
        callback?(url, context)
        return returnValue
    }
}

@objcMembers
public class MockCustomActionDelegate: NSObject, IterableCustomActionDelegate {
    // returnValue is reserved for future, don't rely on this
    override private convenience init() {
        self.init(returnValue: false)
    }
    
    public init(returnValue: Bool) {
        self.returnValue = returnValue
    }
    
    private(set) var returnValue: Bool
    private(set) var action: IterableAction?
    private(set) var context: IterableActionContext?
    var callback: ((String, IterableActionContext) -> Void)?
    
    public func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        self.action = action
        self.context = context
        callback?(action.type, context)
        return returnValue
    }
}

@objcMembers
public class MockUrlOpener: NSObject, UrlOpenerProtocol {
    var openedUrl: URL?
    var callback: ((URL) -> Void)?
    
    public init(callback: ((URL) -> Void)? = nil) {
        self.callback = callback
    }
    
    public func open(url: URL) {
        callback?(url)
        openedUrl = url
    }
}

public class MockPushTracker: NSObject, PushTrackerProtocol {
    var campaignId: NSNumber?
    var templateId: NSNumber?
    var messageId: String?
    var appAlreadyRunnnig: Bool = false
    var dataFields: [AnyHashable: Any]?
    var onSuccess: OnSuccessHandler?
    var onFailure: OnFailureHandler?
    public var lastPushPayload: [AnyHashable: Any]?
    
    public func trackPushOpen(_ userInfo: [AnyHashable: Any],
                              dataFields: [AnyHashable: Any]?,
                              onSuccess: OnSuccessHandler?,
                              onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        // save payload
        lastPushPayload = userInfo
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            return trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            return SendRequestError.createErroredFuture(reason: "Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push")
        }
    }
    
    public func trackPushOpen(_ campaignId: NSNumber,
                              templateId: NSNumber?,
                              messageId: String,
                              appAlreadyRunning: Bool,
                              dataFields: [AnyHashable: Any]?,
                              onSuccess: OnSuccessHandler?,
                              onFailure: OnFailureHandler?) -> Future<SendRequestValue, SendRequestError> {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        appAlreadyRunnnig = appAlreadyRunning
        self.dataFields = dataFields
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        
        return Promise<SendRequestValue, SendRequestError>(value: [:])
    }
}

@objc public class MockApplicationStateProvider: NSObject, ApplicationStateProviderProtocol {
    override private convenience init() {
        self.init(applicationState: .active)
    }
    
    @objc public init(applicationState: UIApplication.State) {
        self.applicationState = applicationState
    }
    
    public var applicationState: UIApplication.State
}

class MockNetworkSession: NetworkSessionProtocol {
    class MockDataTask: DataTaskProtocol {
        init(url: URL, completionHandler: @escaping CompletionHandler, parent: MockNetworkSession) {
            self.url = url
            self.completionHandler = completionHandler
            self.parent = parent
        }

        var state: URLSessionDataTask.State = .suspended
        
        func resume() {
            state = .running
            parent.makeDataRequest(with: url, completionHandler: completionHandler)
        }
        
        func cancel() {
            canceled = true
            state = .completed
        }
        
        private let url: URL
        private let completionHandler: CompletionHandler
        private let parent: MockNetworkSession
        private var canceled = false
    }

    var urlPatternDataMapping: [String: Data?]?
    var delay: TimeInterval
    var requests = [URLRequest]()
    var callback: ((Data?, URLResponse?, Error?) -> Void)?
    var requestCallback: ((URLRequest) -> Void)?
    
    var statusCode: Int
    var error: Error?
    
    convenience init(statusCode: Int = 200, delay: TimeInterval = 0.0) {
        self.init(statusCode: statusCode,
                  data: [:].toJsonData(),
                  delay: delay,
                  error: nil)
    }
    
    convenience init(statusCode: Int, json: [AnyHashable: Any], delay: TimeInterval = 0.0, error: Error? = nil) {
        self.init(statusCode: statusCode,
                  data: json.toJsonData(),
                  delay: delay,
                  error: error)
    }
    
    convenience init(statusCode: Int, data: Data?, delay: TimeInterval = 0.0, error: Error? = nil) {
        self.init(statusCode: statusCode, urlPatternDataMapping: [".*": data], delay: delay, error: error)
    }
    
    init(statusCode: Int,
         urlPatternDataMapping: [String: Data?]?,
         delay: TimeInterval = 0.0,
         error: Error? = nil) {
        self.statusCode = statusCode
        self.urlPatternDataMapping = urlPatternDataMapping
        self.delay = delay
        self.error = error
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        let block = {
            self.requests.append(request)
            self.requestCallback?(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: self.statusCode, httpVersion: "HTTP/1.1", headerFields: [:])
            let data = self.data(for: request.url?.absoluteString)
            completionHandler(data, response, self.error)
            
            self.callback?(data, response, self.error)
        }

        if delay == 0 {
            DispatchQueue.main.async {
                block()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                block()
            }
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        let block = {
            let response = HTTPURLResponse(url: url, statusCode: self.statusCode, httpVersion: "HTTP/1.1", headerFields: [:])
            let data = self.data(for: url.absoluteString)
            completionHandler(data, response, self.error)
            
            self.callback?(data, response, self.error)
        }
        
        if delay == 0 {
            DispatchQueue.main.async {
                block()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                block()
            }
        }
    }
    
    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        MockDataTask(url: url, completionHandler: completionHandler, parent: self)
    }

    func getRequest(withEndPoint endPoint: String) -> URLRequest? {
        return requests.first { request in
            request.url?.absoluteString.contains(endPoint) == true
        }
    }
    
    static func json(fromData data: Data) -> [AnyHashable: Any] {
        try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
    }
    
    private func data(for urlAbsoluteString: String?) -> Data? {
        guard let urlAbsoluteString = urlAbsoluteString else {
            return nil
        }
        guard let mapping = urlPatternDataMapping else {
            return nil
        }
        
        for pattern in mapping.keys {
            if urlAbsoluteString.range(of: pattern, options: [.regularExpression]) != nil {
                return mapping[pattern] ?? nil
            }
        }
        
        return nil
    }
}

class NoNetworkNetworkSession: NetworkSessionProtocol {
    func makeRequest(_ request: URLRequest, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
            let error = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: nil)
            completionHandler(try! JSONSerialization.data(withJSONObject: [:], options: []), response, error)
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
            let error = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: nil)
            completionHandler(try! JSONSerialization.data(withJSONObject: [:], options: []), response, error)
        }
    }

    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        fatalError("Not implemented")
    }
}

class MockInAppFetcher: InAppFetcherProtocol {
    var syncCallback: (() -> Void)?
    
    init(messages: [IterableInAppMessage] = []) {
        ITBInfo()
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }
    
    deinit {
        ITBInfo()
    }
    
    func fetch() -> Future<[IterableInAppMessage], Error> {
        ITBInfo()
        
        syncCallback?()
        
        return Promise(value: messagesMap.values)
    }
    
    @discardableResult func mockMessagesAvailableFromServer(internalApi: InternalIterableAPI?, messages: [IterableInAppMessage]) -> Future<Int, Error> {
        ITBInfo()
        
        messagesMap = OrderedDictionary<String, IterableInAppMessage>()
        
        messages.forEach {
            messagesMap[$0.messageId] = $0
        }
        
        let result = Promise<Int, Error>()
        
        let inAppManager = internalApi?.inAppManager
        inAppManager?.scheduleSync().onSuccess { [weak inAppManager = inAppManager] _ in
            result.resolve(with: inAppManager?.getMessages().count ?? 0)
        }
        
        return result
    }
    
    @discardableResult func mockInAppPayloadFromServer(internalApi: InternalIterableAPI?, _ payload: [AnyHashable: Any]) -> Future<Int, Error> {
        ITBInfo()
        return mockMessagesAvailableFromServer(internalApi: internalApi, messages: InAppTestHelper.inAppMessages(fromPayload: payload))
    }
    
    func add(message: IterableInAppMessage) {
        messagesMap[message.messageId] = message
    }
    
    var messages: [IterableInAppMessage] {
        messagesMap.values
    }
    
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
}

class MockInAppDisplayer: InAppDisplayerProtocol {
    // when a message is shown this is called back
    var onShow: Promise<IterableInAppMessage, IterableError> = Promise<IterableInAppMessage, IterableError>()
    
    func isShowingInApp() -> Bool {
        showing
    }
    
    // This is not resolved until a url is clicked.
    func showInApp(message: IterableInAppMessage) -> ShowResult {
        guard showing == false else {
            onShow.reject(with: IterableError.general(description: "showing something else"))
            return .notShown("showing something else")
        }
        
        result = Promise<URL, IterableError>()
        
        showing = true
        
        onShow.resolve(with: message)
        
        return .shown(result)
    }
    
    // Mimics clicking a url
    func click(url: URL) {
        ITBInfo()
        showing = false
        result.resolve(with: url)
    }
    
    private var result = Promise<URL, IterableError>()
    private var showing = false
}

class MockInAppDelegate: IterableInAppDelegate {
    var onNewMessageCallback: ((IterableInAppMessage) -> Void)?
    
    init(showInApp: InAppShowResponse = .show) {
        self.showInApp = showInApp
    }
    
    func onNew(message: IterableInAppMessage) -> InAppShowResponse {
        onNewMessageCallback?(message)
        return showInApp
    }
    
    private let showInApp: InAppShowResponse
}

class MockNotificationCenter: NotificationCenterProtocol {
    init() {
        ITBInfo()
    }
    
    deinit {
        ITBInfo()
    }
    
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object _: Any?) {
        observers.append(Observer(observer: observer as! NSObject,
                                  notificationName: name!,
                                  selector: selector))
    }
    
    func removeObserver(_: Any) {}
    
    func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?) {
        _ = observers.filter { $0.notificationName == name }.map {
            let notification = Notification(name: name, object: object, userInfo: userInfo)
            _ = $0.observer?.perform($0.selector, with: notification)
        }
    }
    
    class CallbackReference {
        init(callbackId: String,
             callbackClass: NSObject) {
            self.callbackId = callbackId
            self.callbackClass = callbackClass
        }

        let callbackId: String
        private let callbackClass: NSObject
    }
    
    func addCallback(forNotification notification: Notification.Name, callback: @escaping (Notification) -> Void) -> CallbackReference {
        class CallbackClass: NSObject {
            let callback: (Notification) -> Void
            
            init(callback: @escaping (Notification) -> Void) {
                self.callback = callback
            }
            
            @objc func onNotification(notification: Notification) {
                callback(notification)
            }
        }

        let id = IterableUtil.generateUUID()
        let callbackClass = CallbackClass(callback: callback)

        observers.append(Observer(id: id,
                                  observer: callbackClass,
                                  notificationName: notification,
                                  selector: #selector(callbackClass.onNotification(notification:))))
        return CallbackReference(callbackId: id, callbackClass: callbackClass)
    }

    func removeCallbacks(withIds ids: String...) {
        observers.removeAll { ids.contains($0.id) }
    }
    
    private class Observer: NSObject {
        let id: String
        weak var observer: NSObject?
        let notificationName: Notification.Name
        let selector: Selector
        
        init(id: String = IterableUtil.generateUUID(),
             observer: NSObject,
             notificationName: Notification.Name,
             selector: Selector) {
            self.id = id
            self.observer = observer
            self.notificationName = notificationName
            self.selector = selector
        }
    }
    
    private var observers = [Observer]()
}

class MockInAppPersister: InAppPersistenceProtocol {
    private var messages = [IterableInAppMessage]()
    
    func getMessages() -> [IterableInAppMessage] {
        messages
    }
    
    func persist(_ messages: [IterableInAppMessage]) {
        self.messages = messages
    }
    
    func clear() {
        messages.removeAll()
    }
}

struct MockAPNSTypeChecker: APNSTypeCheckerProtocol {
    let apnsType: APNSType
    
    init(apnsType: APNSType) {
        self.apnsType = apnsType
    }
}

class MockWebView: WebViewProtocol {
    let view: UIView = UIView()
    
    func loadHTMLString(_: String, baseURL _: URL?) -> WKNavigation? {
        nil
    }
    
    func set(position: ViewPosition) {
        self.position = position
        view.frame.size.width = position.width
        view.frame.size.height = position.height
        view.center = position.center
    }
    
    func set(navigationDelegate _: WKNavigationDelegate?) {}
    
    func evaluateJavaScript(_: String, completionHandler: ((Any?, Error?) -> Void)?) {
        completionHandler?(height, nil)
    }
    
    func layoutSubviews() {}
    
    func calculateHeight() -> Future<CGFloat, IterableError> {
        Promise<CGFloat, IterableError>(value: height)
    }
    
    var position: ViewPosition = ViewPosition()
    
    private var height: CGFloat
    
    init(height: CGFloat) {
        self.height = height
    }
}

class MockLocalStorage: LocalStorageProtocol {
    var userId: String? = nil
    
    var email: String? = nil
    
    var authToken: String? = nil
    
    var ddlChecked: Bool = false
    
    var deviceId: String? = nil
    
    var sdkVersion: String? = nil
    
    var offlineMode: Bool = false
    
    var offlineModeBeta: Bool = false
    
    func getAttributionInfo(currentDate: Date) -> IterableAttributionInfo? {
        guard !MockLocalStorage.isExpired(expiration: attributionInfoExpiration, currentDate: currentDate) else {
            return nil
        }
        return attributionInfo
    }
    
    func save(attributionInfo: IterableAttributionInfo?, withExpiration expiration: Date?) {
        self.attributionInfo = attributionInfo
        attributionInfoExpiration = expiration
    }
    
    func getPayload(currentDate: Date) -> [AnyHashable : Any]? {
        guard !MockLocalStorage.isExpired(expiration: payloadExpiration, currentDate: currentDate) else {
            return nil
        }
        return payload
    }
    
    func save(payload: [AnyHashable : Any]?, withExpiration: Date?) {
        self.payload = payload
        payloadExpiration = withExpiration
    }
    
    private var payload: [AnyHashable: Any]? = nil
    private var payloadExpiration: Date? = nil
    
    private var attributionInfo: IterableAttributionInfo? = nil
    private var attributionInfoExpiration: Date? = nil
    
    private static func isExpired(expiration: Date?, currentDate: Date) -> Bool {
        if let expiration = expiration {
            if expiration.timeIntervalSinceReferenceDate > currentDate.timeIntervalSinceReferenceDate {
                // expiration is later
                return false
            } else {
                // expired
                return true
            }
        } else {
            // no expiration
            return false
        }
    }
}
