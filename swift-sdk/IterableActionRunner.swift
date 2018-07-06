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

class IterableActionRunner : NSObject, ActionRunnerProtocol {
    private let urlDelegate: IterableURLDelegate?
    private let customActionDelegate: IterableCustomActionDelegate?
    private let urlOpener: UrlOpenerProtocol
    
    init(urlDelegate: IterableURLDelegate?, customActionDelegate: IterableCustomActionDelegate?, urlOpener: UrlOpenerProtocol) {
        self.urlDelegate = urlDelegate
        self.customActionDelegate = customActionDelegate
        self.urlOpener = urlOpener
    }
    
    func execute(action: IterableAction, from source: IterableActionSource) -> Bool {
        let context = IterableActionContext(action: action, source: source)
        
        if action.isOfType(IterableAction.actionTypeOpenUrl) {
            if let urlString = action.data, let url = URL(string: urlString) {
                return open(url: url, inContext: context)
            } else {
                ITBError("Could not create url from action: \(action)")
                return false
            }
        } else {
            return callCustomActionIfSpecified(action: action, inContext: context)
        }
    }
    
    private func open(url: URL, inContext context: IterableActionContext) -> Bool {
        if urlDelegate?.handle(iterableURL:url, inContext: context) == true {
            return true
        }

        guard context.source == .push else {
            // only open urls for push, leave others to delegate
            return false
        }
        
        if let scheme = url.scheme, scheme == "http" || scheme == "https" {
            urlOpener.open(url: url)
            return true
        } else {
            return false
        }
    }
    
    private func callCustomActionIfSpecified(action: IterableAction, inContext context: IterableActionContext) -> Bool {
        guard IterableUtil.isNotNullOrEmpty(string: action.type) else {
            return false
        }
        guard let customActionDelegate = customActionDelegate else {
            return false
        }
        
        return customActionDelegate.handle(iterableCustomAction:action, inContext:context)
    }
}
