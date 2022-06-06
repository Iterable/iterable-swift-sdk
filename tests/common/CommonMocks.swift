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
                              onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError> {
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
                              onFailure: OnFailureHandler?) -> Pending<SendRequestValue, SendRequestError> {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        appAlreadyRunnnig = appAlreadyRunning
        self.dataFields = dataFields
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        
        return Fulfill<SendRequestValue, SendRequestError>(value: [:])
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

    struct MockResponse {
        let statusCode: Int
        let data: Data?
        let delay: TimeInterval
        let error: Error?
        let headerFields: [String: String]?
        let queue: DispatchQueue?
        
        init(statusCode: Int = MockNetworkSession.defaultStatus,
             data: Data? = MockNetworkSession.defaultData,
             delay: TimeInterval = 0.0,
             error: Error? = nil,
             headerFields: [String: String]? = MockNetworkSession.defaultHeaderFields,
             queue: DispatchQueue? = nil) {
            self.statusCode = statusCode
            self.data = data
            self.delay = delay
            self.error = error
            self.headerFields = headerFields
            self.queue = queue
        }
        
        func toUrlResponse(url: URL) -> URLResponse? {
            HTTPURLResponse(url: url,
                            statusCode: statusCode,
                            httpVersion: MockNetworkSession.defaultHttpVersion,
                            headerFields: headerFields)
        }
    }
    
    var responseCallback: ((URL) -> MockResponse?)?
    var queue: DispatchQueue
    
    var timeout: TimeInterval = 60.0
    
    var requests = [URLRequest]()
    var callback: ((Data?, URLResponse?, Error?) -> Void)?
    var requestCallback: ((URLRequest) -> Void)?
    
    convenience init(statusCode: Int = MockNetworkSession.defaultStatus, delay: TimeInterval = 0.0) {
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
        let mockResponse = MockResponse(statusCode: statusCode,
                                        data: data,
                                        delay: delay,
                                        error: error)
        self.init(mapping: [".*": mockResponse])
    }
    
    convenience init(mapping: [String: MockResponse?]?) {
        let responseCallback: (URL) -> MockResponse? = { url in
            MockNetworkSession.response(for: url.absoluteString, inMapping: mapping)
        }
        self.init(responseCallback: responseCallback)
    }
    
    init(responseCallback: ((URL) -> MockResponse?)?,
         queue: DispatchQueue = DispatchQueue.main) {
        self.responseCallback = responseCallback
        self.queue = queue
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        let mockResponse = self.mockResponse(for: request.url)

        let block = {
            self.requests.append(request)
            self.requestCallback?(request)
            if let mockResponse = mockResponse {
                let response = mockResponse.toUrlResponse(url: request.url!)
                completionHandler(mockResponse.data, response, mockResponse.error)
                self.callback?(mockResponse.data, response, mockResponse.error)
            } else {
                let response = Self.defaultURLResponse(forUrl: request.url!)
                completionHandler(Self.defaultData, response, nil)
                self.callback?(Self.defaultData, response, nil)
            }
        }

        let queue = mockResponse?.queue ?? self.queue

        let delay = mockResponse?.delay ?? 0
        if  delay == 0 {
            queue.async {
                block()
            }
        } else {
            if delay < timeout {
                queue.asyncAfter(deadline: .now() + delay) {
                    block()
                }
            } else {
                queue.asyncAfter(deadline: .now() + timeout) {
                    let error = NetworkError(reason: "The request timed out.")
                    completionHandler(nil, nil, error)
                    self.callback?(nil, nil, error)
                }
            }
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        let mockResponse = self.mockResponse(for: url)

        let block = {
            if let mockResponse = mockResponse {
                let response = mockResponse.toUrlResponse(url: url)
                completionHandler(mockResponse.data, response, mockResponse.error)
                self.callback?(mockResponse.data, response, mockResponse.error)
            } else {
                let response = HTTPURLResponse(url: url,
                                               statusCode: Self.defaultStatus,
                                               httpVersion: Self.defaultHttpVersion,
                                               headerFields: Self.defaultHeaderFields)
                completionHandler(nil, response, nil)
                self.callback?(nil, response, nil)
            }
        }
        
        let queue = mockResponse?.queue ?? self.queue
        
        let delay = mockResponse?.delay ?? 0
        if delay == 0 {
            queue.async {
                block()
            }
        } else {
            queue.asyncAfter(deadline: .now() + delay) {
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
    
    private static let defaultStatus = 200
    private static let defaultData = [:].toJsonData()
    private static let defaultHttpVersion = "HTTP/1.1"
    private static let defaultHeaderFields: [String: String] = [:]
    
    private static func defaultURLResponse(forUrl url: URL) -> URLResponse? {
        HTTPURLResponse(url: url,
                        statusCode: Self.defaultStatus,
                        httpVersion: Self.defaultHttpVersion,
                        headerFields: Self.defaultHeaderFields)
    }
    
    private func mockResponse(for url: URL?) -> MockResponse? {
        guard let url = url else {
            return nil
        }
        return responseCallback?(url)
    }

    private static func response(for urlAbsoluteString: String?, inMapping mapping: [String: MockResponse?]?) -> MockResponse? {
        guard let urlAbsoluteString = urlAbsoluteString else {
            return nil
        }
        guard let mapping = mapping else {
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
    
    func fetch() -> Pending<[IterableInAppMessage], Error> {
        ITBInfo()
        
        syncCallback?()
        
        return Fulfill(value: messagesMap.values)
    }
    
    @discardableResult func mockMessagesAvailableFromServer(internalApi: InternalIterableAPI?, messages: [IterableInAppMessage]) -> Pending<Int, Error> {
        ITBInfo()
        
        messagesMap = OrderedDictionary<String, IterableInAppMessage>()
        
        messages.forEach {
            messagesMap[$0.messageId] = $0
        }
        
        let result = Fulfill<Int, Error>()
        
        let inAppManager = internalApi?.inAppManager
        inAppManager?.scheduleSync().onSuccess { [weak inAppManager = inAppManager] _ in
            result.resolve(with: inAppManager?.getMessages().count ?? 0)
        }
        
        return result
    }
    
    @discardableResult func mockInAppPayloadFromServer(internalApi: InternalIterableAPI?, _ payload: [AnyHashable: Any]) -> Pending<Int, Error> {
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
    var onShow: Fulfill<IterableInAppMessage, IterableError> = Fulfill<IterableInAppMessage, IterableError>()
    
    func isShowingInApp() -> Bool {
        showing
    }
    
    // This is not resolved until a url is clicked.
    func showInApp(message: IterableInAppMessage, onClickCallback: ((URL) -> Void)?) -> ShowResult {
        guard showing == false else {
            onShow.reject(with: IterableError.general(description: "showing something else"))
            return .notShown("showing something else")
        }
        
        showing = true
        self.onClickCallback = onClickCallback
        
        onShow.resolve(with: message)
        
        return .shown
    }
    
    // Mimics clicking a url
    func click(url: URL) {
        ITBInfo()
        showing = false
        DispatchQueue.main.async { [weak self] in
            self?.onClickCallback?(url)
        }
    }
    
    private var onClickCallback: ((URL) -> Void)?
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
    
    func calculateHeight() -> Pending<CGFloat, IterableError> {
        Fulfill<CGFloat, IterableError>(value: height)
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

class MockInboxState: InboxStateProtocol {
    var clickCallback: ((URL?, IterableInAppMessage, String?) -> Void)?
    
    var isReady = true
    
    var messages = [InboxMessageViewModel]()
    
    var totalMessagesCount: Int {
        messages.count
    }
    
    var unreadMessagesCount: Int {
        messages.reduce(0) {
            $1.read ? $0 + 1 : $0
        }
    }
    
    func sync() -> Pending<Bool, Error> {
        Fulfill(value: true)
    }
    
    func track(inboxSession: IterableInboxSession) {
    }
    
    func loadImage(forMessageId messageId: String, fromUrl url: URL) -> Pending<Data, Error> {
        Fulfill(value: Data())
    }
    
    func handleClick(clickedUrl url: URL?, forMessage message: IterableInAppMessage, inboxSessionId: String?) {
        clickCallback?(url, message, inboxSessionId)
    }
    
    func set(read: Bool, forMessage message: InboxMessageViewModel) {
    }
    
    func remove(message: InboxMessageViewModel, inboxSessionId: String?) {
    }
}

extension IterableHtmlMessageViewController.Parameters {
    static func createForTesting(messageId: String = UUID().uuidString,
                                 campaignId: NSNumber? = TestHelper.generateIntGuid() as NSNumber) -> IterableHtmlMessageViewController.Parameters {
        let metadata = IterableInAppMessageMetadata.createForTesting(messageId: messageId, campaignId: campaignId)
        return IterableHtmlMessageViewController.Parameters(html: "",
                                                            messageMetadata: metadata,
                                                            isModal: false)
    }
}

extension IterableInAppMessageMetadata {
    static func createForTesting(messageId: String = UUID().uuidString,
                                 campaignId: NSNumber? = TestHelper.generateIntGuid() as NSNumber) -> IterableInAppMessageMetadata {
        IterableInAppMessageMetadata(message: IterableInAppMessage.createForTesting(messageId: messageId, campaignId: campaignId), location: .inApp)
    }
}

extension IterableInAppMessage {
    static func createForTesting(messageId: String = UUID().uuidString,
                                 campaignId: NSNumber? = TestHelper.generateIntGuid() as NSNumber) -> IterableInAppMessage {
        IterableInAppMessage(messageId: messageId,
                             campaignId: campaignId,
                             content: IterableHtmlInAppContent.createForTesting())
    }
}

extension IterableHtmlInAppContent {
    static func createForTesting() -> IterableHtmlInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    }
}

class MockMessageViewControllerEventTracker: MessageViewControllerEventTrackerProtocol {
    var trackInAppOpenCallback: ((IterableInAppMessage, InAppLocation, String?) -> Void)?
    var trackInAppCloseCallback: ((IterableInAppMessage, InAppLocation, String?, InAppCloseSource?, String?) -> Void)?
    var trackInAppClickCallback: ((IterableInAppMessage, InAppLocation, String?, String?) -> Void)?


    func trackInAppOpen(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?) {
        trackInAppOpenCallback?(message, location, inboxSessionId)
    }

    func trackInAppClose(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?, source: InAppCloseSource?, clickedUrl: String?) {
        trackInAppCloseCallback?(message, location, inboxSessionId, source, clickedUrl)
    }

    func trackInAppClick(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?, clickedUrl: String) {
        trackInAppClickCallback?(message, location, inboxSessionId, clickedUrl)
    }
}
