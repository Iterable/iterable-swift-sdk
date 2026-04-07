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
        stop()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            ITBInfo("networkMonitor.pathUpdateHandler, path: \(path.debugDescription), status: \(path.status)")
            self?.statusUpdatedCallback?()
        }

        monitor.start(queue: queue)
        self.networkMonitor = monitor
    }
    
    func stop() {
        ITBInfo()
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private var networkMonitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
}
