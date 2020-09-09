//
//  Created by Tapash Majumder on 9/8/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class NetworkConnectivityManagerTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
    }
    
    func testNetworkMonitor() throws {
        let expectation1 = expectation(description: "do not fulfill before start")
        expectation1.isInverted = true
        let monitor = NetworkMonitor()
        monitor.statusUpdatedCallback = {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)

        let expectation2 = expectation(description: "fullfill when started")
        monitor.statusUpdatedCallback = {
            expectation2.fulfill()
        }
        monitor.start()
        wait(for: [expectation2], timeout: 1.0)

        // now stop
        monitor.stop()
        let expectation3 = expectation(description: "don't fullfill when stopped")
        expectation3.isInverted = true
        monitor.statusUpdatedCallback = {
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
        
        let expectation4 = expectation(description: "fullfill when started again")
        monitor.statusUpdatedCallback = {
            expectation4.fulfill()
        }
        monitor.start()
        wait(for: [expectation4], timeout: 1.0)
        monitor.stop()
    }
    
    func testPollingNetworkMonitor() throws {
        let expectation1 = expectation(description: "do not fulfill before start")
        expectation1.isInverted = true
        let monitor = PollingNetworkMonitor(pollingInterval: 0.2)
        monitor.statusUpdatedCallback = {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        let expectation2 = expectation(description: "fullfill when started")
        expectation2.expectedFulfillmentCount = 2
        monitor.statusUpdatedCallback = {
            expectation2.fulfill()
        }
        monitor.start()
        wait(for: [expectation2], timeout: 1.0)

        // now stop
        monitor.stop()
        let expectation3 = expectation(description: "don't fullfill when stopped")
        expectation3.isInverted = true
        monitor.statusUpdatedCallback = {
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)

        let expectation4 = expectation(description: "fullfill when started again")
        monitor.statusUpdatedCallback = {
            expectation4.fulfill()
        }
        monitor.start()
        wait(for: [expectation4], timeout: 1.0)
        monitor.stop()
    }
    
    func testConnectivityChange() throws {
        let networkSession = MockNetworkSession()
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = PollingNetworkMonitor(pollingInterval: 0.5)
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)
        
        // check online status before everything
        XCTAssertTrue(manager.isOnline)
        
        // check that status is offline when there is network error
        let expectation1 = expectation(description: "ConnectivityManager: check status change on network error")
        networkSession.error = IterableError.general(description: "Mock error")
        manager.connectivityChangedCallback = { connected in
            XCTAssertFalse(connected)
            expectation1.fulfill()
        }
        manager.start()
        wait(for: [expectation1], timeout: 10.0)
        
        // check that status is online once error is removed
        let expectation2 = expectation(description: "ConnectivityManager: check status change on network back to normal")
        manager.connectivityChangedCallback = { connected in
            XCTAssertTrue(connected)
            expectation2.fulfill()
        }
        networkSession.error = nil
        wait(for: [expectation2], timeout: 10.0)
        
        // check that status does not change once manager is stopped
        let expectation3 = expectation(description: "ConnectivityManager: no status change when stopped")
        expectation3.isInverted = true
        manager.stop()
        networkSession.error = IterableError.general(description: "Mock error")
        manager.connectivityChangedCallback = { connected in
            XCTAssertTrue(connected)
            expectation3.fulfill()
        }
        wait(for: [expectation3], timeout: 1.0)
    }

    func testForegroundBackgroundChange() throws {
        let networkSession = MockNetworkSession()
        let checker = NetworkConnectivityChecker(networkSession: networkSession)
        let monitor = PollingNetworkMonitor(pollingInterval: 0.5)
        let notificationCenter = MockNotificationCenter()
        let manager = NetworkConnectivityManager(networkMonitor: monitor,
                                                 connectivityChecker: checker,
                                                 notificationCenter: notificationCenter)
        
        // check online status before everything
        XCTAssertTrue(manager.isOnline)
        
        // check that status is offline when there is network error
        let expectation1 = expectation(description: "ConnectivityManager: check status change on network error")
        networkSession.error = IterableError.general(description: "Mock error")
        manager.connectivityChangedCallback = { connected in
            XCTAssertFalse(connected)
            expectation1.fulfill()
        }
        manager.start()
        wait(for: [expectation1], timeout: 10.0)
        
        // check that status is still offline when app is in background, even though network is normal.
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil, userInfo: nil)
        let expectation2 = expectation(description: "ConnectivityManager: check no status change on network back to normal")
        expectation2.isInverted = true
        manager.connectivityChangedCallback = { connected in
            XCTAssertTrue(connected)
            expectation2.fulfill()
        }
        networkSession.error = nil
        wait(for: [expectation2], timeout: 1.0)

        // check that status changes when we go online
        let expectation3 = expectation(description: "ConnectivityManager: status change when app goes to foreground")
        manager.connectivityChangedCallback = { connected in
            XCTAssertTrue(connected)
            expectation3.fulfill()
        }
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil, userInfo: nil)
        wait(for: [expectation3], timeout: 10.0)
    }
}
