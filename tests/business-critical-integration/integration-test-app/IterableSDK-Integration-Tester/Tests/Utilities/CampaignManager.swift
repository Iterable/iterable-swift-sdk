import Foundation

class CampaignManager {
    
    // MARK: - Properties
    
    private let apiClient: IterableAPIClient
    private let projectId: String
    private var activeCampaigns: [String: CampaignInfo] = [:]
    private var createdLists: [String: ListInfo] = [:]
    
    // Configuration
    private let campaignPrefix = "integration-test"
    private let listPrefix = "test-list"
    
    // MARK: - Initialization
    
    init(apiClient: IterableAPIClient, projectId: String) {
        self.apiClient = apiClient
        self.projectId = projectId
    }
    
    // MARK: - Data Structures
    
    struct CampaignInfo {
        let campaignId: String
        let name: String
        let type: CampaignType
        let createdAt: Date
        let recipientEmail: String
        var status: CampaignStatus = .created
        
        enum CampaignType {
            case pushNotification
            case inAppMessage
            case embeddedMessage
            case sms
            case email
        }
        
        enum CampaignStatus {
            case created
            case active
            case completed
            case failed
        }
    }
    
    struct ListInfo {
        let listId: String
        let name: String
        let createdAt: Date
        var subscriberCount: Int = 0
    }
    
    // MARK: - Push Notification Campaigns
    
    func createPushNotificationCampaign(
        name: String,
        recipientEmail: String,
        title: String,
        body: String,
        deepLinkURL: String? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let campaignName = "\(campaignPrefix)-push-\(name)-\(timestampSuffix())"
        
        var payload: [String: Any] = [
            "name": campaignName,
            "recipientEmail": recipientEmail,
            "messageMedium": "Push",
            "sendAt": "immediate",
            "campaignState": "Ready",
            "dataFields": [
                "testType": "push_notification",
                "campaignName": name,
                "projectId": projectId
            ],
            "pushPayload": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": 1,
                "sound": "default"
            ],
            "metadata": [
                "source": "integration_test",
                "campaign_type": "push_notification",
                "test_name": name
            ]
        ]
        
        // Add deep link if provided
        if let deepLink = deepLinkURL {
            payload["defaultAction"] = [
                "type": "openUrl",
                "data": deepLink
            ]
            payload["pushPayload"] = (payload["pushPayload"] as! [String: Any]).merging([
                "customData": [
                    "deepLink": deepLink,
                    "action": "openUrl"
                ]
            ]) { _, new in new }
        }
        
