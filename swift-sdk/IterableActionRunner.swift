//
//  IterableActionRunner.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

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
                        urlDelegateHandler: ((URL) -> Bool)? = nil,
                        customActionDelegateHandler: ((String) -> Bool)? = nil) -> Result {
        let inspectionResult = inspect(action: action)
        switch(inspectionResult) {
        case .noop:
            return .notHandled
        case .openUrl(let url):
            if urlDelegateHandler?(url) == true {
                return .openedUrl(url)
            } else {
                if shouldOpenUrl(url: url, from: source) {
                    return .openUrl(url)
                } else {
                    return .notHandled
                }
            }
        case .customAction(let type):
            if customActionDelegateHandler?(type) == true {
                return .performedCustomAction(type)
            } else {
                return .notHandled
            }
        }
    }

    // Will the urlDelegate handle this url from this source?
    // It will return a closure for that
    static func handler(forUrlDelegate urlDelegate: IterableURLDelegate?, andAction action: IterableAction, from source: IterableActionSource) ->  (URL) -> Bool {
        return  { url in
            urlDelegate?.handle(iterableURL: url, inContext: IterableActionContext(action: action, source: source)) == true
        }
    }

    // Will the customActionDelegate handle this customaction from this source?
    // It will return a closure for that
    static func handler(forCustomActionDelegate customActionDelegate: IterableCustomActionDelegate?, andAction action: IterableAction, from source: IterableActionSource) ->  (String) -> Bool {
        return  { customAction in
            if let customActionDelegate = customActionDelegate {
                _ = customActionDelegate.handle(iterableCustomAction: action, inContext: IterableActionContext(action: action, source: source))
                return true
            } else {
                return false
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

