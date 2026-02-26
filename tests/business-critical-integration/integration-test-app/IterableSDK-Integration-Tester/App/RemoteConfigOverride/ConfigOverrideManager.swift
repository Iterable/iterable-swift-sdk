import Foundation

/// Manages remote config flag overrides independently of the mock JWT server.
final class ConfigOverrideManager {
    static let shared = ConfigOverrideManager()

    var overrideOfflineMode: Bool = true
    var overrideAutoRetry: Bool = true

    private(set) var isEnabled: Bool = false

    private init() {}

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        NetworkMonitor.registerProtocolClass(ConfigOverrideURLProtocol.self)
        print("[CONFIG OVERRIDE] Enabled — offlineMode: \(overrideOfflineMode), autoRetry: \(overrideAutoRetry)")
    }

    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        NetworkMonitor.unregisterProtocolClass(ConfigOverrideURLProtocol.self)
        print("[CONFIG OVERRIDE] Disabled")
    }
}
