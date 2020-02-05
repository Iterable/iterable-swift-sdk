//
//  Created by Jay Kim on 12/6/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

struct IterableLogUtil {
    private let dateProvider: DateProviderProtocol
    private let logDelegate: IterableLogDelegate
    
    init(dateProvider: DateProviderProtocol, logDelegate: IterableLogDelegate) {
        self.dateProvider = dateProvider
        self.logDelegate = logDelegate
    }
    
    static var sharedInstance: IterableLogUtil?
    
    func log(level: LogLevel, message: String?, file: String, method: String, line: Int) {
        let logMessage = IterableLogUtil.formatLogMessage(message: message, file: file, method: method, line: line, date: dateProvider.currentDate)
        logDelegate.log(level: level, message: logMessage)
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
            return "\(formattedDate):\(String(format: "%p", Thread.current)):\(fileToDisplay):\(method):\(line): \(zeeMessage)"
        } else {
            return "\(formattedDate):\(String(format: "%p", Thread.current)):\(fileToDisplay):\(method):\(line)"
        }
    }
    
    private static func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        return formatter.string(from: date)
    }
}
