//
//  Created by Tapash Majumder on 7/24/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

typealias SendRequestValue = [AnyHashable: Any]

struct SendRequestError: Error {
    let reason: String?
    let data: Data?
    
    init(reason: String? = nil, data: Data? = nil) {
        self.reason = reason
        self.data = data
    }
    
    static func createErroredFuture<T>(reason: String? = nil) -> Future<T, SendRequestError> {
        return Promise<T, SendRequestError>(error: SendRequestError(reason: reason))
    }
}

extension SendRequestError: LocalizedError {
    var localizedDescription: String {
        return reason ?? ""
    }
}

protocol NetworkSessionProtocol {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler)
    func makeDataRequest(with url: URL, completionHandler: @escaping CompletionHandler)
}

extension URLSession: NetworkSessionProtocol {
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
}

struct NetworkHelper {
    static func getData(fromUrl url: URL, usingSession networkSession: NetworkSessionProtocol) -> Future<Data, Error> {
        let promise = Promise<Data, Error>()
        
        networkSession.makeDataRequest(with: url) { data, response, error in
            let result = createDataResultFromNetworkResponse(data: data, response: response, error: error)
            
            switch result {
            case let .success(value):
                DispatchQueue.main.async {
                    promise.resolve(with: value)
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    promise.reject(with: error)
                }
            }
        }
        
        return promise
    }
    
    static func sendRequest(_ request: URLRequest, usingSession networkSession: NetworkSessionProtocol) -> Future<SendRequestValue, SendRequestError> {
        #if NETWORK_DEBUG
            print()
            print("====================================================>")
            print("sending request: \(request)")
            if let headers = request.allHTTPHeaderFields {
                print("headers:")
                print(headers)
            }
            if let body = request.httpBody {
                if let dict = try? JSONSerialization.jsonObject(with: body, options: []) {
                    print("request body:")
                    print(dict)
                }
            }
            print("====================================================>")
            print()
        #endif
        
        let promise = Promise<SendRequestValue, SendRequestError>()
        
        networkSession.makeRequest(request) { data, response, error in
            let result = createResultFromNetworkResponse(data: data, response: response, error: error)
            
            switch result {
            case let .success(value):
                promise.resolve(with: value)
            case let .failure(error):
                promise.reject(with: error)
            }
        }
        
        return promise
    }
    
    static func createResultFromNetworkResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<SendRequestValue, SendRequestError> {
        if let error = error {
            return .failure(SendRequestError(reason: "\(error.localizedDescription)", data: data))
        }
        
        guard let response = response as? HTTPURLResponse else {
            return .failure(SendRequestError(reason: "No response", data: nil))
        }
        
        let responseCode = response.statusCode
        
        let json: Any?
        var jsonError: Error?
        
        if let data = data, data.count > 0 {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                jsonError = error
                json = nil
            }
        } else {
            json = nil
        }
        
        if responseCode == 401 {
            return .failure(SendRequestError(reason: "Invalid API Key", data: data))
        } else if responseCode >= 400 {
            var reason = "Invalid Request"
            if let jsonDict = json as? [AnyHashable: Any], let msgFromDict = jsonDict["msg"] as? String {
                reason = msgFromDict
            } else if responseCode >= 500 {
                reason = "Internal Server Error"
            }
            
            return .failure(SendRequestError(reason: reason, data: data))
        } else if responseCode == 200 {
            if let data = data, data.count > 0 {
                if let jsonError = jsonError {
                    var reason = "Could not parse json, error: \(jsonError.localizedDescription)"
                    if let stringValue = String(data: data, encoding: .utf8) {
                        reason = "Could not parse json: \(stringValue), error: \(jsonError.localizedDescription)"
                    }
                    
                    return .failure(SendRequestError(reason: reason, data: data))
                } else if let json = json as? [AnyHashable: Any] {
                    return .success(json)
                } else {
                    return .failure(SendRequestError(reason: "Response is not a dictionary", data: data))
                }
            } else {
                return .failure(SendRequestError(reason: "No data received", data: data))
            }
        } else {
            return .failure(SendRequestError(reason: "Received non-200 response: \(responseCode)", data: data))
        }
    }
    
    static func createDataResultFromNetworkResponse(data: Data?, response _: URLResponse?, error: Error?) -> Result<Data, SendRequestError> {
        if let error = error {
            return .failure(SendRequestError(reason: "\(error.localizedDescription)"))
        }
        
        guard let data = data else {
            return .failure(SendRequestError(reason: "No data"))
        }
        
        return .success(data)
    }
}
