//
//
//  Created by Tapash Majumder on 9/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import os

/// Will log if logLevel is >= IterableConfig.logLevel.
public class DefaultLogDelegate: IterableLogDelegate {
    public func log(level: LogLevel = .info, message: String) {
        guard let configLogLevel = IterableAPIInternal.sharedInstance?.config.logLevel, level.rawValue >= configLogLevel.rawValue else {
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
public class AllLogDelegate: IterableLogDelegate {
    public func log(level: LogLevel = .info, message: String) {
        let markedMessage = IterableLogUtil.markedMessage(level: level, message: message)
        print(markedMessage)
    }
}

/// Will log nothing
public class NoneLogDelegate: IterableLogDelegate {
    public func log(level: LogLevel = .info, message: String) {
        // Do nothing
    }
}

public func ITBError(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    IterableLogUtil.log(level: .error, message: message, file: file, method: method, line: line)
}

public func ITBInfo(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    IterableLogUtil.log(level: .info, message: message, file: file, method: method, line: line)
}

public func ITBDebug(_ message: String? = nil, file: String = #file, method: String = #function, line: Int = #line) {
    IterableLogUtil.log(level: .debug, message: message, file: file, method: method, line: line)
}

struct IterableLogUtil {
    static func log(level: LogLevel, message: String?, file: String, method: String, line: Int) {
        let date = IterableAPIInternal.sharedInstance?.dateProvider.currentDate ?? Date()
        let logMessage = formatLogMessage(message: message, file: file, method: method, line: line, date: date)
        IterableAPIInternal.sharedInstance?.config.logDelegate.log(level: level, message: logMessage)
    }
    
    static func markedMessage(level: LogLevel, message: String) -> String {
        let markerStr = marker(forLevel: level)
        return "\(markerStr) \(message)"
    }
    
    static func marker(forLevel level: LogLevel) -> String {
        switch level {
        case .error:
            return "❤️"
        case .info:
            return "💛"
        case .debug:
            return "💚"
        }
    }

    private static func formatLogMessage(message: String?, file: String, method: String, line: Int, date: Date) -> String {
        let fileUrl = NSURL(fileURLWithPath: file)
        let fileToDisplay = fileUrl.deletingPathExtension!.lastPathComponent
        
        let formattedDate = formatDate(date: date)
        
        if let zeeMessage = message {
            return "\(formattedDate):\(fileToDisplay):\(method):\(line): \(zeeMessage)"
        } else {
            return "\(formattedDate):\(fileToDisplay):\(method):\(line)"
        }
    }
    
    private static func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        return formatter.string(from: date)
    }
}
