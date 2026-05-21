//
//  Copyright © 2026 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class NetworkMonitorLifecycleTests: XCTestCase {
    func testNetworkMonitorDeallocatesAfterStartAndStop() {
        weak var weakMonitor: NetworkMonitor?
        weak var weakPathMonitor: SpyPathMonitor?

        autoreleasepool {
            var monitor: NetworkMonitor? = NetworkMonitor(pathMonitorFactory: {
                let pathMonitor = SpyPathMonitor()
                weakPathMonitor = pathMonitor
                return pathMonitor
            })

            weakMonitor = monitor
            monitor?.start()
            XCTAssertNotNil(weakPathMonitor)

            monitor?.stop()
            monitor = nil
        }

        XCTAssertNil(weakMonitor)
        XCTAssertNil(weakPathMonitor)
    }

    func testStartTwiceReleasesFirstPathMonitor() {
        var createdPathMonitorCount = 0
        weak var firstPathMonitor: SpyPathMonitor?
        weak var secondPathMonitor: SpyPathMonitor?

        let monitor = NetworkMonitor(pathMonitorFactory: {
            let pathMonitor = SpyPathMonitor()
            createdPathMonitorCount += 1

            if createdPathMonitorCount == 1 {
                firstPathMonitor = pathMonitor
            } else if createdPathMonitorCount == 2 {
                secondPathMonitor = pathMonitor
            }

            return pathMonitor
        })

        monitor.start()
        XCTAssertNotNil(firstPathMonitor)

        monitor.start()
        XCTAssertEqual(createdPathMonitorCount, 2)
        XCTAssertNil(firstPathMonitor)
        XCTAssertNotNil(secondPathMonitor)

        monitor.stop()
        XCTAssertNil(secondPathMonitor)
    }

    func testPathUpdateHandlerDoesNotInvokeStatusUpdatedCallbackAfterStop() {
        let pathMonitor = SpyPathMonitor()
        let monitor = NetworkMonitor(pathMonitorFactory: { pathMonitor })
        var statusUpdatedCallbackCount = 0
        monitor.statusUpdatedCallback = {
            statusUpdatedCallbackCount += 1
        }

        monitor.start()
        pathMonitor.sendPathUpdate()
        XCTAssertEqual(statusUpdatedCallbackCount, 1)

        monitor.stop()
        XCTAssertNil(pathMonitor.pathUpdateHandler)

        pathMonitor.sendPathUpdate()
        XCTAssertEqual(statusUpdatedCallbackCount, 1)
        XCTAssertEqual(pathMonitor.cancelCount, 1)
    }

    private final class SpyPathMonitor: NetworkPathMonitorProtocol {
        var pathUpdateHandler: ((NetworkPathUpdate) -> Void)?
        private(set) var cancelCount = 0

        func start(queue _: DispatchQueue) {}

        func cancel() {
            cancelCount += 1
        }

        func sendPathUpdate() {
            pathUpdateHandler?(NetworkPathUpdate(debugDescription: "spy path",
                                                status: "satisfied"))
        }
    }
}
