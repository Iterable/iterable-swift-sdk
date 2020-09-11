//
//  Created by Tapash Majumder on 7/24/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

typealias SendRequestValue = [AnyHashable: Any]

struct SendRequestError: Error {
    let reason: String?
    let data: Data?
    let httpStatusCode: Int?
    let iterableCode: String?
    let originalError: Error?
    
    init(reason: String? = nil,
         data: Data? = nil,
         httpStatusCode: Int? = nil,
         iterableCode: String? = nil,
         originalError: Error? = nil) {
        self.reason = reason
        self.data = data
        self.httpStatusCode = httpStatusCode
        self.iterableCode = iterableCode
        self.originalError = originalError
    }
    
    static func createErroredFuture<T>(reason: String? = nil) -> Future<T, SendRequestError> {
        Promise<T, SendRequestError>(error: SendRequestError(reason: reason))
    }
    
    static func from(error: Error) -> SendRequestError {
        SendRequestError(reason: error.localizedDescription)
    }
    
    static func from(networkError: NetworkError,
                     reason: String? = nil,
                     iterableCode: String? = nil) -> SendRequestError {
        SendRequestError(reason: reason ?? networkError.reason,
                         data: networkError.data,
                         httpStatusCode: networkError.httpStatusCode,
                         iterableCode: iterableCode,
                         originalError: networkError.originalError)
    }
}

extension SendRequestError: LocalizedError {
    var errorDescription: String? {
        reason
    }
}

struct NetworkError: Error {
    let reason: String?
    let data: Data?
    let httpStatusCode: Int?
    let originalError: Error?
    
    init(reason: String? = nil,
         data: Data? = nil,
         httpStatusCode: Int? = nil,
         originalError: Error? = nil) {
        self.reason = reason
        self.data = data
        self.httpStatusCode = httpStatusCode
        self.originalError = originalError
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        reason
    }
}

protocol DataTaskProtocol {
    var state: URLSessionDataTask.State { get }
    func resume()
    func cancel()
}

extension URLSessionDataTask: DataTaskProtocol {}

protocol NetworkSessionProtocol {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    func makeRequest(_ request: URLRequest, completionHandler: @escaping CompletionHandler)
    func makeDataRequest(with url: URL, completionHandler: @escaping CompletionHandler)
    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol
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

    func createDataTask(with url: URL, completionHandler: @escaping CompletionHandler) -> DataTaskProtocol {
        dataTask(with: url, completionHandler: completionHandler)
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
    
    static func sendRequest<T>(_ request: URLRequest,
                               converter: @escaping (Data) throws -> T?,
                               usingSession networkSession: NetworkSessionProtocol) -> Future<T, NetworkError> {
        #if NETWORK_DEBUG
        let requestId = IterableUtil.generateUUID()
        print()
        print("====================================================>")
        print("sending request: \(request)")
        print("requestId: \(requestId)")
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
        
        let promise = Promise<T, NetworkError>()
        
        networkSession.makeRequest(request) { data, response, error in
            let result = createResultFromNetworkResponse(data: data,
                                                         converter: converter,
                                                         response: response,
                                                         error: error)
            
            switch result {
            case let .success(value):
                #if NETWORK_DEBUG
                print("request with requestId: \(requestId) successfully sent")
                #endif
                promise.resolve(with: value)
            case let .failure(error):
                #if NETWORK_DEBUG
                print("request with id: \(requestId) errored")
                #endif
                promise.reject(with: error)
            }
        }
        
        return promise
    }
    
    static func sendRequest(_ request: URLRequest,
                            usingSession networkSession: NetworkSessionProtocol) -> Future<SendRequestValue, SendRequestError> {
        let converter: (Data) throws -> SendRequestValue? = { data in
            try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
        }
        
        return sendRequest(request,
                           converter: converter,
                           usingSession: networkSession)
            .mapFailure(convertNetworkErrorToSendRequestError(_:))
    }
    
    private static func createResultFromNetworkResponse<T>(data: Data?,
                                                   converter: (Data) throws -> T?,
                                                   response: URLResponse?,
                                                   error: Error?) -> Result<T, NetworkError> {
        if let error = error {
            return .failure(NetworkError(reason: "\(error.localizedDescription)", data: data, originalError: error))
        }
        
        guard let response = response as? HTTPURLResponse else {
            return .failure(NetworkError(reason: "No response", data: nil))
        }
        
        let httpStatusCode = response.statusCode
        
        if httpStatusCode >= 500 {
            return .failure(NetworkError(reason: "Internal Server Error", data: data, httpStatusCode: httpStatusCode))
        } else if httpStatusCode >= 400 {
            return .failure(NetworkError(reason: "Invalid Request", data: data, httpStatusCode: httpStatusCode))
        } else if httpStatusCode == 200 {
            if let data = data, data.count > 0 {
                return convertData(data: data, converter: converter)
            } else {
                return .failure(NetworkError(reason: "No data received", data: data, httpStatusCode: httpStatusCode))
            }
        } else {
            return .failure(NetworkError(reason: "Received non-200 response: \(httpStatusCode)", data: data, httpStatusCode: httpStatusCode))
        }
    }
    
    private static func convertData<T>(data: Data, converter: (Data) throws -> T?) -> Result<T, NetworkError> {
        do {
            if let responseObj = try converter(data) {
                return .success(responseObj)
            } else {
                return .failure(NetworkError(reason: "Wrong response type", data: data, httpStatusCode: 200))
            }
        } catch {
            var reason = "Could not convert data, error: \(error.localizedDescription)"
            if let stringValue = String(data: data, encoding: .utf8) {
                reason = "Could not convert data: \(stringValue), error: \(error.localizedDescription)"
            }
            return .failure(NetworkError(reason: reason, data: data, httpStatusCode: 200))
        }
    }
    
    private static func createDataResultFromNetworkResponse(data: Data?,
                                                    response _: URLResponse?,
                                                    error: Error?) -> Result<Data, SendRequestError> {
        if let error = error {
            return .failure(SendRequestError(reason: "\(error.localizedDescription)"))
        }
        
        guard let data = data else {
            return .failure(SendRequestError(reason: "No data"))
        }
        
        return .success(data)
    }
    
    private static func convertNetworkErrorToSendRequestError(_ networkError: NetworkError) -> SendRequestError {
        guard let httpStatusCode = networkError.httpStatusCode else {
            return SendRequestError.from(networkError: networkError)
        }
        
        let json: Any?
        if let data = networkError.data, data.count > 0 {
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                json = nil
            }
        } else {
            json = nil
        }
        
        if httpStatusCode == 401 {
            var iterableCode: String? = nil
            if let jsonDict = json as? [AnyHashable: Any] {
                iterableCode = jsonDict[JsonKey.Response.iterableCode] as? String
            }
            
            return SendRequestError.from(networkError: networkError, reason: "Invalid API Key", iterableCode: iterableCode)
        } else if httpStatusCode >= 400 {
            var reason = "Invalid Request"
            if let jsonDict = json as? [AnyHashable: Any], let msgFromDict = jsonDict["msg"] as? String {
                reason = msgFromDict
            } else if httpStatusCode >= 500 {
                reason = "Internal Server Error"
            }
            
            return SendRequestError.from(networkError: networkError, reason: reason)
        }
        
        return SendRequestError.from(networkError: networkError)
    }
}
