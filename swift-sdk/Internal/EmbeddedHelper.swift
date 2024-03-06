//
//  Copyright © 2023 Iterable. All rights reserved.
//
import UIKit

/// Utility Methods for embedded
/// All classes/structs are internal.
struct EmbeddedHelper {
    enum EmbeddedClickedUrl {
        case localResource(name: String) // applewebdata://abc-def/something => something
        case iterableCustomAction(name: String) // iterable://something => something
        case customAction(name: String) // action:something => something or itbl://something => something
        case regularUrl(URL) // protocol://something => protocol://something
    }

    static func parse(embeddedUrl url: URL) -> EmbeddedClickedUrl? {
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
        String(str.drop { $0 == "/" })
    }

    private static func dropScheme(urlString: String, scheme: String) -> String {
        let prefix = scheme + "://"
        return String(urlString.dropFirst(prefix.count))
    }
}
