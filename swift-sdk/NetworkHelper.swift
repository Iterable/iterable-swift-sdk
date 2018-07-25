//
//
//  Created by Tapash Majumder on 7/24/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

typealias SendRequestValue = [AnyHashable : Any]

struct SendRequestErrorType {
    let errorMessage: String?
    let data: Data?
}

enum Result<Value, ErrorType> {
    case value(Value)
    case error(ErrorType)
}


class Promise<Value, ErrorType> {
    private lazy var callbacks = [(Result<Value, ErrorType>) -> Void]()
    
    func observe(with callback: @escaping (Result<Value, ErrorType>) -> Void) {
        callbacks.append(callback)
    }
    
    func resolve(with value: Value) {
        callbacks.forEach { (callback) in
            callback(.value(value))
        }
    }
    
    func reject(with error: ErrorType) {
        callbacks.forEach { (callback) in
            callback(.error(error))
        }
    }
}

protocol NetworkSessionProtocol {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func provideData(with request: URLRequest, completionHandler: @escaping CompletionHandler)
}

extension URLSession : NetworkSessionProtocol {
    func provideData(with request: URLRequest, completionHandler: @escaping CompletionHandler) {
        let task = dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }
        task.resume()
    }
}

struct NetworkHelper {
    static func sendRequest(_ request: URLRequest, usingSession networkSession: NetworkSessionProtocol) -> Promise<SendRequestValue, SendRequestErrorType>  {
        let result = Promise<SendRequestValue, SendRequestErrorType>()
        
        networkSession.provideData(with: request) { (data, response, error) in
            if let error = error {
                return result.reject(with: SendRequestErrorType(errorMessage: "\(error.localizedDescription)", data: data))
            }
            guard let response = response as? HTTPURLResponse else {
                return result.reject(with: SendRequestErrorType(errorMessage: "No response", data: nil))
            }
            
            let responseCode = response.statusCode
            
            let json: Any?
            var jsonError: Error? = nil
            
            if let data = data, data.count > 0 {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: [])
                } catch let error {
                    jsonError = error
                    json = nil
                }
            } else {
                json = nil
            }
            
            if responseCode == 401 {
                return result.reject(with: SendRequestErrorType(errorMessage: "Invalid API Key", data: data))
            } else if responseCode >= 400 {
                var errorMessage = "Invalid Request"
                if let jsonDict = json as? [AnyHashable : Any], let msgFromDict = jsonDict["msg"] as? String {
                    errorMessage = msgFromDict
                } else if responseCode >= 500 {
                    errorMessage = "Internal Server Error"
                }
                return result.reject(with: SendRequestErrorType(errorMessage: errorMessage, data: data))
            } else if responseCode == 200 {
                if let data = data, data.count > 0 {
                    if let jsonError = jsonError {
                        var reason = "Could not parse json, error: \(jsonError.localizedDescription)"
                        if let stringValue = String(data: data, encoding: .utf8) {
                            reason = "Could not parse json: \(stringValue), error: \(jsonError.localizedDescription)"
                        }
                        return result.reject(with: SendRequestErrorType(errorMessage: reason, data: data))
                    } else if let json = json as? [AnyHashable : Any] {
                        return result.resolve(with: json)
                    } else {
                        return result.reject(with: SendRequestErrorType(errorMessage: "Response is not a dictionary", data: data))
                    }
                } else {
                    return result.reject(with: SendRequestErrorType(errorMessage: "No data received", data: data))
                }
            } else {
                return result.reject(with: SendRequestErrorType(errorMessage: "Received non-200 response: \(responseCode)", data: data))
            }
        }
        
        return result
    }
}
