//
//  Created by David Truong on 9/14/16.
//  Ported to Swift by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//
// Utility Methods for in-app
// All classes/structs are internal.

import UIKit

// This is Internal Struct, no public methods
struct InAppHelper {
    static func getInAppMessagesFromServer(apiClient: ApiClientProtocol, number: Int) -> Future<[IterableInAppMessage], SendRequestError> {
        return apiClient.getInAppMessages(NSNumber(value: number)).map {
            InAppMessageParser.parse(payload: $0).compactMap { parseResult in
                process(parseResult: parseResult, apiClient: apiClient)
            }
        }
    }
    
    enum InAppClickedUrl {
        case localResource(name: String) // applewebdata://abc-def/something => something
        case iterableCustomAction(name: String) // iterable://something => something
        case customAction(name: String) // action:something => something or itbl://something => something
        case regularUrl(URL) // https://something => https://something
    }
    
    static func parse(inAppUrl url: URL) -> InAppClickedUrl? {
        guard let scheme = UrlScheme.from(url: url) else {
            ITBError("Request url contains an invalid scheme: \(url)")
            return nil
        }
        
        switch scheme {
        case .applewebdata:
            ITBError("Request url contains an invalid scheme: \(url)")
            guard let urlPath = getUrlPath(url: url) else {
                return nil
            }
            return .localResource(name: urlPath)
        case .iterable:
            return .iterableCustomAction(name: dropScheme(urlString: url.absoluteString, scheme: scheme.rawValue))
        case .action, .itbl:
            return .customAction(name: dropScheme(urlString: url.absoluteString, scheme: scheme.rawValue))
        case .other:
            return .regularUrl(url)
        }
    }
    
    private enum UrlScheme: String {
        case applewebdata
        case iterable
        case action
        case itbl // this is for backward compatibility and should be handled just like action://
        case other
        
        fileprivate static func from(url: URL) -> UrlScheme? {
            guard let name = url.scheme else {
                return nil
            }
            
            if let scheme = UrlScheme(rawValue: name.lowercased()) {
                return scheme
            } else {
                return .other
            }
        }
    }
    
    // returns everything other than scheme, hostname and leading slashes
    // so scheme://host/path#something => path#something
    private static func getUrlPath(url: URL) -> String? {
        guard let host = url.host else {
            return nil
        }
        
        let urlArray = url.absoluteString.components(separatedBy: host)
        guard urlArray.count > 1 else {
            return nil
        }
        
        let urlPath = urlArray[1]
        return dropLeadingSlashes(str: urlPath)
    }
    
    private static func dropLeadingSlashes(str: String) -> String {
        return String(str.drop { $0 == "/" })
    }
    
    private static func dropScheme(urlString: String, scheme: String) -> String {
        let prefix = scheme + "://"
        return String(urlString.dropFirst(prefix.count))
    }
    
    // process each parseResult and consumes failed message, if messageId is present
    private static func process(parseResult: Result<IterableInAppMessage, InAppMessageParser.ParseError>, apiClient: ApiClientProtocol) -> IterableInAppMessage? {
        switch parseResult {
        case let .failure(parseError):
            switch parseError {
            case let .parseFailed(reason: reason, messageId: messageId):
                ITBError(reason)
                if let messageId = messageId {
                    apiClient.inAppConsume(messageId: messageId)
                }
                return nil
            }
        case let .success(val):
            return val
        }
    }
}
