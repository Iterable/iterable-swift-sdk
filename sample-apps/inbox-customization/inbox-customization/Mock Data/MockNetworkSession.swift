//
//  Created by Tapash Majumder on 1/14/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockNetworkSession: NetworkSessionProtocol {
    var urlPatternDataMapping: [String: Data?]?
    var url: URL?
    var request: URLRequest?
    var callback: ((Data?, URLResponse?, Error?) -> Void)?
    var requestCallback: ((URLRequest) -> Void)?
    
    var statusCode: Int
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
    
    convenience init(statusCode: Int, data: Data?, error: Error? = nil) {
        self.init(statusCode: statusCode, urlPatternDataMapping: [".*": data], error: error)
    }
    
    init(statusCode: Int, urlPatternDataMapping: [String: Data?]?, error: Error? = nil) {
        self.statusCode = statusCode
        self.urlPatternDataMapping = urlPatternDataMapping
        self.error = error
    }
    
    func makeRequest(_ request: URLRequest, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            self.request = request
            self.requestCallback?(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: self.statusCode, httpVersion: "HTTP/1.1", headerFields: [:])
            let data = self.data(for: request.url?.absoluteString)
            completionHandler(data, response, self.error)
            
            self.callback?(data, response, self.error)
        }
    }
    
    func makeDataRequest(with url: URL, completionHandler: @escaping NetworkSessionProtocol.CompletionHandler) {
        DispatchQueue.main.async {
            self.url = url
            let response = HTTPURLResponse(url: url, statusCode: self.statusCode, httpVersion: "HTTP/1.1", headerFields: [:])
            let data = self.data(for: url.absoluteString)
            completionHandler(data, response, self.error)
            
            self.callback?(data, response, self.error)
        }
    }
    
    func getRequestBody() -> [AnyHashable: Any] {
        return MockNetworkSession.json(fromData: request!.httpBody!)
    }
    
    static func json(fromData data: Data) -> [AnyHashable: Any] {
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
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

extension Dictionary where Key == AnyHashable {
    func toJsonData() -> Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
}
