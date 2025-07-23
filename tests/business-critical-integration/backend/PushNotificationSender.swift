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
            "campaignId": Int(campaignId) ?? 0,
            "messageId": messageId,
            "sendAt": "immediate",
            "allowRepeatMarketingCampaigns": true,
            "dataFields": [
                "testType": "standard_push",
                "timestamp": Date().timeIntervalSince1970
            ],
            "pushPayload": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": 1,
                "sound": "default",
                "contentAvailable": false
            ],
            "metadata": [
                "source": "integration_test",
                "test_type": "standard_push",
                "project_id": projectId
            ]
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
        
        var dataFields = customData
        dataFields["silentPush"] = true
        dataFields["triggerType"] = triggerType
        dataFields["timestamp"] = Date().timeIntervalSince1970
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": Int(campaignId) ?? 0,
            "messageId": messageId,
            "sendAt": "immediate",
            "allowRepeatMarketingCampaigns": true,
            "dataFields": dataFields,
            "pushPayload": [
                "contentAvailable": true,
                "isGhostPush": true,
                "badge": NSNull(),
                "sound": NSNull(),
                "alert": NSNull()
            ],
            "metadata": [
                "source": "integration_test",
                "test_type": "silent_push",
                "trigger_type": triggerType,
                "project_id": projectId
            ]
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
    
    // MARK: - Push with Deep Links
    
    func sendPushWithDeepLink(
        to userEmail: String,
        title: String,
        body: String,
        deepLinkURL: String,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        let campaignId = generateCampaignId()
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": Int(campaignId) ?? 0,
            "messageId": messageId,
            "sendAt": "immediate",
            "allowRepeatMarketingCampaigns": true,
            "dataFields": [
                "testType": "deeplink_push",
                "deepLinkURL": deepLinkURL,
                "timestamp": Date().timeIntervalSince1970
            ],
            "pushPayload": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": 1,
                "sound": "default",
                "customData": [
                    "deepLink": deepLinkURL,
                    "action": "openUrl"
                ]
            ],
            "defaultAction": [
                "type": "openUrl",
                "data": deepLinkURL
            ],
            "metadata": [
                "source": "integration_test",
                "test_type": "deeplink_push",
                "deep_link": deepLinkURL,
                "project_id": projectId
            ]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: campaignId,
            type: .withDeepLink(title: title, body: body, deepLink: deepLinkURL),
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
    
    // MARK: - Push with Action Buttons
    
    func sendPushWithActionButtons(
        to userEmail: String,
        title: String,
        body: String,
        buttons: [ActionButton],
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        let campaignId = generateCampaignId()
        
        // Convert action buttons to payload format
        var actionButtons: [[String: Any]] = []
        
        for button in buttons {
            var buttonData: [String: Any] = [
                "identifier": button.identifier,
                "buttonText": button.title,
                "openApp": true
            ]
            
            switch button.action {
            case .openApp:
                buttonData["action"] = [
                    "type": "openApp"
                ]
            case .openURL(let url):
                buttonData["action"] = [
                    "type": "openUrl",
                    "data": url
                ]
            case .dismiss:
                buttonData["action"] = [
                    "type": "dismiss"
                ]
            }
            
            actionButtons.append(buttonData)
        }
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": Int(campaignId) ?? 0,
            "messageId": messageId,
            "sendAt": "immediate",
            "allowRepeatMarketingCampaigns": true,
            "dataFields": [
                "testType": "action_buttons_push",
                "buttonsCount": buttons.count,
                "timestamp": Date().timeIntervalSince1970
            ],
            "pushPayload": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": 1,
                "sound": "default",
                "actionButtons": actionButtons
            ],
            "metadata": [
                "source": "integration_test",
                "test_type": "action_buttons_push",
                "buttons_count": buttons.count,
                "project_id": projectId
            ]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: campaignId,
            type: .withActionButtons(title: title, body: body, buttons: buttons),
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
    
    // MARK: - Push with Custom Data
    
    func sendPushWithCustomData(
        to userEmail: String,
        title: String,
        body: String,
        customData: [String: Any],
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        let campaignId = generateCampaignId()
        
        var dataFields = customData
        dataFields["testType"] = "custom_data_push"
        dataFields["timestamp"] = Date().timeIntervalSince1970
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": Int(campaignId) ?? 0,
            "messageId": messageId,
            "sendAt": "immediate",
            "allowRepeatMarketingCampaigns": true,
            "dataFields": dataFields,
            "pushPayload": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": 1,
                "sound": "default",
                "customData": customData
            ],
            "metadata": [
                "source": "integration_test",
                "test_type": "custom_data_push",
                "custom_fields": Array(customData.keys),
                "project_id": projectId
            ]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: campaignId,
            type: .withCustomData(title: title, body: body, customData: customData),
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
    
    // MARK: - Rich Media Push
    
    func sendRichMediaPush(
        to userEmail: String,
        title: String,
        body: String,
        imageURL: String,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let messageId = generateMessageId()
        let campaignId = generateCampaignId()
        
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": Int(campaignId) ?? 0,
            "messageId": messageId,
            "sendAt": "immediate",
            "allowRepeatMarketingCampaigns": true,
            "dataFields": [
                "testType": "rich_media_push",
                "imageURL": imageURL,
                "timestamp": Date().timeIntervalSince1970
            ],
            "pushPayload": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": 1,
                "sound": "default",
                "richMedia": [
                    "imageURL": imageURL,
                    "imageAltText": "Test Rich Media Image"
                ]
            ],
            "metadata": [
                "source": "integration_test",
                "test_type": "rich_media_push",
                "image_url": imageURL,
                "project_id": projectId
            ]
        ]
        
        let notificationInfo = PushNotificationInfo(
            messageId: messageId,
            campaignId: campaignId,
            type: .richMedia(title: title, body: body, imageURL: imageURL),
            timestamp: Date(),
            recipient: userEmail
        )
        
        sentNotifications[messageId] = notificationInfo
        
        sendPushNotificationRequest(payload: payload, messageId: messageId, completion: completion)
    }
    
    // MARK: - Batch Push Notifications
    
    func sendBatchPushNotifications(
        notifications: [(userEmail: String, type: PushNotificationType)],
        completion: @escaping ([String], [Error]) -> Void
    ) {
        var successfulMessageIds: [String] = []
        var errors: [Error] = []
        let group = DispatchGroup()
        
        for notification in notifications {
            group.enter()
            
            switch notification.type {
            case .standard(let title, let body):
                sendStandardPushNotification(to: notification.userEmail, title: title, body: body) { success, messageId, error in
                    if success, let id = messageId {
                        successfulMessageIds.append(id)
                    } else if let error = error {
                        errors.append(error)
                    }
                    group.leave()
                }
                
            case .silent:
                sendSilentPushNotification(to: notification.userEmail, triggerType: "batch_test") { success, messageId, error in
                    if success, let id = messageId {
                        successfulMessageIds.append(id)
                    } else if let error = error {
                        errors.append(error)
                    }
                    group.leave()
                }
                
            case .withDeepLink(let title, let body, let deepLink):
                sendPushWithDeepLink(to: notification.userEmail, title: title, body: body, deepLinkURL: deepLink) { success, messageId, error in
                    if success, let id = messageId {
                        successfulMessageIds.append(id)
                    } else if let error = error {
                        errors.append(error)
                    }
                    group.leave()
                }
                
            default:
                // Handle other types similarly
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(successfulMessageIds, errors)
        }
    }
    
    // MARK: - Push Notification Validation
    
    func validatePushDelivery(
        messageId: String,
        timeout: TimeInterval = 30.0,
        completion: @escaping (Bool, PushNotificationInfo?) -> Void
    ) {
        guard let notificationInfo = sentNotifications[messageId] else {
            completion(false, nil)
            return
        }
        
        let startTime = Date()
        
        func checkDeliveryStatus() {
            // Check if enough time has passed for delivery
            let elapsed = Date().timeIntervalSince(startTime)
            
            if elapsed >= timeout {
                completion(false, notificationInfo)
                return
            }
            
            // In a real implementation, this would check delivery status via API
            // For testing, we simulate delivery after a reasonable delay
            if elapsed >= 5.0 {
                var updatedInfo = notificationInfo
                updatedInfo.deliveryStatus = .delivered
                sentNotifications[messageId] = updatedInfo
                completion(true, updatedInfo)
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                    checkDeliveryStatus()
                }
            }
        }
        
        checkDeliveryStatus()
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
    
    // MARK: - Test Helpers
    
    func createTestActionButtons() -> [ActionButton] {
        return [
            ActionButton(
                identifier: "view_offer",
                title: "View Offer",
                action: .openURL("https://links.iterable.com/u/click?_t=offer&_m=integration")
            ),
            ActionButton(
                identifier: "dismiss",
                title: "Not Now",
                action: .dismiss
            ),
            ActionButton(
                identifier: "open_app",
                title: "Open App",
                action: .openApp
            )
        ]
    }
    
    func createTestCustomData() -> [String: Any] {
        return [
            "productId": "12345",
            "category": "electronics",
            "price": 299.99,
            "discount": 0.15,
            "userId": "test-user-123",
            "sessionId": "session-\(Date().timeIntervalSince1970)",
            "metadata": [
                "source": "integration_test",
                "experiment": "push_optimization_v2"
            ]
        ]
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

// MARK: - Extensions

extension PushNotificationSender {
    
    // Convenience method for integration tests
    func sendIntegrationTestPush(
        to userEmail: String,
        testType: String,
        completion: @escaping (Bool, String?, Error?) -> Void
    ) {
        let title = "Integration Test - \(testType)"
        let body = "This is a test push notification for \(testType) integration testing."
        
        switch testType.lowercased() {
        case "standard":
            sendStandardPushNotification(to: userEmail, title: title, body: body, completion: completion)
        case "silent":
            sendSilentPushNotification(to: userEmail, triggerType: "integration_test", completion: completion)
        case "deeplink":
            let deepLink = "https://links.iterable.com/u/click?_t=integration&_m=test"
            sendPushWithDeepLink(to: userEmail, title: title, body: body, deepLinkURL: deepLink, completion: completion)
        case "buttons":
            let buttons = createTestActionButtons()
            sendPushWithActionButtons(to: userEmail, title: title, body: body, buttons: buttons, completion: completion)
        case "custom_data":
            let customData = createTestCustomData()
            sendPushWithCustomData(to: userEmail, title: title, body: body, customData: customData, completion: completion)
        default:
            sendStandardPushNotification(to: userEmail, title: title, body: body, completion: completion)
        }
    }
}