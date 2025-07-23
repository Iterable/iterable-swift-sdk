//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

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
                  data: MockNetworkSession.defaultData,
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

        let block = {[weak self] in
            self?.requests.append(request)
            self?.requestCallback?(request)
            if let mockResponse = mockResponse {
                let response = mockResponse.toUrlResponse(url: request.url!)
                completionHandler(mockResponse.data, response, mockResponse.error)
                self?.callback?(mockResponse.data, response, mockResponse.error)
            } else {
                let response = Self.defaultURLResponse(forUrl: request.url!)
                completionHandler(Self.defaultData, response, nil)
                self?.callback?(Self.defaultData, response, nil)
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
    private static let defaultData = Dictionary<AnyHashable, Any>().toJsonData()
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
            completionHandler(try! JSONSerialization.data(withJSONObject: Dictionary<AnyHashable, Any>(), options: []), response, error)
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
            let error = NSError(domain: NSURLErrorDomain, code: -1009, userInfo: nil)
            completionHandler(try! JSONSerialization.data(withJSONObject: Dictionary<AnyHashable, Any>(), options: []), response, error)
        }
    }
    
    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        fatalError("Not implemented")
    }
}
