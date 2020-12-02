//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class NetworkConnectivityCheckerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
    }

    func testIsConnectedByDefault() throws {
        let expectation1 = expectation(description: #function)
        let checker = NetworkConnectivityChecker()

        checker.checkConnectivity().onSuccess { connected in
            XCTAssertEqual(connected, true)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15.0)
    }

    func testIsConnected() throws {
        let expectation1 = expectation(description: #function)
        let checker = NetworkConnectivityChecker(networkSession: MockNetworkSession())

        checker.checkConnectivity().onSuccess { connected in
            XCTAssertEqual(connected, true)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15.0)
    }

    func testIsNotConnectedIfWrongStatus() throws {
        let expectation1 = expectation(description: #function)
        let checker = NetworkConnectivityChecker(networkSession: MockNetworkSession(statusCode: 300))

        checker.checkConnectivity().onSuccess { connected in
            XCTAssertEqual(connected, false)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15.0)
    }

    func testIsNotConnectedIfError() throws {
        let expectation1 = expectation(description: #function)
        let checker = NetworkConnectivityChecker(networkSession: MockNetworkSession(statusCode: 200, data: Data(repeating: 1, count: 10), error: IterableError.general(description: "simulated error")))

        checker.checkConnectivity().onSuccess { connected in
            XCTAssertEqual(connected, false)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 15.0)
    }
}
