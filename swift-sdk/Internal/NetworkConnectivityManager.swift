//
//  Created by Tapash Majumder on 9/8/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

class NetworkConnectivityManager: NSObject {
    init(networkMonitor: NetworkMonitorProtocol? = nil,
         connectivityChecker: NetworkConnectivityChecker = NetworkConnectivityChecker(),
         notificationCenter: NotificationCenterProtocol = NotificationCenter.default) {
        ITBInfo()
        self.networkMonitor = networkMonitor ?? Self.createNetworkMonitor()
        self.connectivityChecker = connectivityChecker
        self.notificationCenter = notificationCenter
        super.init()
        notificationCenter.addObserver(self,
                                       selector: #selector(onAppWillEnterForeground(notification:)),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(onAppDidEnterBackground(notification:)),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
    }
    
    var isOnline: Bool {
        online
    }
    
    var connectivityChangedCallback: ((Bool) -> Void)?
    
    func start() {
        ITBInfo()
        networkMonitor.statusUpdatedCallback = updateStatus
        networkMonitor.start()
    }
    
    func stop() {
        networkMonitor.stop()
    }
    
    private func updateStatus() {
        ITBInfo()
        connectivityChecker.checkConnectivity().onSuccess { connected in
            self.online = connected
        }
    }
    
    @objc
    private func onAppWillEnterForeground(notification _: Notification) {
        ITBInfo()
        start()
    }
    
    @objc
    private func onAppDidEnterBackground(notification _: Notification) {
        ITBInfo()
        stop()
    }

    private static func createNetworkMonitor() -> NetworkMonitorProtocol {
        if #available(iOS 12, *) {
            return NetworkMonitor()
        } else {
            return PollingNetworkMonitor()
        }
    }

    private let notificationCenter: NotificationCenterProtocol
    private var networkMonitor: NetworkMonitorProtocol
    private let connectivityChecker: NetworkConnectivityChecker
    
    private var online = true {
        didSet {
            if online != oldValue {
                connectivityChangedCallback?(online)
            }
        }
    }
}
