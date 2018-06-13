//
//  IterableActionRunner.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@objc public class IterableActionRunner : NSObject {
    @objc public static func executeAction(_ action: IterableAction) {
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
    
    private static func open(url: URL, action: IterableAction) {
        guard IterableAPI.instance?.urlDelegate?.handleIterableURL(url, fromAction: action) == false else {
            // only proceed if it was not handled
            return
        }
        
        if let scheme = url.scheme, scheme == "http" || scheme == "https" {
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
    
    private static func callCustomActionIfSpecified(action: IterableAction) {
        if IterableUtil.isNotNullOrEmpty(string: action.type) {
            _ = IterableAPI.instance?.customActionDelegate?.handleIterableCustomAction(action)
        }
    }
}
