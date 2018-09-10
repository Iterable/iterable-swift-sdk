//
//  IterableUtil.swift
//
//  Created by Tapash Majumder on 5/18/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import os

@objc public final class IterableUtil : NSObject {
    static var rootViewController : UIViewController? {
        return UIApplication.shared.delegate?.window??.rootViewController
    }
    
    static func trim(string: String) -> String {
        return string.trimmingCharacters(in: .whitespaces)
    }
    
    static func isNullOrEmpty(string: String?) -> Bool {
        guard let string = string else {
            return true
        }
        
        return trim(string: string).isEmpty
    }
    
    static func isNotNullOrEmpty(string: String?) -> Bool {
        return !isNullOrEmpty(string: string)
    }
    
    static func generateUUID() -> String {
        return UUID().uuidString
    }
    

    // MARK: Helper Utility Functions
    // converts from IterableURLDelegate to UrlHandler
    static func urlHandler(fromUrlDelegate urlDelegate: IterableURLDelegate?, inContext context: IterableActionContext) -> UrlHandler {
        return { url in
            urlDelegate?.handle(iterableURL: url, inContext: context) == true
        }
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
}

