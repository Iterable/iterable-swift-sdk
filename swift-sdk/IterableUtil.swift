//
//  IterableUtil.swift
//  iOS Demo
//
//  Created by Tapash Majumder on 5/18/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import os

@objc public final class IterableUtil : NSObject {
    static var rootViewController : UIViewController {
        return UIApplication.shared.keyWindow!.rootViewController!
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
    
    static func isNotNullOrEmpty(string: String) -> Bool {
        return !isNullOrEmpty(string: string)
    }
}

public func ITBError(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    let logMessage = formatLogMessage(message: message, file: file, method: method, line: line)
    if #available(iOS 10.0, *) {
        os_log("%@", log: OSLog.default, type: .error, logMessage)
    } else {
        print(logMessage)
    }
}

private func formatLogMessage(message: String?, file: String, method: String, line: Int) -> String {
    let fileUrl = NSURL(fileURLWithPath: file)
    let fileToDisplay = fileUrl.deletingPathExtension!.lastPathComponent
    
    if let zeeMessage = message {
        return "\(fileToDisplay):\(method):\(line): \(zeeMessage)"
    } else {
        return "\(fileToDisplay):\(method):\(line)"
    }
}

/// It will print the output only if 'LOG' is defined in the project via -D LOG as 'Other Swift Flags'
public func ITBInfo(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    #if LOG
    let fileUrl = NSURL(fileURLWithPath: file)
    let fileToDisplay = fileUrl.deletingPathExtension!.lastPathComponent
    
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSSS"
    let time = formatter.string(from: Date())
    
    if let zeeMessage = message {
        print("===> \(time):\(fileToDisplay):\(method):\(line): \(zeeMessage)")
    } else {
        print("===> \(time):\(fileToDisplay):\(method):\(line)")
    }
    #endif
}
