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
    @objc func execute(action: IterableAction)
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
    
    func execute(action: IterableAction) {
        if action.isOfType(IterableAction.actionTypeOpenUrl) {
            if let data = action.data {
                if let url = URL(string: data) {
                    open(url: url, action: action)
                } else {
                    ITBError("Could not create url from data: \(data)")
                }
            } else {
                ITBError("data is required for action type 'openUrl'")
            }
        } else {
            callCustomActionIfSpecified(action: action)
        }
    }
    
    private func open(url: URL, action: IterableAction) {
        guard urlDelegate?.handleIterableURL(url, fromAction: action) == false else {
            // only proceed if it was not handled
            return
        }
        
        if let scheme = url.scheme, scheme == "http" || scheme == "https" {
            urlOpener.open(url: url)
        }
    }
    
    private func callCustomActionIfSpecified(action: IterableAction) {
        if IterableUtil.isNotNullOrEmpty(string: action.type) {
            _ = customActionDelegate?.handleIterableCustomAction(action)
        }
    }
}
