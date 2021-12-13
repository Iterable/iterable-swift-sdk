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

@available(iOS 12.0, *)
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
        networkMonitor.pathUpdateHandler = { path in
            ITBInfo("networkMonitor.pathUpdateHandler, path: \(path.debugDescription), status: \(path.status)")
            self.statusUpdatedCallback?()
        }

        networkMonitor.start(queue: queue)
        self.networkMonitor = networkMonitor
    }
    
    func stop() {
        ITBInfo()
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private weak var networkMonitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
}

/// This is used for pre-iOS 12.0 because `NWPathMonitor` is not available.
class PollingNetworkMonitor: NetworkMonitorProtocol {
    init(pollingInterval: TimeInterval? = nil) {
        ITBInfo()
        self.pollingInterval = pollingInterval ?? Self.defaultPollingInterval
    }
    
    deinit {
        ITBInfo()
    }
    
    var statusUpdatedCallback: (() -> Void)?

    func start() {
        ITBInfo()
        timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { timer in
            ITBInfo("Called timer")
            self.statusUpdatedCallback?()
        }
    }
    
    func stop() {
        ITBInfo()
        timer?.invalidate()
        timer = nil
    }
    
    private var pollingInterval: TimeInterval
    private static let defaultPollingInterval: TimeInterval = 5 * 60
    
    private var timer: Timer?
}
