//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

#if canImport(Network)
import Network
#endif

/// Listens to network interface to detect status change.
/// It only knows that the status has changed.
/// It does not know if the network is online or not.
protocol NetworkMonitorProtocol {
    func start()
    func stop()
    var statusUpdatedCallback: (() -> Void)? { get set }
}

class NetworkMonitor: NetworkMonitorProtocol {
    init() {
        ITBInfo()
    }

    deinit {
        ITBInfo()
        stop()
    }

    var statusUpdatedCallback: (() -> Void)?

    func start() {
        ITBInfo()
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { [weak self] path in
            ITBInfo("networkMonitor.pathUpdateHandler, path: \(path.debugDescription), status: \(path.status)")
            self?.statusUpdatedCallback?()
        }

        networkMonitor.start(queue: queue)
        self.networkMonitor = networkMonitor
    }

    func stop() {
        ITBInfo()
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    // Use a strong reference so the NWPathMonitor is kept alive while monitoring.
    // The previous weak reference could cause the monitor to be deallocated prematurely,
    // leading to crashes when the path update handler fired on a released object.
    private var networkMonitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
}
