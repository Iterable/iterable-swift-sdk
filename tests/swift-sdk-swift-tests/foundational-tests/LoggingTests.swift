//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class LoggingTests: XCTestCase {
    func testLogging() {
        let expectation1 = expectation(description: "debug message")
        let expectation2 = expectation(description: "info message")
        let expectation3 = expectation(description: "error message")
        
        class LogDelegate: IterableLogDelegate {
            var callback: ((LogLevel, String) -> Void)?
            
            func log(level: LogLevel, message: String) {
                callback?(level, message)
            }
        }
        
        let debugMessage = UUID().uuidString
        let infoMessage = UUID().uuidString
        let errorMessage = UUID().uuidString
        
        let logDelegate = LogDelegate()
        logDelegate.callback = { logLevel, message in
            if logLevel == .debug, message.contains(debugMessage) {
                expectation1.fulfill()
            }
            if logLevel == .info, message.contains(infoMessage) {
                expectation2.fulfill()
            }
            if logLevel == .error, message.contains(errorMessage) {
                expectation3.fulfill()
            }
        }
        let config = IterableConfig()
        config.logDelegate = logDelegate
        InternalIterableAPI.initializeForTesting(apiKey: "apiKey", config: config)
        
        ITBDebug(debugMessage)
        
        ITBInfo(infoMessage)
        
        ITBError(errorMessage)
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 10.0)
    }
}
