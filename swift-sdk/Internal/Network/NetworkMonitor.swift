//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

#if canImport(Network)
import Network
#endif

struct NetworkPathUpdate {
    let debugDescription: String
    let status: String
}

protocol NetworkPathMonitorProtocol: AnyObject {
    var pathUpdateHandler: ((NetworkPathUpdate) -> Void)? { get set }
    func start(queue: DispatchQueue)
    func cancel()
}

#if canImport(Network)
private final class NetworkPathMonitor: NetworkPathMonitorProtocol {
    var pathUpdateHandler: ((NetworkPathUpdate) -> Void)? {
        didSet {
            guard let pathUpdateHandler = pathUpdateHandler else {
                monitor.pathUpdateHandler = nil
                return
            }

            monitor.pathUpdateHandler = { path in
                pathUpdateHandler(NetworkPathUpdate(debugDescription: path.debugDescription,
                                                    status: String(describing: path.status)))
            }
        }
    }

    func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }

    func cancel() {
        monitor.cancel()
    }

    private let monitor = NWPathMonitor()
}
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
    init(pathMonitorFactory: @escaping () -> NetworkPathMonitorProtocol = { NetworkPathMonitor() }) {
        ITBInfo()
        self.pathMonitorFactory = pathMonitorFactory
    }
    
    deinit {
        ITBInfo()
        stop()
    }
    
    var statusUpdatedCallback: (() -> Void)?

    func start() {
        ITBInfo()
        stop()

        let networkMonitor = pathMonitorFactory()
        networkMonitor.pathUpdateHandler = { [weak self] path in
            ITBInfo("networkMonitor.pathUpdateHandler, path: \(path.debugDescription), status: \(path.status)")
            self?.statusUpdatedCallback?()
        }

        networkMonitor.start(queue: queue)
        self.networkMonitor = networkMonitor
    }
    
    func stop() {
        ITBInfo()
        networkMonitor?.pathUpdateHandler = nil
        networkMonitor?.cancel()
        networkMonitor = nil
    }
    
    private var networkMonitor: NetworkPathMonitorProtocol?
    private let pathMonitorFactory: () -> NetworkPathMonitorProtocol
    private let queue = DispatchQueue(label: "NetworkMonitor")
}
