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
    
    static func execute(action: IterableAction, from source: IterableActionSource, urlDelegate: IterableURLDelegate? = nil, customActionDelegate: IterableCustomActionDelegate? = nil) -> Result {
        let context = IterableActionContext(action: action, source: source)
        let inspectionResult = inspect(action: action)
        switch(inspectionResult) {
        case .noop:
            return .notHandled
        case .openUrl(let url):
            if urlDelegate?.handle(iterableURL: url, inContext: context) == true {
                return .openedUrl(url)
            } else {
                if shouldOpenUrl(url: url, from: source) {
                    return .openUrl(url)
                } else {
                    return .notHandled
                }
            }
        case .customAction:
            if let customActionDelegate = customActionDelegate {
                _ = customActionDelegate.handle(iterableCustomAction: action, inContext: context)
                return .performedCustomAction(action.type)
            } else {
                return .notHandled
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

