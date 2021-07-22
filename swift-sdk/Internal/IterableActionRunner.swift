//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

/// handles opening of Urls

@available(iOSApplicationExtension, unavailable)
@objc protocol UrlOpenerProtocol: AnyObject {
    @objc func open(url: URL)
}

/// Default app opener. Defers to UIApplication open
@available(iOSApplicationExtension, unavailable)
class AppUrlOpener: UrlOpenerProtocol {
    public init() {}
    
    public func open(url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    ITBError("Could not open url: \(url)")
                }
            }
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

struct IterableActionRunner {
    // returns true if an action is performed either by us or by the calling app.
    @discardableResult
  @available(iOSApplicationExtension, unavailable)
    static func execute(action: IterableAction,
                        context: IterableActionContext,
                        urlHandler: UrlHandler? = nil,
                        customActionHandler: CustomActionHandler? = nil,
                        urlOpener: UrlOpenerProtocol? = nil) -> Bool {
        let handled = callExternalHandlers(action: action,
                                           from: context.source,
                                           urlHandler: urlHandler,
                                           customActionHandler: customActionHandler)
        
        if handled {
            return true
        } else {
            if case let .openUrl(url) = detectActionType(fromAction: action), shouldOpenUrl(url: url, from: context.source), let urlOpener = urlOpener {
                urlOpener.open(url: url)
                return true
            } else {
                return false
            }
        }
    }
    
    // MARK: - Private
    
    // return true if the action is handled by the calling app either by opening a url or performing a custom action.
    private static func callExternalHandlers(action: IterableAction,
                                             from _: IterableActionSource,
                                             urlHandler: UrlHandler? = nil,
                                             customActionHandler: CustomActionHandler? = nil) -> Bool {
        let actionType = detectActionType(fromAction: action)
        switch actionType {
        case .noop:
            return false
        case let .openUrl(url):
            if urlHandler?(url) == true {
                return true
            } else {
                return false
            }
        case let .customAction(type):
            if customActionHandler?(type) == true {
                return true
            } else {
                return false
            }
        }
    }
    
    private static func shouldOpenUrl(url: URL, from source: IterableActionSource) -> Bool {
        if source == .push || source == .inApp, let scheme = url.scheme, scheme == "http" || scheme == "https" {
            return true
        } else {
            return false
        }
    }
    
    private enum ActionType {
        case openUrl(URL)
        case customAction(String)
        case noop
    }
    
    // What type of action needs to be performed.
    private static func detectActionType(fromAction action: IterableAction) -> ActionType {
        if action.isOpenUrl() {
            if let urlString = action.data, let url = URL(string: urlString) {
                return .openUrl(url)
            } else {
                ITBError("Could not create url from action: \(action)")
                return .noop
            }
        } else {
            if IterableUtil.isNullOrEmpty(string: action.type) {
                return .noop
            } else {
                return .customAction(action.type)
            }
        }
    }
}
