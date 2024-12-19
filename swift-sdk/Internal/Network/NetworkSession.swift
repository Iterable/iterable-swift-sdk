//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

protocol DataTaskProtocol {
    var state: URLSessionDataTask.State { get }
    func resume()
    func cancel()
}

extension URLSessionDataTask: DataTaskProtocol {}

protocol NetworkSessionProtocol {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    var timeout: TimeInterval { get set }
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler)
    func makeDataRequest(with url: URL, completionHandler: @escaping CompletionHandler)
    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol
}

extension NetworkSessionProtocol {
    var timeout: TimeInterval {
        get { 60.0 }
        set {}
    }
}

extension URLSession: NetworkSessionProtocol {
    var timeout: TimeInterval {
        get {
            configuration.timeoutIntervalForRequest
        }
        set {
            configuration.timeoutIntervalForRequest = newValue
        }
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler) {
        let task = dataTask(with: request) { data, response, error in
            completionHandler(data, response, error)
        }
        
        task.resume()
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping CompletionHandler) {
        let task = dataTask(with: url) { data, response, error in
            completionHandler(data, response, error)
        }
        
        task.resume()
    }

    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        dataTask(with: url, completionHandler: completionHandler)
    }
}

protocol RedirectNetworkSessionDelegate: AnyObject {
    func onRedirect(deepLinkLocation: URL?, campaignId: NSNumber?, templateId: NSNumber?, messageId: String?)
}

protocol RedirectNetworkSessionProvider {
    func createRedirectNetworkSession(delegate: RedirectNetworkSessionDelegate) -> NetworkSessionProtocol
}

class RedirectNetworkSession: NSObject, NetworkSessionProtocol {
    var timeout: TimeInterval {
        get {
            networkSession.timeout
        }
        set {
            networkSession.timeout = newValue
        }
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
    
    private lazy var networkSession: NetworkSessionProtocol = {
        URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
    } ()
    
    init(delegate: RedirectNetworkSessionDelegate?) {
        self.delegate = delegate
    }

    private weak var delegate: RedirectNetworkSessionDelegate?
}

extension RedirectNetworkSession: URLSessionDelegate, URLSessionTaskDelegate {
    internal func urlSession(_: URLSession,
                           task _: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void) {
        var deepLinkLocation: URL? = nil
        var campaignId: NSNumber? = nil
        var templateId: NSNumber? = nil
        var messageId: String? = nil
        
        deepLinkLocation = request.url
        
        guard let headerFields = response.allHeaderFields as? [String: String] else {
            delegate?.onRedirect(deepLinkLocation: deepLinkLocation, campaignId: campaignId, templateId: templateId, messageId: messageId)
            return
        }
        
        guard let url = response.url else {
            delegate?.onRedirect(deepLinkLocation: deepLinkLocation, campaignId: campaignId, templateId: templateId, messageId: messageId)
            return
        }
        
        for cookie in HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url) {
            if cookie.name == Const.CookieName.campaignId {
                campaignId = number(fromString: cookie.value)
            } else if cookie.name == Const.CookieName.templateId {
                templateId = number(fromString: cookie.value)
            } else if cookie.name == Const.CookieName.messageId {
                messageId = cookie.value
            }
        }
        
        delegate?.onRedirect(deepLinkLocation: deepLinkLocation, campaignId: campaignId, templateId: templateId, messageId: messageId)
        completionHandler(nil)
    }
    
    private func number(fromString str: String) -> NSNumber {
        if let intValue = Int(str) {
            return NSNumber(value: intValue)
        }
        
        return NSNumber(value: 0)
    }

}
