//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class LoggingTests: XCTestCase {
    private class SpyDateProvider: DateProviderProtocol {
        private(set) var currentDateAccessCount = 0

        var currentDate: Date {
            currentDateAccessCount += 1
            return Date(timeIntervalSince1970: 0)
        }
    }

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

    func testDefaultLogDelegateDoesNotFormatFilteredLogLevel() {
        let dateProvider = SpyDateProvider()
        let logUtil = IterableLogUtil(dateProvider: dateProvider, logDelegate: DefaultLogDelegate(minLogLevel: .error))

        logUtil.log(level: .info, message: "filtered", file: #file, method: #function, line: #line)
        XCTAssertEqual(dateProvider.currentDateAccessCount, 0)

        logUtil.log(level: .error, message: "logged", file: #file, method: #function, line: #line)
        XCTAssertEqual(dateProvider.currentDateAccessCount, 1)
    }

    func testNoneLogDelegateDoesNotFormatMessages() {
        let dateProvider = SpyDateProvider()
        let logUtil = IterableLogUtil(dateProvider: dateProvider, logDelegate: NoneLogDelegate())

        logUtil.log(level: .error, message: "filtered", file: #file, method: #function, line: #line)

        XCTAssertEqual(dateProvider.currentDateAccessCount, 0)
    }
}