        apiClient.createCampaign(payload: payload) { [weak self] success, campaignId in
            if success, let id = campaignId {
                let campaignInfo = CampaignInfo(
                    campaignId: id,
                    name: campaignName,
                    type: .pushNotification,
                    createdAt: Date(),
                    recipientEmail: recipientEmail
                )
                self?.activeCampaigns[id] = campaignInfo
                completion(true, id)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - In-App Message Campaigns
    
    func createInAppMessageCampaign(
        name: String,
        recipientEmail: String,
        htmlContent: String,
        displaySettings: [String: Any] = [:],
        completion: @escaping (Bool, String?) -> Void
    ) {
        let campaignName = "\(campaignPrefix)-inapp-\(name)-\(timestampSuffix())"
        
        var defaultDisplaySettings: [String: Any] = [
            "displayMode": "Immediate",
            "backgroundAlpha": 0.5,
            "position": "Center",
            "padding": [
                "top": 0,
                "left": 0,
                "bottom": 0,
                "right": 0
            ]
        ]
        
        // Merge with provided settings
        for (key, value) in displaySettings {
            defaultDisplaySettings[key] = value
        }
        
        let payload: [String: Any] = [
            "name": campaignName,
            "recipientEmail": recipientEmail,
            "messageMedium": "InApp",
            "sendAt": "immediate",
            "campaignState": "Ready",
            "dataFields": [
                "testType": "in_app_message",
                "campaignName": name,
                "projectId": projectId
            ],
            "template": [
                "html": htmlContent,
                "displaySettings": defaultDisplaySettings,
                "closeButton": [
                    "isRequiredToDismissMessage": false,
                    "position": "TopRight",
                    "size": "Regular",
                    "color": "#FFFFFF",
                    "sideMargin": 10,
                    "topMargin": 10
                ]
            ],
            "metadata": [
                "source": "integration_test",
                "campaign_type": "in_app_message",
                "test_name": name
            ]
        ]
        
        apiClient.createCampaign(payload: payload) { [weak self] success, campaignId in
            if success, let id = campaignId {
                let campaignInfo = CampaignInfo(
                    campaignId: id,
                    name: campaignName,
                    type: .inAppMessage,
                    createdAt: Date(),
                    recipientEmail: recipientEmail
                )
                self?.activeCampaigns[id] = campaignInfo
                completion(true, id)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - Embedded Message Campaigns
    
    func createEmbeddedMessageCampaign(
        name: String,
        placementId: String,
        listId: String? = nil,
        content: [String: Any],
        completion: @escaping (Bool, String?) -> Void
    ) {
        let campaignName = "\(campaignPrefix)-embedded-\(name)-\(timestampSuffix())"
        
        var payload: [String: Any] = [
            "name": campaignName,
            "messageMedium": "Embedded",
            "sendAt": "immediate",
            "campaignState": "Ready",
            "dataFields": [
                "testType": "embedded_message",
                "campaignName": name,
                "projectId": projectId,
                "placementId": placementId
            ],
            "template": [
                "placementId": placementId,
                "content": content,
                "displaySettings": [
                    "position": "top",
                    "animationType": "slideDown",
                    "duration": 0,
                    "autoHide": false
                ]
            ],
            "metadata": [
                "source": "integration_test",
                "campaign_type": "embedded_message",
                "test_name": name,
                "placement_id": placementId
            ]
        ]
        
        // Add list targeting if provided
        if let list = listId {
            payload["listIds"] = [Int(list) ?? 0]
            payload["segmentationListId"] = Int(list) ?? 0
        }
        
        apiClient.createCampaign(payload: payload) { [weak self] success, campaignId in
            if success, let id = campaignId {
                let campaignInfo = CampaignInfo(
                    campaignId: id,
                    name: campaignName,
                    type: .embeddedMessage,
                    createdAt: Date(),
                    recipientEmail: "" // Embedded messages use list targeting
                )
                self?.activeCampaigns[id] = campaignInfo
                completion(true, id)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - SMS Campaigns
    
    func createSMSCampaign(
        name: String,
        recipientEmail: String,
        message: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let campaignName = "\(campaignPrefix)-sms-\(name)-\(timestampSuffix())"
        
        let payload: [String: Any] = [
            "name": campaignName,
            "recipientEmail": recipientEmail,
            "messageMedium": "SMS",
            "sendAt": "immediate",
            "campaignState": "Ready",
            "dataFields": [
                "testType": "sms",
                "campaignName": name,
                "projectId": projectId
            ],
            "template": [
                "message": message
            ],
            "metadata": [
                "source": "integration_test",
                "campaign_type": "sms",
                "test_name": name
            ]
        ]
        
        apiClient.createCampaign(payload: payload) { [weak self] success, campaignId in
            if success, let id = campaignId {
                let campaignInfo = CampaignInfo(
                    campaignId: id,
                    name: campaignName,
                    type: .sms,
                    createdAt: Date(),
                    recipientEmail: recipientEmail
                )
                self?.activeCampaigns[id] = campaignInfo
                completion(true, id)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - List Management
    
    func createTestList(
        name: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let listName = "\(listPrefix)-\(name)-\(timestampSuffix())"
        
        apiClient.createList(name: listName) { [weak self] success, listId in
            if success, let id = listId {
                let listInfo = ListInfo(
                    listId: id,
                    name: listName,
                    createdAt: Date()
                )
                self?.createdLists[id] = listInfo
                completion(true, id)
            } else {
                completion(false, nil)
            }
        }
    }
    
    func subscribeUserToList(
        listId: String,
        userEmail: String,
        completion: @escaping (Bool) -> Void
    ) {
        apiClient.subscribeToList(listId: listId, userEmail: userEmail) { [weak self] success in
            if success {
                // Update subscriber count
                if var listInfo = self?.createdLists[listId] {
                    listInfo.subscriberCount += 1
                    self?.createdLists[listId] = listInfo
                }
            }
            completion(success)
        }
    }
    
    func unsubscribeUserFromList(
        listId: String,
        userEmail: String,
        completion: @escaping (Bool) -> Void
    ) {
        apiClient.unsubscribeFromList(listId: listId, userEmail: userEmail) { [weak self] success in
            if success {
                // Update subscriber count
                if var listInfo = self?.createdLists[listId] {
                    listInfo.subscriberCount = max(0, listInfo.subscriberCount - 1)
                    self?.createdLists[listId] = listInfo
                }
            }
            completion(success)
        }
    }
    
    // MARK: - Campaign Templates
    
    func createStandardInAppMessageHTML() -> String {
        return """
        <div style='background: linear-gradient(135deg, #007AFF, #5856D6); color: white; padding: 30px; text-align: center; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.15); font-family: -apple-system, BlinkMacSystemFont, sans-serif;'>
            <h2 style='margin: 0 0 15px 0; font-size: 24px; font-weight: 600;'>🎉 Special Offer!</h2>
            <p style='margin: 0 0 20px 0; font-size: 16px; line-height: 1.4; opacity: 0.9;'>Don't miss out on our exclusive integration test promotion.</p>
            <div style='margin: 20px 0;'>
                <a href='https://links.iterable.com/u/click?_t=inapp-test&_m=integration' 
                   style='background: white; color: #007AFF; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: 600; display: inline-block; margin: 5px;'>
                   Learn More
                </a>
                <button onclick='iterable://dismiss' 
                        style='background: transparent; color: white; border: 2px solid white; padding: 12px 24px; border-radius: 8px; font-weight: 600; margin: 5px; cursor: pointer;'>
                   Maybe Later
                </button>
            </div>
        </div>
        """
    }
    
    func createEmbeddedMessageContent() -> [String: Any] {
        return [
            "type": "banner",
            "backgroundColor": "#FF6B35",
            "textColor": "#FFFFFF",
            "title": "🔥 Limited Time Offer",
            "body": "Get 25% off your next purchase. Use code TEST25 at checkout!",
            "buttonText": "Shop Now",
            "buttonAction": [
                "type": "openUrl",
                "data": "https://links.iterable.com/u/click?_t=embedded-test&_m=integration"
            ],
            "dismissAction": [
                "type": "dismiss"
            ],
            "imageURL": "https://via.placeholder.com/400x200/FF6B35/FFFFFF?text=Special+Offer"
        ]
    }
    
    // MARK: - Batch Operations
    
    func createMultipleCampaigns(
        configurations: [CampaignConfiguration],
        completion: @escaping ([String], [Error]) -> Void
    ) {
        var createdCampaignIds: [String] = []
        var errors: [Error] = []
        let group = DispatchGroup()
        
        for config in configurations {
            group.enter()
            
            switch config.type {
            case .pushNotification:
                createPushNotificationCampaign(
                    name: config.name,
                    recipientEmail: config.recipientEmail,
                    title: config.title ?? "Test Push",
                    body: config.body ?? "Test push notification body",
                    deepLinkURL: config.deepLinkURL
                ) { success, campaignId in
                    if success, let id = campaignId {
                        createdCampaignIds.append(id)
                    } else {
                        errors.append(CampaignError.creationFailed)
                    }
                    group.leave()
                }
                
            case .inAppMessage:
                createInAppMessageCampaign(
                    name: config.name,
                    recipientEmail: config.recipientEmail,
                    htmlContent: config.htmlContent ?? createStandardInAppMessageHTML()
                ) { success, campaignId in
                    if success, let id = campaignId {
                        createdCampaignIds.append(id)
                    } else {
                        errors.append(CampaignError.creationFailed)
                    }
                    group.leave()
                }
                
            case .embeddedMessage:
                createEmbeddedMessageCampaign(
                    name: config.name,
                    placementId: config.placementId ?? "test-placement",
                    listId: config.listId,
                    content: config.embeddedContent ?? createEmbeddedMessageContent()
                ) { success, campaignId in
                    if success, let id = campaignId {
                        createdCampaignIds.append(id)
                    } else {
                        errors.append(CampaignError.creationFailed)
                    }
                    group.leave()
                }
                
            case .sms:
                createSMSCampaign(
                    name: config.name,
                    recipientEmail: config.recipientEmail,
                    message: config.smsMessage ?? "Test SMS message with deep link: https://links.iterable.com/u/click?_t=sms-test&_m=integration"
                ) { success, campaignId in
                    if success, let id = campaignId {
                        createdCampaignIds.append(id)
                    } else {
                        errors.append(CampaignError.creationFailed)
                    }
                    group.leave()
                }
                
            default:
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(createdCampaignIds, errors)
        }
    }
    
    // MARK: - Campaign Management
    
    func updateCampaignStatus(campaignId: String, status: CampaignInfo.CampaignStatus) {
        if var campaignInfo = activeCampaigns[campaignId] {
            campaignInfo.status = status
            activeCampaigns[campaignId] = campaignInfo
        }
    }
    
    func getCampaignInfo(campaignId: String) -> CampaignInfo? {
        return activeCampaigns[campaignId]
    }
    
    func getAllActiveCampaigns() -> [CampaignInfo] {
        return Array(activeCampaigns.values)
    }
    
    func getActiveCampaigns(for userEmail: String) -> [CampaignInfo] {
        return activeCampaigns.values.filter { $0.recipientEmail == userEmail }
    }
    
    func getActiveCampaigns(ofType type: CampaignInfo.CampaignType) -> [CampaignInfo] {
        return activeCampaigns.values.filter { $0.type == type }
    }
    
    // MARK: - Cleanup Operations
    
    func cleanupAllCampaigns(completion: @escaping (Bool) -> Void) {
        let campaignIds = Array(activeCampaigns.keys)
        
        if campaignIds.isEmpty {
            completion(true)
            return
        }
        
        apiClient.cleanupCampaigns(campaignIds: campaignIds) { [weak self] success in
            if success {
                self?.activeCampaigns.removeAll()
            }
            completion(success)
        }
    }
    
    func cleanupAllLists(completion: @escaping (Bool) -> Void) {
        let listIds = Array(createdLists.keys)
        
        if listIds.isEmpty {
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        var allSucceeded = true
        
        for listId in listIds {
            group.enter()
            apiClient.deleteList(listId: listId) { success in
                if !success {
                    allSucceeded = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            if allSucceeded {
                self?.createdLists.removeAll()
            }
            completion(allSucceeded)
        }
    }
    
    func cleanupCampaign(campaignId: String, completion: @escaping (Bool) -> Void) {
        apiClient.deleteCampaign(campaignId: campaignId) { [weak self] success in
            if success {
                self?.activeCampaigns.removeValue(forKey: campaignId)
            }
            completion(success)
        }
    }
    
    // MARK: - Utility Methods
    
    private func timestampSuffix() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
    func getCampaignStatistics() -> CampaignStatistics {
        let campaigns = Array(activeCampaigns.values)
        return CampaignStatistics(
            totalCampaigns: campaigns.count,
            pushCampaigns: campaigns.filter { $0.type == .pushNotification }.count,
            inAppCampaigns: campaigns.filter { $0.type == .inAppMessage }.count,
            embeddedCampaigns: campaigns.filter { $0.type == .embeddedMessage }.count,
            smsCampaigns: campaigns.filter { $0.type == .sms }.count,
            activeCampaigns: campaigns.filter { $0.status == .active }.count,
            completedCampaigns: campaigns.filter { $0.status == .completed }.count,
            totalLists: createdLists.count
        )
    }
}

// MARK: - Supporting Types

struct CampaignConfiguration {
    let name: String
    let type: CampaignManager.CampaignInfo.CampaignType
    let recipientEmail: String
    let title: String?
    let body: String?
    let deepLinkURL: String?
    let htmlContent: String?
    let placementId: String?
    let listId: String?
    let embeddedContent: [String: Any]?
    let smsMessage: String?
}

struct CampaignStatistics {
    let totalCampaigns: Int
    let pushCampaigns: Int
    let inAppCampaigns: Int
    let embeddedCampaigns: Int
    let smsCampaigns: Int
    let activeCampaigns: Int
    let completedCampaigns: Int
    let totalLists: Int
}

enum CampaignError: Error, LocalizedError {
    case creationFailed
    case invalidConfiguration
    case listNotFound
    case campaignNotFound
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create campaign"
        case .invalidConfiguration:
            return "Invalid campaign configuration"
        case .listNotFound:
            return "List not found"
        case .campaignNotFound:
            return "Campaign not found"
        }
    }
}

// MARK: - Extensions

extension CampaignManager {
    
    // Convenience methods for integration tests
    func createIntegrationTestSuite(
        userEmail: String,
        completion: @escaping ([String], [Error]) -> Void
    ) {
        let configurations = [
            CampaignConfiguration(
                name: "push-test",
                type: .pushNotification,
                recipientEmail: userEmail,
                title: "Integration Test Push",
                body: "Testing push notification functionality",
                deepLinkURL: "https://links.iterable.com/u/click?_t=push-test&_m=integration",
                htmlContent: nil,
                placementId: nil,
                listId: nil,
                embeddedContent: nil,
                smsMessage: nil
            ),
            CampaignConfiguration(
                name: "inapp-test",
                type: .inAppMessage,
                recipientEmail: userEmail,
                title: nil,
                body: nil,
                deepLinkURL: nil,
                htmlContent: createStandardInAppMessageHTML(),
                placementId: nil,
                listId: nil,
                embeddedContent: nil,
                smsMessage: nil
            ),
            CampaignConfiguration(
                name: "sms-test",
                type: .sms,
                recipientEmail: userEmail,
                title: nil,
                body: nil,
                deepLinkURL: nil,
                htmlContent: nil,
                placementId: nil,
                listId: nil,
                embeddedContent: nil,
                smsMessage: "Integration test SMS with link: https://links.iterable.com/u/click?_t=sms-test&_m=integration"
            )
        ]
        
        createMultipleCampaigns(configurations: configurations, completion: completion)
    }
}