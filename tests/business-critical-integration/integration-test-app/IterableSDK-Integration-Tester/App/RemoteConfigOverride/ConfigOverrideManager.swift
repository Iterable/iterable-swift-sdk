import Foundation

/// Manages remote config flag overrides independently of the mock JWT server.
/// Persists preferences to UserDefaults so they survive app relaunches.
final class ConfigOverrideManager {
    static let shared = ConfigOverrideManager()

    private static let keyEnabled = "config_override_enabled"
    private static let keyOfflineMode = "config_override_offline_mode"
    private static let keyAutoRetry = "config_override_auto_retry"

    var overrideOfflineMode: Bool {
        didSet { UserDefaults.standard.set(overrideOfflineMode, forKey: Self.keyOfflineMode) }
    }

    var overrideAutoRetry: Bool {
        didSet { UserDefaults.standard.set(overrideAutoRetry, forKey: Self.keyAutoRetry) }
    }

    private(set) var isEnabled: Bool = false

    private init() {
        let defaults = UserDefaults.standard
        // Load saved preferences (default to true if never set)
        if defaults.object(forKey: Self.keyOfflineMode) != nil {
            overrideOfflineMode = defaults.bool(forKey: Self.keyOfflineMode)
        } else {
            overrideOfflineMode = true
        }
        if defaults.object(forKey: Self.keyAutoRetry) != nil {
            overrideAutoRetry = defaults.bool(forKey: Self.keyAutoRetry)
        } else {
            overrideAutoRetry = true
        }

        // Re-enable override if it was enabled last time
        if defaults.bool(forKey: Self.keyEnabled) {
            enable()
        }
    }

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: Self.keyEnabled)
        NetworkMonitor.registerProtocolClass(ConfigOverrideURLProtocol.self)
        print("[CONFIG OVERRIDE] Enabled — offlineMode: \(overrideOfflineMode), autoRetry: \(overrideAutoRetry)")
    }

    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        UserDefaults.standard.set(false, forKey: Self.keyEnabled)
        NetworkMonitor.unregisterProtocolClass(ConfigOverrideURLProtocol.self)
        print("[CONFIG OVERRIDE] Disabled")
    }
}
