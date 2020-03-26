//
//  Created by Tapash Majumder on 9/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import os

/// Will log if logLevel is >= minLogLevel
@objc public class DefaultLogDelegate: NSObject, IterableLogDelegate {
    private let minLogLevel: LogLevel // the lowest level that will be logged
    
    init(minLogLevel: LogLevel = .info) {
        self.minLogLevel = minLogLevel
    }
    
    public func log(level: LogLevel = .info, message: String) {
        guard level.rawValue >= minLogLevel.rawValue else {
            return
        }
        
        let markedMessage = IterableLogUtil.markedMessage(level: level, message: message)
        if #available(iOS 10.0, *) {
            os_log("%@", log: OSLog.default, type: OSLogType.error, markedMessage)
        } else {
            print(markedMessage)
        }
    }
}

/// Will log everything
@objc public class AllLogDelegate: NSObject, IterableLogDelegate {
    public func log(level: LogLevel = .info, message: String) {
        let markedMessage = IterableLogUtil.markedMessage(level: level, message: message)
        print(markedMessage)
    }
}

/// Will log nothing
@objc public class NoneLogDelegate: NSObject, IterableLogDelegate {
    public func log(level _: LogLevel = .info, message _: String) {
        // Do nothing
    }
}

public func ITBError(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    IterableLogUtil.sharedInstance?.log(level: .error, message: message, file: file, method: method, line: line)
}

public func ITBInfo(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    IterableLogUtil.sharedInstance?.log(level: .info, message: message, file: file, method: method, line: line)
}

public func ITBDebug(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    IterableLogUtil.sharedInstance?.log(level: .debug, message: message, file: file, method: method, line: line)
}
