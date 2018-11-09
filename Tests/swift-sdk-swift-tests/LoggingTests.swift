//
//
//  Created by Tapash Majumder on 9/4/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest
@testable import IterableSDK

class LoggingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLogging() {
        class LogDelegate : IterableLogDelegate {
            var level: LogLevel? = nil
            var message: String? = nil
            
            func log(level: LogLevel, message: String) {
                self.level = level
                self.message = message
            }
        }
        
        let logDelegate = LogDelegate()
        let config = IterableConfig()
        config.logDelegate = logDelegate
        TestHelper.initializeApi(apiKey: "apiKey", config: config)
        
        ITBDebug("debug message")
        XCTAssert(logDelegate.level == .debug)
        XCTAssert(logDelegate.message!.contains("debug message"))

        ITBInfo("info message")
        XCTAssert(logDelegate.level == .info)
        XCTAssert(logDelegate.message!.contains("info message"))

        ITBError("error message")
        XCTAssert(logDelegate.level == .error)
        XCTAssert(logDelegate.message!.contains("error message"))
    }
}
