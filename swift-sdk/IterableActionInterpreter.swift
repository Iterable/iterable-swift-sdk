//
//
//  Created by Tapash Majumder on 6/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public typealias UrlHandler = (URL) -> Bool
public typealias CustomActionHandler = (String) -> Bool

/// handles opening of Urls
@objc public protocol UrlOpenerProtocol : class {
    @objc func open(url: URL)
}

/// Default app opener. Defers to UIApplication open
class AppUrlOpener : UrlOpenerProtocol {
    func open(url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { (success) in
                if !success {
                    ITBError("Could not open url: \(url)")
                }
            }
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

struct IterableActionInterpreter {
    enum Result {
        case openUrl(URL)
        case openedUrl(URL)
        case performedCustomAction(String)
        case notHandled
    }

    static func execute(action: IterableAction,
                        from source: IterableActionSource,
                        urlHandler: UrlHandler? = nil,
                        customActionHandler: CustomActionHandler? = nil) -> Result {
        let actionType = detectActionType(fromAction: action)
        switch(actionType) {
        case .noop:
            return .notHandled
        case .openUrl(let url):
            if urlHandler?(url) == true {
                return .openedUrl(url)
            } else {
                if shouldOpenUrl(url: url, from: source) {
                    return .openUrl(url)
                } else {
                    return .notHandled
                }
            }
        case .customAction(let type):
            if customActionHandler?(type) == true {
                return .performedCustomAction(type)
            } else {
                return .notHandled
            }
        }
    }

    // MARK: Private
    private static func shouldOpenUrl(url: URL, from source: IterableActionSource) -> Bool {
        if source == .push, let scheme = url.scheme, (scheme == "http" || scheme == "https") {
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

    // MARK: Helper Utility Functions
    // converts from IterableURLDelegate to UrlHandler
    static func urlHandler(fromUrlDelegate urlDelegate: IterableURLDelegate?, inContext context: IterableActionContext) -> UrlHandler {
        return { url in
            urlDelegate?.handle(iterableURL: url, inContext: context) == true
        }
    }
    
    // it will partially bind urlDelegate and return a mapping from IterableActionContext to UrlHandler
    static func contextToUrlHandler(fromUrlDelegate urlDelegate: IterableURLDelegate?) -> (IterableActionContext) -> UrlHandler {
        return IterableUtil.curry(urlHandler(fromUrlDelegate: inContext:))(urlDelegate)
    }
    
    // converts from IterableCustomActionDelegate to CustomActionHandler
    static func customActionHandler(fromCustomActionDelegate customActionDelegate: IterableCustomActionDelegate?, inContext context: IterableActionContext) -> CustomActionHandler {
        return { customActionName in
            if let customActionDelegate = customActionDelegate {
                let _ = customActionDelegate.handle(iterableCustomAction: context.action, inContext: context)
                return true
            } else {
                return false
            }
        }
    }
    
    // it will partially bind customActionDelegate and return a mapping from IterableActionContext to CustomActionHandler
    static func contextToCustomActionHandler(fromCustomActionDelegate customActionDelegate: IterableCustomActionDelegate?) -> (IterableActionContext) -> CustomActionHandler {
        return IterableUtil.curry(customActionHandler(fromCustomActionDelegate:inContext:))(customActionDelegate)
    }
    
}

