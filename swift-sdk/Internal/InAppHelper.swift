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
    static func getInAppMessagesFromServer(internalApi: IterableAPIInternal, number: Int) -> Future<[IterableMessageProtocol]> {
        return internalApi.getInAppMessages(NSNumber(value: number)).map {
            InAppMessageParser.inAppMessages(fromPayload: $0, internalApi: internalApi)
        }
    }
    
    // Given the clicked url in inApp get the callbackUrl and destinationUrl
    static func getCallbackAndDestinationUrl(url: URL) -> (callbackUrl: String, destinationUrl: String)? {
        if url.scheme == UrlScheme.custom.rawValue {
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
        case custom = "applewebdata"
        case itbl = "itbl"
        case other
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
}
