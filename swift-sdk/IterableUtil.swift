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

public class DefaultLogDelegate: IterableLogDelegate {
    public func log(level: LogLevel = .info, message: String) {
        guard let configLogLevel = IterableAPIInternal.sharedInstance?.config.logLevel, level.rawValue >= configLogLevel.rawValue else {
            return
        }
        
        switch level {
        case .error:
            // Error goes to os_log, if available
            if #available(iOS 10.0, *) {
                os_log("%@", log: OSLog.default, type: .error, message)
            } else {
                print(message)
            }
        case .info:
            let markerStr = "💛"
            print("\(markerStr) \(message)")
        case .debug:
            // no logging
            break
        }
    }
}

public func ITBError(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    let date = IterableAPIInternal.sharedInstance?.dateProvider.currentDate ?? Date()
    let logMessage = formatLogMessage(message: message, file: file, method: method, line: line, date: date)
    IterableAPIInternal.sharedInstance?.config.logDelegate.log(level: .error, message: logMessage)
}

private func formatLogMessage(message: String?, file: String, method: String, line: Int, date: Date) -> String {
    let fileUrl = NSURL(fileURLWithPath: file)
    let fileToDisplay = fileUrl.deletingPathExtension!.lastPathComponent

    let formattedDate = formatDate(date: date)
    
    if let zeeMessage = message {
        return "\(formattedDate):\(fileToDisplay):\(method):\(line): \(zeeMessage)"
    } else {
        return "\(formattedDate):\(fileToDisplay):\(method):\(line)"
    }
}

private func formatDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSSS"
    return formatter.string(from: date)
}

/// It will print the output only if 'LOG' is defined in the project via -D LOG as 'Other Swift Flags'
public func ITBInfo(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    let date = IterableAPIInternal.sharedInstance?.dateProvider.currentDate ?? Date()
    let logMessage = formatLogMessage(message: message, file: file, method: method, line: line, date: date)
    IterableAPIInternal.sharedInstance?.config.logDelegate.log(level: .info, message: logMessage)
}
