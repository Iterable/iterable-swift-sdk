//
//
//  Created by Tapash Majumder on 7/24/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

typealias SendRequestValue = [AnyHashable : Any]

struct SendRequestError : Error {
    let errorMessage: String?
    let data: Data?
    
    init(errorMessage: String? = nil, data: Data? = nil) {
        self.errorMessage = errorMessage
        self.data = data
    }
    
    static func createFailedFuture(reason: String? = nil) -> Future<SendRequestValue, SendRequestError> {
        return Promise<SendRequestValue, SendRequestError>(error: SendRequestError(errorMessage: reason))
    }
}

extension SendRequestError : LocalizedError {
    var localizedDescription: String {
        return errorMessage ?? ""
    }
}

enum Result<Value, ErrorType> {
    case value(Value)
    case error(ErrorType)
}

// This has only two public methods
// either there is a success with result
// or there is a failure with error
// There is no way to set value a result in this class.
class Future<Value, ErrorType> {
    var onSuccess: ((Value) -> Void)? = nil {
        didSet { result.map(report) }
    }
    
    var onFailure : ((ErrorType) -> Void)? = nil {
        didSet { result.map(report) }
    }
    
    fileprivate var result: Result<Value, ErrorType>? {
        // Observe whenever a result is assigned, and report it
        didSet { result.map(report) }
    }
    
    // Report success or error based on result
    private func report(result: Result<Value, ErrorType>) {
        switch result {
        case .value(let value):
            onSuccess?(value)
            break
        case .error(let error):
            onFailure?(error)
            break
        }
    }
}

extension Future {
    func flatMap<NextValue>(_ closure: @escaping (Value) -> Future<NextValue, ErrorType>) -> Future<NextValue, ErrorType> {
        let promise = Promise<NextValue, ErrorType>()
        
        onSuccess = { value in
            let future = closure(value)
            
            future.onSuccess = { futureValue in
                promise.resolve(with: futureValue)
            }
            
            future.onFailure = { futureError in
                promise.reject(with: futureError)
            }
        }
        
        onFailure = { error in
            promise.reject(with: error)
        }
        
        return promise
    }
    
    func map<NextValue>(_ closure: @escaping (Value) -> NextValue) -> Future<NextValue, ErrorType> {
        let promise = Promise<NextValue, ErrorType>()
        
        onSuccess = { value in
            let nextValue = closure(value)
            promise.resolve(with: nextValue)
        }
        
        onFailure = { error in
            promise.reject(with: error)
        }
        
        return promise
    }
}


// This class takes the responsibility of setting value for Future
class Promise<Value, ErrorType> : Future<Value, ErrorType> {
    init(value: Value? = nil) {
        super.init()
        result = value.map(Result.value)
    }
    
    init(error: ErrorType) {
        super.init()
        result = Result.error(error)
    }

    func resolve(with value: Value) {
        result = .value(value)
    }
    
    func reject(with error: ErrorType) {
        result = .error(error)
    }
}

protocol NetworkSessionProtocol {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler)
}

extension URLSession : NetworkSessionProtocol {
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler) {
        let task = dataTask(with: request) { (data, response, error) in
            completionHandler(data, response, error)
        }
        task.resume()
    }
}

struct NetworkHelper {
    static func sendRequest(_ request: URLRequest, usingSession networkSession: NetworkSessionProtocol) -> Future<SendRequestValue, SendRequestError>  {
        let promise = Promise<SendRequestValue, SendRequestError>()
        
        networkSession.makeRequest(request) { (data, response, error) in
            let result = createResultFromNetworkResponse(data: data, response: response, error: error)
            switch (result) {
            case .value(let value):
                promise.resolve(with: value)
            case .error(let error):
                promise.reject(with: error)
            }
        }
            
        return promise
    }
    
    static func createResultFromNetworkResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<SendRequestValue, SendRequestError> {
        if let error = error {
            return .error(SendRequestError(errorMessage: "\(error.localizedDescription)", data: data))
        }
        guard let response = response as? HTTPURLResponse else {
            return .error(SendRequestError(errorMessage: "No response", data: nil))
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
            return .error(SendRequestError(errorMessage: "Invalid API Key", data: data))
        } else if responseCode >= 400 {
            var errorMessage = "Invalid Request"
            if let jsonDict = json as? [AnyHashable : Any], let msgFromDict = jsonDict["msg"] as? String {
                errorMessage = msgFromDict
            } else if responseCode >= 500 {
                errorMessage = "Internal Server Error"
            }
            return .error(SendRequestError(errorMessage: errorMessage, data: data))
        } else if responseCode == 200 {
            if let data = data, data.count > 0 {
                if let jsonError = jsonError {
                    var reason = "Could not parse json, error: \(jsonError.localizedDescription)"
                    if let stringValue = String(data: data, encoding: .utf8) {
                        reason = "Could not parse json: \(stringValue), error: \(jsonError.localizedDescription)"
                    }
                    return .error(SendRequestError(errorMessage: reason, data: data))
                } else if let json = json as? [AnyHashable : Any] {
                    return .value(json)
                } else {
                    return .error(SendRequestError(errorMessage: "Response is not a dictionary", data: data))
                }
            } else {
                return .error(SendRequestError(errorMessage: "No data received", data: data))
            }
        } else {
            return .error(SendRequestError(errorMessage: "Received non-200 response: \(responseCode)", data: data))
        }
    }
}
