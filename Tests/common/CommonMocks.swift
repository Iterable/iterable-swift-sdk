//
//  Created by Tapash Majumder on 6/13/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UserNotifications

@testable import IterableSDK

struct MockNotificationResponse: NotificationResponseProtocol {
    let userInfo: [AnyHashable: Any]
    let actionIdentifier: String
    
    init(userInfo: [AnyHashable: Any], actionIdentifier: String) {
        self.userInfo = userInfo
        self.actionIdentifier = actionIdentifier
    }
    
    var textInputResponse: UNTextInputNotificationResponse? {
        return nil
    }
}

@objcMembers
public class MockUrlDelegate: NSObject, IterableURLDelegate {
    // returnValue = true if we handle the url, else false
    private convenience override init() {
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
    private convenience override init() {
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

@objcMembers
public class MockPushTracker: NSObject, PushTrackerProtocol {
    var campaignId: NSNumber?
    var templateId: NSNumber?
    var messageId: String?
    var appAlreadyRunnnig: Bool = false
    var dataFields: [AnyHashable: Any]?
    var onSuccess: OnSuccessHandler?
    var onFailure: OnFailureHandler?
    public var lastPushPayload: [AnyHashable: Any]?
    
    public func trackPushOpen(_ userInfo: [AnyHashable: Any]) {
        trackPushOpen(userInfo, dataFields: nil)
    }
    
    public func trackPushOpen(_ userInfo: [AnyHashable: Any], dataFields: [AnyHashable: Any]?) {
        trackPushOpen(userInfo, dataFields: dataFields, onSuccess: nil, onFailure: nil)
    }
    
    public func trackPushOpen(_ userInfo: [AnyHashable: Any], dataFields: [AnyHashable: Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        // save payload
        lastPushPayload = userInfo
        
        if let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: userInfo), metadata.isRealCampaignNotification() {
            trackPushOpen(metadata.campaignId, templateId: metadata.templateId, messageId: metadata.messageId, appAlreadyRunning: false, dataFields: dataFields, onSuccess: onSuccess, onFailure: onFailure)
        } else {
            onFailure?("Not tracking push open - payload is not an Iterable notification, or a test/proof/ghost push", nil)
        }
    }
    
    public func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?) {
        trackPushOpen(campaignId, templateId: templateId, messageId: messageId, appAlreadyRunning: appAlreadyRunning, dataFields: dataFields, onSuccess: nil, onFailure: nil)
    }
    
    public func trackPushOpen(_ campaignId: NSNumber, templateId: NSNumber?, messageId: String?, appAlreadyRunning: Bool, dataFields: [AnyHashable: Any]?, onSuccess: OnSuccessHandler?, onFailure: OnFailureHandler?) {
        self.campaignId = campaignId
        self.templateId = templateId
        self.messageId = messageId
        appAlreadyRunnnig = appAlreadyRunning
        self.dataFields = dataFields
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }
}

@objc public class MockApplicationStateProvider: NSObject, ApplicationStateProviderProtocol {
    private convenience override init() {
        self.init(applicationState: .active)
    }
    
    @objc public init(applicationState: UIApplication.State) {
        self.applicationState = applicationState
    }
    
    public var applicationState: UIApplication.State
}

class MockNetworkSession: NetworkSessionProtocol {
    var url: URL?
    var request: URLRequest?
    var callback: ((Data?, URLResponse?, Error?) -> Void)?
    var requestCallback: ((URLRequest) -> Void)?
    
    var statusCode: Int
    var data: Data? // This is data returned
    var error: Error?
    
    convenience init(statusCode: Int = 200) {
        self.init(statusCode: statusCode,
                  data: [:].toJsonData(),
                  error: nil)
    }
    
    convenience init(statusCode: Int, json: [AnyHashable: Any], error: Error? = nil) {
        self.init(statusCode: statusCode,
                  data: json.toJsonData(),
                  error: error)
    }
    
    init(statusCode: Int, data: Data?, error: Error? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.error = error
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            self.request = request
            self.requestCallback?(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: self.statusCode, httpVersion: "HTTP/1.1", headerFields: [:])
            completionHandler(self.data, response, self.error)
            
            self.callback?(self.data, response, self.error)
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            self.url = url
            let response = HTTPURLResponse(url: url, statusCode: self.statusCode, httpVersion: "HTTP/1.1", headerFields: [:])
            completionHandler(self.data, response, self.error)
            
            self.callback?(self.data, response, self.error)
        }
    }
    
    func getRequestBody() -> [AnyHashable: Any] {
        return MockNetworkSession.json(fromData: request!.httpBody!)
    }
    
    static func json(fromData data: Data) -> [AnyHashable: Any] {
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
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
}

class MockInAppFetcher: InAppFetcherProtocol {
    var syncCallback: (() -> Void)?
    
    init(messages: [IterableInAppMessage] = []) {
        ITBInfo()
        for message in messages {
            messagesMap[message.messageId] = message
        }
    }
    
    func fetch() -> Future<[IterableInAppMessage], Error> {
        ITBInfo()
        
        syncCallback?()
        
        return Promise(value: messagesMap.values)
    }
    
    @discardableResult func mockMessagesAvailableFromServer(messages: [IterableInAppMessage]) -> Future<Bool, Error> {
        ITBInfo()
        
        messagesMap = OrderedDictionary<String, IterableInAppMessage>()
        
        messages.forEach {
            messagesMap[$0.messageId] = $0
        }
        
        let result = Promise<Bool, Error>()
        
        (IterableAPI.inAppManager as! IterableInAppManagerProtocolInternal).scheduleSync().onSuccess { _ in
            result.resolve(with: true)
        }
        
        return result
    }
    
    @discardableResult func mockInAppPayloadFromServer(_ payload: [AnyHashable: Any]) -> Future<Bool, Error> {
        ITBInfo()
        return mockMessagesAvailableFromServer(messages: InAppTestHelper.inAppMessages(fromPayload: payload))
    }
    
    func add(message: IterableInAppMessage) {
        messagesMap[message.messageId] = message
    }
    
    private var messagesMap = OrderedDictionary<String, IterableInAppMessage>()
}

class MockInAppDisplayer: InAppDisplayerProtocol {
    // when a message is shown this is called back
    var onShow: Promise<IterableInAppMessage, IterableError> = Promise<IterableInAppMessage, IterableError>()
    
    func isShowingInApp() -> Bool {
        return showing
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
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object _: Any?) {
        observers.append(Observer(observer: observer as! NSObject, notificationName: name!, selector: selector))
    }
    
    func removeObserver(_: Any) {}
    
    func post(name: Notification.Name, object _: Any?, userInfo _: [AnyHashable: Any]?) {
        _ = observers.filter { $0.notificationName == name }.map {
            _ = $0.observer.perform($0.selector, with: Notification(name: name))
        }
    }
    
    func addCallback(forNotification notification: Notification.Name, callback: @escaping () -> Void) {
        class CallbackClass: NSObject {
            let callback: () -> Void
            init(callback: @escaping () -> Void) {
                self.callback = callback
            }
            
            @objc func onNotification(notification _: Notification) {
                callback()
            }
        }
        
        let callbackClass = CallbackClass(callback: callback)
        addObserver(callbackClass, selector: #selector(callbackClass.onNotification(notification:)), name: notification, object: self)
    }
    
    private class Observer: NSObject {
        let observer: NSObject
        let notificationName: Notification.Name
        let selector: Selector
        
        init(observer: NSObject, notificationName: Notification.Name, selector: Selector) {
            self.observer = observer
            self.notificationName = notificationName
            self.selector = selector
        }
    }
    
    private var observers = [Observer]()
}

class MockInAppPesister: InAppPersistenceProtocol {
    private var messages = [IterableInAppMessage]()
    
    func getMessages() -> [IterableInAppMessage] {
        return messages
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
