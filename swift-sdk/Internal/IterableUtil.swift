//
//  Created by Tapash Majumder on 5/18/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import os
import UIKit

/// Functionality such as this will be built in for Swift 5.0. This will help with the transition
enum IterableResult<T, E> {
    case success(T)
    case failure(E)
}

@objc public final class IterableUtil: NSObject {
    static var rootViewController: UIViewController? {
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
    
    /// int is milliseconds since epoch.
    static func date(fromInt int: Int) -> Date {
        let seconds = Double(int) / 1000.0 // ms -> seconds
        
        return Date(timeIntervalSince1970: seconds)
    }
    
    /// milliseconds since epoch.
    static func int(fromDate date: Date) -> Int {
        return Int(date.timeIntervalSince1970 * 1000)
    }
    
    // given "var1", "val1", "var2", "val2" as input
    // this will return "var1: val1, var2: val2"
    // this is useful for description of an object or struct
    static func describe(_ values: Any..., pairSeparator: String = ": ", separator: String = ", ") -> String {
        return values.take(2).map { pair in
            if pair.count == 0 {
                return ""
            } else if pair.count == 1 {
                return "\(pair[0])\(pairSeparator)nil"
            } else {
                return "\(pair[0])\(pairSeparator)\(pair[1])"
            }
        }.joined(separator: separator)
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
        return { _ in
            guard let customActionDelegate = customActionDelegate else {
                return false
            }
            
            _ = customActionDelegate.handle(iterableCustomAction: context.action, inContext: context)
            
            return true
        }
    }
}
