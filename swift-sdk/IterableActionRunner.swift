//
//  IterableActionRunner.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public typealias UrlHandler = (URL) -> Bool
public typealias CustomActionHandler = (String) -> Bool

/// IterableActionRunner implements this.
@objc public protocol ActionRunnerProtocol : class {
    func execute(action: IterableAction, from source: IterableActionSource) -> Bool
}

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

struct IterableActionRunner {
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
        let inspectionResult = inspect(action: action)
        switch(inspectionResult) {
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

    // converts from IterableURLDelegate to UrlHandler
    static func actionSourceToUrlHandler(fromUrlDelegate urlDelegate: IterableURLDelegate?) -> (IterableAction, IterableActionSource) -> UrlHandler {
        return { (action, source) in { (url) in
            return urlDelegate?.handle(iterableURL: url, inContext: IterableActionContext(action: action, source: source)) == true
            }
        }
    }
    
    // converts from IterableCustomActionDelegate to CustomActionHandler
    static func actionSourceToCustomActionHandler(fromCustomActionDelegate customActionDelegate: IterableCustomActionDelegate?) -> (IterableAction, IterableActionSource) -> CustomActionHandler {
        return { (action, source) in { (customActionName) in
                if let customActionDelegate = customActionDelegate {
                    let _ = customActionDelegate.handle(iterableCustomAction: action, inContext: IterableActionContext(action: action, source: source))
                    return true
                } else {
                    return false
                }
            }
        }
    }

    private static func shouldOpenUrl(url: URL, from source: IterableActionSource) -> Bool {
        if source == .push, let scheme = url.scheme, (scheme == "http" || scheme == "https") {
            return true
        } else {
            return false
        }
    }

    private enum InspectionResult {
        case openUrl(URL)
        case customAction(String)
        case noop
    }
    
    // What type of action needs to be performed.
    private static func inspect(action: IterableAction) -> InspectionResult {
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

