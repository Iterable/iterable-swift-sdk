//
//  IterableRequestUtil.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 8/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct IterableRequestUtil {
    static func createPostRequest(forApiEndPoint apiEndPoint: String, path: String, apiKey: String, args: [String: String]? = nil, body: [AnyHashable: Any]? = nil) -> URLRequest? {
        return createPostRequest(forApiEndPoint: apiEndPoint, path: path, apiKey: apiKey, args: args, body: dictToJsonData(body))
    }
    
    static func createPostRequest<T: Encodable>(forApiEndPoint apiEndPoint: String, path: String, apiKey: String, args: [String: String]? = nil, body: T) -> URLRequest? {
        return createPostRequest(forApiEndPoint: apiEndPoint, path: path, apiKey: apiKey, args: args, body: try? JSONEncoder().encode(body))
    }
    
    static func createPostRequest(forApiEndPoint apiEndPoint: String, path: String, apiKey: String, args: [String: String]? = nil, body: Data? = nil) -> URLRequest? {
        guard let url = getUrlComponents(forApiEndPoint: apiEndPoint, path: path, args: args)?.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(.ITBL_PLATFORM_IOS, forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_PLATFORM)
        request.setValue(IterableAPI.sdkVersion, forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_VERSION)
        request.setValue(apiKey, forHTTPHeaderField: AnyHashable.ITBL_HEADER_API_KEY)
        request.httpMethod = .ITBL_KEY_POST
        request.httpBody = body
        
        return request
    }
    
    static func createGetRequest(forApiEndPoint apiEndPoint: String, path: String, args: [String: String]? = nil) -> URLRequest? {
        guard let url = getUrlComponents(forApiEndPoint: apiEndPoint, path: path, args: args)?.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue(.ITBL_PLATFORM_IOS, forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_PLATFORM)
        request.setValue(IterableAPI.sdkVersion, forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_VERSION)
        request.httpMethod = .ITBL_KEY_GET
        return request
    }
    
    private static func getUrlComponents(forApiEndPoint apiEndPoint: String, path: String, args: [String: String]? = nil) -> URLComponents? {
        let endPointCombined = pathCombine(path1: apiEndPoint, path2: path)
        
        guard var components = URLComponents(string: "\(endPointCombined)") else {
            return nil
        }
        
        if let args = args {
            components.queryItems = args.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        
        return components
    }
    
    static func dictToJsonData(_ dict: [AnyHashable: Any]?) -> Data? {
        guard let dict = dict else {
            return nil
        }
        
        return try? JSONSerialization.data(withJSONObject: dict, options: [])
    }
    
    static func pathCombine(paths: [String]) -> String {
        return paths.reduce("", pathCombine)
    }
    
    private static func pathCombine(path1: String, path2: String) -> String {
        var result = path1
        if result.hasSuffix("/") {
            result.removeLast()
        }
        // result has no ending slashes, add one if needed
        if !result.isEmpty, !path2.isEmpty, !path2.hasPrefix("/") {
            result.append("/")
        }
        result.append(path2)
        return result
    }
}
