import Foundation
import IterableSDK

/// Notification posted when the SDK emits a log line.
/// `userInfo["message"]` contains the parsed, friendly log string.
extension Notification.Name {
    static let sdkLogCaptured = Notification.Name("SDKLogCaptured")
}

/// Custom IterableLogDelegate that captures SDK logs and broadcasts them
/// via NotificationCenter so the test UI can display them in real-time.
/// Also prints to console so logs are still visible in Xcode.
final class SDKLogCapture: NSObject, IterableLogDelegate {

    static let shared = SDKLogCapture()

    func log(level: LogLevel, message: String) {
        // Still print to console
        let marker: String
        switch level {
        case .error: marker = "❤️"
        case .info:  marker = "💛"
        case .debug: marker = "💚"
        @unknown default: marker = "❓"
        }
        print("\(marker) \(message)")

        // Parse and broadcast
        let friendly = parseSdkLog(level: level, message: message)
        if let friendly = friendly {
            NotificationCenter.default.post(
                name: .sdkLogCaptured,
                object: nil,
                userInfo: ["message": friendly]
            )
        }
    }

    // MARK: - Log Parsing (mirrors Android LogStore.parseSdkLog)

    private func parseSdkLog(level: LogLevel, message: String) -> String? {
        // Format: "HH:mm:ss.SSSS:0xThread:FileName:methodName:line: actual message"
        // Extract the file name and the actual message
        let components = message.components(separatedBy: ":")
        // Need at least: time, thread, file, method, line, message
        guard components.count >= 6 else { return nil }

        let fileName = components[2]
        // Message is everything after the 5th colon
        let msgStartIndex = components.prefix(5).joined(separator: ":").count + 1
        guard msgStartIndex < message.count else { return nil }
        let msg = String(message[message.index(message.startIndex, offsetBy: msgStartIndex)...]).trimmingCharacters(in: .whitespaces)

        // Skip empty messages
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
        default:
            // Only show errors from other files
            if level == .error {
                return "❌ \(fileName): \(msg)"
            }
            return nil
        }
    }

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
        if msg.contains("processed with retry") || msg.contains("retry") {
            let id = extractTaskId(msg)
            return "🔄 Task \(id) will retry"
        }
        if msg.contains("paused") {
            return "⏸️ TaskRunner: \(msg)"
        }
        return "🔧 TaskRunner: \(msg)"
    }

    private func parseAuthLog(_ msg: String) -> String? {
        if msg.contains("token refreshed") || msg.contains("Token refreshed") {
            return "🔑 Auth: token refreshed"
        }
        if msg.contains("requestNewAuthToken") {
            return "🔄 Auth: requesting new token"
        }
        if msg.contains("auth failure") || msg.contains("onAuthFailure") {
            return "❌ Auth: failure — \(msg)"
        }
        if msg.contains("Scheduling") {
            return "🔄 Auth: \(msg)"
        }
        if msg.contains("Expiring") || msg.contains("expir") {
            return "⏰ Auth: \(msg)"
        }
        return nil
    }

    private func parseRequestLog(_ msg: String) -> String? {
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
            return "🔑 Processor: \(msg)"
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

    private func extractTaskId(_ msg: String) -> String {
        // Try to extract task ID from messages like "task: ABC12345 succeeded"
        if let range = msg.range(of: "task:?\\s+(\\S+)", options: .regularExpression) {
            let match = String(msg[range])
            let parts = match.components(separatedBy: .whitespaces)
            if let id = parts.last {
                return String(id.prefix(8))
            }
        }
        return "?"
    }
}
