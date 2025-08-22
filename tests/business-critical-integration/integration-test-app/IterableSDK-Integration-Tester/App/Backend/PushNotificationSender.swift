import Foundation
import UserNotifications

class PushNotificationSender {
    
    // MARK: - Properties
    
    private let apiClient: IterableAPIClient
    private let serverKey: String
    private let projectId: String
    private var sentNotifications: [String: PushNotificationInfo] = [:]
    
    // Configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 3.0
    private let deliveryTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    init(apiClient: IterableAPIClient, serverKey: String, projectId: String) {
        self.apiClient = apiClient
        self.serverKey = serverKey
        self.projectId = projectId
    }
    
    // MARK: - Push Notification Types
    
    enum PushNotificationType {
        case standard(title: String, body: String)
        case silent
        case withDeepLink(title: String, body: String, deepLink: String)
        case withActionButtons(title: String, body: String, buttons: [ActionButton])
        case withCustomData(title: String, body: String, customData: [String: Any])
        case richMedia(title: String, body: String, imageURL: String)
    }
    
    struct ActionButton {
        let identifier: String
        let title: String
        let action: ButtonAction
        
        enum ButtonAction {
            case openApp
            case openURL(String)
            case dismiss
        }
    }
    
    struct PushNotificationInfo {
        let messageId: String
        let campaignId: String
        let type: PushNotificationType
        let timestamp: Date
        let recipient: String
        var deliveryStatus: DeliveryStatus = .pending
        
        enum DeliveryStatus {
            case pending
            case sent
            case delivered
            case failed(Error)
        }
    }
    
    // MARK: - Standard Push Notifications
    
    func sendStandardPushNotification(
        to userEmail: String,
        title: String,
        body: String,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        let campaignId = generateCampaignId()
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": 14679102,
            "allowRepeatMarketingSends": true,
            "dataFields": [:],
            "metadata": [:]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: campaignId,
            type: .standard(title: title, body: body),
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
    
    // MARK: - Silent Push Notifications
    
    func sendSilentPushNotification(
        to userEmail: String,
        triggerType: String,
        customData: [String: Any] = [:],
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        let campaignId = generateCampaignId()
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": 14679102,
            "allowRepeatMarketingSends": true,
            "dataFields": [:],
            "metadata": [:]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: campaignId,
            type: .silent,
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
    
    // MARK: - Utility Methods
    
    private func sendPushNotificationRequest(
        payload: [String: Any],
        messageId: String,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        apiClient.sendPushNotification(to: payload["recipientEmail"] as! String, payload: payload) { success, error in
            if success {
                // Update notification status
                if var notificationInfo = self.sentNotifications[messageId] {
                    notificationInfo.deliveryStatus = .sent
                    self.sentNotifications[messageId] = notificationInfo
                }
                completion(true, messageId, nil)
            } else {
                // Update notification status with error
                if var notificationInfo = self.sentNotifications[messageId] {
                    notificationInfo.deliveryStatus = .failed(error ?? PushError.unknownError)
                    self.sentNotifications[messageId] = notificationInfo
                }
                completion(false, messageId, error)
            }
        }
    }
    
    private func generateMessageId() -> String {
        return "test-msg-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"
    }
    
    private func generateCampaignId() -> String {
        return String(Int.random(in: 100000...999999))
    }
    
    // MARK: - Push Notification History
    
    func getPushNotificationHistory(for userEmail: String) -> [PushNotificationInfo] {
        return sentNotifications.values.filter { $0.recipient == userEmail }
    }
    
    func clearPushNotificationHistory() {
        sentNotifications.removeAll()
    }
    
    func getPushNotificationInfo(messageId: String) -> PushNotificationInfo? {
        return sentNotifications[messageId]
    }
    
    // MARK: - Convenience Methods
    
    func sendIntegrationTestPush(
        to userEmail: String,
        testType: String = "standard",
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let title = "Integration Test Push"
        let body = "This is a test push notification sent from the Integration Test App backend module."
        
        switch testType.lowercased() {
        case "standard":
            sendStandardPushNotification(to: userEmail, title: title, body: body, completion: completion)
        case "silent":
            sendSilentPushNotification(to: userEmail, triggerType: "integration_test", completion: completion)
        default:
            sendStandardPushNotification(to: userEmail, title: title, body: body, completion: completion)
        }
    }
    
    func sendDeepLinkPush(
        to userEmail: String,
        campaignId: Int,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": campaignId,
            "allowRepeatMarketingSends": true,
            "dataFields": [:],
            "metadata": [:]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: String(campaignId),
            type: .withDeepLink(title: "Deep Link Test", body: "Tap to test deep link", deepLink: "tester://"),
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
}

// MARK: - Error Types

enum PushError: Error, LocalizedError {
    case invalidPayload
    case sendFailed
    case deliveryTimeout
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidPayload:
            return "Invalid push notification payload"
        case .sendFailed:
            return "Failed to send push notification"
        case .deliveryTimeout:
            return "Push notification delivery timeout"
        case .unknownError:
            return "Unknown push notification error"
        }
    }
}
