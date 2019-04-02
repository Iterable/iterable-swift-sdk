//
//  Created by David Truong on 9/14/16.
//  Ported to Swift by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//
// Utility Methods for inApp
// All classes/structs are internal.

import UIKit


// This is Internal Struct, no public methods
struct InAppHelper {
    static func getInAppMessagesFromServer(internalApi: IterableAPIInternal, number: Int) -> Future<[IterableInAppMessage]> {
        return internalApi.getInAppMessages(NSNumber(value: number)).map {
            return InAppMessageParser.parse(payload: $0).compactMap { parseResult in
                process(parseResult: parseResult, internalApi: internalApi)
            }
        }
    }
    
    enum InAppClickedUrl {
        case localResource(name: String) // applewebdata://abc-def/something => something
        case iterableCustomAction(name: String) // itbl://something => something
        case customAction(name: String) // action:something => something
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
        case .itbl:
            return .iterableCustomAction(name: dropScheme(urlString: url.absoluteString, scheme: UrlScheme.itbl.rawValue))
        case .action:
            return .customAction(name: dropScheme(urlString: url.absoluteString, scheme: UrlScheme.action.rawValue))
        case .other:
            return .regularUrl(url)
        }
    }
    
    // Given the clicked url in inApp get the callbackUrl and destinationUrl
    static func getCallbackAndDestinationUrl(url: URL) -> (callbackUrl: String, destinationUrl: String)? {
        if url.scheme == UrlScheme.applewebdata.rawValue {
            // Since we are calling loadHTMLString with a nil baseUrl, any request url without a valid scheme get treated as a local resource.
            // Url looks like applewebdata://abc-def/something
            // Removes the extra applewebdata scheme/host data that is appended to the original url.
            // So in this case (callback = something, destination = something)
            // Warn the client that the request url does not contain a valid scheme
            ITBError("Request url contains an invalid scheme: \(url)")
            
            guard let urlPath = getUrlPath(url: url) else {
                return nil
            }
            return (callbackUrl: urlPath, destinationUrl: urlPath)
        } else if url.scheme == UrlScheme.itbl.rawValue {
            // itbl://something => (callback = something, destination = itbl://something)
            let callbackUrl = dropScheme(urlString: url.absoluteString, scheme: UrlScheme.itbl.rawValue)
            return (callbackUrl: callbackUrl, destinationUrl: url.absoluteString)
        } else {
            // http, https etc, return unchanged
            return (url.absoluteString, url.absoluteString)
        }
    }
    
    private enum UrlScheme : String {
        case applewebdata = "applewebdata"
        case itbl = "itbl"
        case action = "action"
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
        return String(str.drop { $0 == "/"})
    }
    
    private static func dropScheme(urlString: String, scheme: String) -> String {
        let prefix = scheme + "://"
        return String(urlString.dropFirst(prefix.count))
    }

    // process each parseResult and consumes failed message, if messageId is present
    private static func process(parseResult: IterableResult<IterableInAppMessage, InAppMessageParser.ParseError>, internalApi: IterableAPIInternal) -> IterableInAppMessage? {
        switch parseResult {
        case .failure(let parseError):
            switch (parseError) {
            case .parseFailed(reason: let reason, messageId: let messageId):
                ITBError(reason)
                if let messageId = messageId {
                    internalApi.inAppConsume(messageId)
                }
                return nil
            }
        case .success(let val):
            return val
        }
    }
}
