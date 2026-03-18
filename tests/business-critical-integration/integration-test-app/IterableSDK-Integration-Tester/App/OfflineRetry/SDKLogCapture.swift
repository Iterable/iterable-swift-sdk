import Foundation
import IterableSDK

// MARK: - LogStore (shared log buffer, mirrors Android LogStore)

/// Shared log store that buffers all logs from app start.
/// Both SDK internal logs and app-level logs go here.
final class LogStore {
    static let shared = LogStore()

    /// All log entries, newest first.
    private(set) var entries: [String] = []

    /// Posted on main thread whenever a new entry is added.
    /// `userInfo["entry"]` contains the formatted log string.
    static let didAddEntry = Notification.Name("LogStoreDidAddEntry")

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private let maxEntries = 500

    private init() {}

    func log(_ message: String) {
        let line = "\(timeFormatter.string(from: Date())) \(message)"
        let notify = {
            self.entries.insert(line, at: 0)
            if self.entries.count > self.maxEntries {
                self.entries.removeLast(self.entries.count - self.maxEntries)
            }
            NotificationCenter.default.post(
                name: LogStore.didAddEntry,
                object: nil,
                userInfo: ["entry": line]
            )
        }
        if Thread.isMainThread {
            notify()
        } else {
            DispatchQueue.main.async(execute: notify)
        }
    }

    func clear() {
        entries.removeAll()
    }
}

// MARK: - SDKLogCapture (IterableLogDelegate)

/// Custom IterableLogDelegate that captures SDK logs, parses them into
/// friendly messages, and routes them to the shared LogStore.
/// Matches the Android network tester's log filtering — only shows
/// actionable events, not internal init/constructor noise.
final class SDKLogCapture: NSObject, IterableLogDelegate {

    static let shared = SDKLogCapture()

    func log(level: LogLevel, message: String) {
        // Still print to console for Xcode debugging
        let marker: String
        switch level {
        case .error: marker = "❤️"
        case .info:  marker = "💛"
        case .debug: marker = "💚"
        @unknown default: marker = "❓"
        }
        print("\(marker) \(message)")

        // Parse and store (only meaningful events)
        if let friendly = parseSdkLog(level: level, message: message) {
            LogStore.shared.log(friendly)
        }
    }

    // MARK: - Log Parsing (mirrors Android LogStore.parseSdkLog)

    private func parseSdkLog(level: LogLevel, message: String) -> String? {
        // Format: "HH:mm:ss.SSSS:0xThread:FileName:methodName:line: actual message"
        // Splitting by ":" gives: [HH, mm, ss.SSSS, 0xThread, FileName, method, line, message...]
        // The timestamp HH:mm:ss.SSSS contributes 3 components, so fileName is at index 4.
        let components = message.components(separatedBy: ":")
        guard components.count >= 8 else { return nil }

        let fileName = components[4]
        let msgStartIndex = components.prefix(7).joined(separator: ":").count + 1
        guard msgStartIndex < message.count else { return nil }
        let msg = String(message[message.index(message.startIndex, offsetBy: msgStartIndex)...]).trimmingCharacters(in: .whitespaces)

        guard !msg.isEmpty else { return nil }

        switch fileName {
        case "IterableTaskRunner":
            return parseTaskRunnerLog(msg)
        case "AuthManager":
            return parseAuthLog(msg)
        case "RequestProcessorUtil":
            return parseRequestLog(msg)
        case "IterableAPICallTaskProcessor":
            return parseProcessorLog(msg)
        case "InternalIterableAPI":
            return parseApiLog(msg)
        case "IterableTaskScheduler":
            return parseSchedulerLog(msg)
        case "NetworkConnectivityManager", "NetworkConnectivityChecker":
            return parseNetworkLog(msg)
        case "NetworkMonitor":
            return parseNetworkMonitorLog(msg)
        case "IterableEmbeddedManager":
            return nil // suppress — internal detail, noisy on init without email
        case "RequestCreator":
            return nil // suppress — transient "email nil" errors during reinit
        case "OfflineRequestProcessor":
            return nil // suppress — "could not find fulfill" is expected for tasks from previous sessions
        default:
            // Only surface errors from unknown files — suppress all info/debug noise
            if level == .error {
                return "❌ \(fileName): \(msg)"
            }
            return nil
        }
    }

    // MARK: - Per-file parsers (only return non-nil for actionable events)

