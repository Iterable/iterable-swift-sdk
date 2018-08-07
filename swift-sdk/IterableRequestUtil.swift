//
//  IterableRequestUtil.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 8/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct IterableRequestUtil {
    static func createPostRequest(forApiEndPoint apiEndPoint:String, path: String, args: [String : String]? = nil, body: [AnyHashable : Any]? = nil) -> URLRequest? {
        guard let url = getUrlComponents(forApiEndPoint: apiEndPoint, path:path, args: args)?.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = ITBL_KEY_POST
        if let body = body {
            if let bodyString = dictToJson(body) {
                request.httpBody = bodyString.data(using: .utf8)
            }
        }
        return request
    }

    static func createGetRequest(forApiEndPoint apiEndPoint:String, path: String, args: [String : String]? = nil) -> URLRequest? {
        guard let url = getUrlComponents(forApiEndPoint: apiEndPoint, path: path, args: args)?.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = ITBL_KEY_GET
        return request
    }

    private static func getUrlComponents(forApiEndPoint apiEndPoint:String, path: String, args: [String : String]? = nil) -> URLComponents? {
        let endPointCombined = pathCombine(path1: apiEndPoint, path2: path)
        guard var components = URLComponents(string: "\(endPointCombined)") else {
            return nil
        }

        if let args = args {
            components.queryItems = args.map{ URLQueryItem(name: $0.key, value: $0.value) }
        }

        return components
    }
    
    static func dictToJson(_ dict: [AnyHashable : Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch (let error) {
            ITBError("dictToJson failed: \(error.localizedDescription)")
            return nil
        }
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
        if !result.isEmpty && !path2.isEmpty && !path2.hasPrefix("/") {
            result.append("/")
        }
        result.append(path2)
        return result    }
}
