//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

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
                                                            error: Error?) -> Result<Data, NetworkError> {
        if let error = error {
            return .failure(NetworkError(reason: "\(error.localizedDescription)"))
        }
        
        guard let data = data else {
            return .failure(NetworkError(reason: "No data"))
        }
        
        return .success(data)
    }
}