    private func parseTaskRunnerLog(_ msg: String) -> String? {
        if msg.contains("JWT auth failure") {
            let id = extractTaskId(msg)
            return "⏸️ Task \(id): JWT failed, pausing queue"
        }
        if msg.contains("Auth paused") || msg.contains("authPaused = true") {
            return "⏸️ Queue PAUSED (auth)"
        }
        if msg.contains("resumed") || msg.contains("authPaused = false") {
            return "▶️ Queue RESUMED"
        }
        if msg.contains("succeeded") {
            let id = extractTaskId(msg)
            return "✅ Task \(id) succeeded"
        }
        if msg.contains("failed with no retry") {
            let id = extractTaskId(msg)
            return "❌ Task \(id) deleted (no retry)"
        }
        if msg.contains("processed with retry") {
            let id = extractTaskId(msg)
            return "🔄 Task \(id) will retry"
        }
        if msg.contains("No tasks to execute") {
            return nil // suppress — not actionable
        }
        if msg.contains("Already running") {
            return nil // suppress — internal detail
        }
        if msg.contains("Executing") {
            // "Executing taskId: XXX, name: events/track"
            if let nameRange = msg.range(of: "name: ") {
                let endpoint = String(msg[nameRange.upperBound...])
                let id = extractTaskId(msg)
                return "🔧 Executing \(endpoint) [\(id)]"
            }
        }
        if msg.contains("deleting task") {
            return nil // suppress — covered by "succeeded" / "deleted"
        }
        // Suppress all other TaskRunner noise (line numbers, init, etc.)
        return nil
    }

    private func parseAuthLog(_ msg: String) -> String? {
        if msg.contains("token refreshed") || msg.contains("Token refreshed") {
            return "🔑 Auth: token refreshed"
        }
        if msg.contains("requestNewAuthToken") {
            return "🔄 Auth: requesting new token"
        }
        if msg.contains("AUTH_TOKEN_NULL") || msg.contains("auth failure") || msg.contains("onAuthFailure") {
            return "❌ Auth: \(msg)"
        }
        if msg.contains("Scheduling auth token refresh timer") {
            // Extract the time: "Scheduling auth token refresh timer for 58993ms ..."
            if let msRange = msg.range(of: "for \\d+ms", options: .regularExpression) {
                let duration = String(msg[msRange])
                return "🔧 Auth: \(duration) until refresh"
            }
            return "🔧 Auth: scheduling refresh"
        }
        if msg.contains("Auth token refresh timer fired") {
            return "🔧 Auth: refresh timer fired"
        }
        if msg.contains("app foregrounded") || msg.contains("App switched to foreground") {
            return "🔄 Auth: app foregrounded, checking token"
        }
        if msg.contains("app backgrounded") || msg.contains("App switched to background") {
            return "💤 Auth: app backgrounded"
        }
        if msg.contains("scheduleAuthTokenRefresh blocked") {
            return nil // suppress — internal detail
        }
        if msg.contains("pauseAuthRetry") {
            return nil // suppress — internal detail
        }
        // Suppress init logs (contain parameter lists)
        if msg.contains("expirationRefreshPeriod") || msg.contains("localStorage") {
            return nil
        }
        return nil
    }

    private func parseRequestLog(_ msg: String) -> String? {
        // Suppress expected transient errors during init
        if msg.contains("UnknownEmailError") || msg.contains("No user exists") {
            return nil
        }
        if msg.contains("401") || msg.contains("InvalidJwt") {
            return "📤 Request: 401 JWT error"
        }
        if msg.contains("500") {
            return "📤 Request: 500 server error"
        }
        if msg.contains("failed") || msg.contains("error") {
            return "📤 Request: \(msg)"
        }
        return nil
    }

    private func parseProcessorLog(_ msg: String) -> String? {
        if msg.contains("permanent failure") || msg.contains("isPermanentFailure") {
            return "❌ Processor: permanent failure"
        }
        if msg.contains("JWT") || msg.contains("401") {
            return "🔑 Processor: JWT auth issue"
        }
        return nil
    }

    private func parseApiLog(_ msg: String) -> String? {
        if msg.contains("SDK not initialized") {
            return "⚠️ SDK not initialized"
        }
        if msg.contains("Cannot complete") {
            return "⚠️ \(msg)"
        }
        if msg.contains("setting offlineMode") {
            return "⚙️ \(msg)"
        }
        return nil
    }

    private func parseSchedulerLog(_ msg: String) -> String? {
        if msg.contains("schedule") || msg.contains("Schedule") {
            return "📋 Scheduler: task created"
        }
        return nil
    }

    private func parseNetworkLog(_ msg: String) -> String? {
        if msg.contains("online") || msg.contains("connected") {
            return "🌐 Network: online"
        }
        if msg.contains("offline") || msg.contains("not connected") {
            return "📡 Network: offline"
        }
        return nil
    }

    private func parseNetworkMonitorLog(_ msg: String) -> String? {
        // Only show connectivity changes, not verbose path details
        if msg.contains("satisfied") && !msg.contains("unsatisfied") {
            return "🌐 Network: online"
        }
        if msg.contains("unsatisfied") {
            return "📡 Network: offline"
        }
        return nil
    }

    private func extractTaskId(_ msg: String) -> String {
        // Match patterns like "taskId: XXXX" or "task: XXXX" or "task XXXX"
        if let range = msg.range(of: "(?:taskId|task):?\\s+([A-F0-9-]+)", options: .regularExpression) {
            let match = String(msg[range])
            let parts = match.components(separatedBy: .whitespaces)
            if let id = parts.last {
                return String(id.prefix(8))
            }
        }
        return "?"
    }
}
