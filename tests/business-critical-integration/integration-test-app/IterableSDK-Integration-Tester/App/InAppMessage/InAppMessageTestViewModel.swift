//
//  InAppMessageTestViewModel.swift
//  IterableSDK-Integration-Tester
//

import SwiftUI
import Combine
import IterableSDK

@MainActor
class InAppMessageTestViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var inAppEnabled: Bool = true
    @Published var messagesAvailable: Int = 0
    @Published var lastSyncTime: String = "Never"
    @Published var messagesShown: Int = 0
    @Published var messagesClicked: Int = 0
    @Published var messagesDismissed: Int = 0
    
    @Published var isCheckingMessages: Bool = false
    @Published var isTriggeringCampaign: Bool = false
    @Published var isClearingMessages: Bool = false
    
    @Published var alertMessage: AlertMessage?
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        loadStatistics()
        updateStatus()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        print("🔄 Starting status monitoring...")
        
        // Update status every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStatus()
            }
        }
        
        updateStatus()
    }
    
    func stopMonitoring() {
        print("🛑 Stopping status monitoring...")
        timer?.invalidate()
        timer = nil
    }
    
    func toggleInApp() {
        print("🔄 Toggle In-App button tapped!")
        inAppEnabled.toggle()
        IterableAPI.inAppManager.isAutoDisplayPaused = !inAppEnabled
        updateStatus()
    }
    
    func checkForMessages() {
        print("🔍 Check Messages button tapped!")
        print("🔍 Manually checking for in-app messages...")
        
        isCheckingMessages = true
        
        // Force sync by toggling auto display
        let isAutoDisplayPaused = IterableAPI.inAppManager.isAutoDisplayPaused
        IterableAPI.inAppManager.isAutoDisplayPaused = false
        IterableAPI.inAppManager.isAutoDisplayPaused = isAutoDisplayPaused
        
        // Check for new messages after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.isCheckingMessages = false
            self.updateStatus()
            UserDefaults.standard.set(Date(), forKey: "iterable_last_in_app_sync")
        }
    }
    
    func triggerCampaign(_ campaignId: Int) {
        print("🎯 Triggering campaign: \(campaignId)")
        
        guard let apiClient = createAPIClient(),
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "API client not initialized or test user email not found")
            return
        }
        
        isTriggeringCampaign = true
        let initialMessageCount = IterableAPI.inAppManager.getMessages().count
        
        apiClient.sendInAppMessage(to: testUserEmail, campaignId: campaignId) { [weak self] success, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if success {
                    print("✅ In-app message triggered for campaign \(campaignId)")
                    
                    // Check for new messages after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        guard let self = self else { return }
                        
                        let newMessageCount = IterableAPI.inAppManager.getMessages().count
                        let difference = newMessageCount - initialMessageCount
                        
                        var message = "Campaign \(campaignId) triggered successfully!"
                        if difference > 0 {
                            message += "\n\n✅ \(difference) new message(s) received"
                            message += "\nTotal messages: \(newMessageCount)"
                            
                            if !IterableAPI.inAppManager.isAutoDisplayPaused {
                                message += "\n\n💡 Message should display automatically"
                            } else {
                                message += "\n\n⚠️ Auto-display is disabled"
                            }
                        } else {
                            message += "\n\n⏳ No new messages yet (may take a moment)"
                        }
                        
                        self.showAlert(title: "Success", message: message)
                        self.updateStatus()
                        self.isTriggeringCampaign = false
                    }
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self.showAlert(title: "Error", message: "Failed to trigger campaign \(campaignId):\n\(errorMessage)")
                    self.isTriggeringCampaign = false
                }
            }
        }
    }
    
    func sendSilentPush(_ campainId: Int) {
        guard let pushSender = createPushSender(),
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Push sender not initialized or test user email not found")
            return
        }
        
        isTriggeringCampaign = true
        pushSender
            .sendSilentPush(to: testUserEmail, campaignId: campainId) {
                [weak self] success,
                messageId,
                error in
            DispatchQueue.main.async {
                
                if success {
                    if let messageId = messageId {
                        print("✅ Silent push sent with message ID: \(messageId)")
                    }
                    // No success alert for silent push - should be silent!
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self?.showAlert(title: "Error", message: "Failed to send silent push notification: \(errorMessage)")
                }
                self?.isTriggeringCampaign = false
            }
        }
    }
    
    func clearMessageQueue() {
        print("🗑️ Clearing message queue...")
        
        guard let apiClient = createAPIClient(),
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "API client not initialized or test user email not found")
            return
        }
        
        isClearingMessages = true
        
        // Clear local messages first
        let localMessages = IterableAPI.inAppManager.getMessages()
        print("🗑️ Clearing \(localMessages.count) local messages")
        
        for message in localMessages {
            IterableAPI.inAppManager.remove(message: message)
        }
        
        // Clear server queue
        apiClient.clearInAppMessageQueue(for: testUserEmail) { [weak self] success in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.isClearingMessages = false
                let remainingMessages = IterableAPI.inAppManager.getMessages().count
                
                if success {
                    let message = "Message queue cleared successfully!\nLocal messages removed: \(localMessages.count)\nRemaining messages: \(remainingMessages)"
                    self.showAlert(title: "Success", message: message)
                } else {
                    let message = "Server queue clear failed, but \(localMessages.count) local messages were removed.\nRemaining messages: \(remainingMessages)"
                    self.showAlert(title: "Partial Success", message: message)
                }
                
                self.updateStatus()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppShown),
            name: .iterableInAppShown,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppClicked),
            name: .iterableInAppClicked,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInAppDismissed),
            name: .iterableInAppDismissed,
            object: nil
        )
    }
    
    @objc private func handleInAppShown(_ notification: Notification) {
        Task { @MainActor in
            messagesShown += 1
            UserDefaults.standard.set(messagesShown, forKey: "in_app_shown_count")
        }
    }
    
    @objc private func handleInAppClicked(_ notification: Notification) {
        Task { @MainActor in
            messagesClicked += 1
            UserDefaults.standard.set(messagesClicked, forKey: "in_app_clicked_count")
        }
    }
    
    @objc private func handleInAppDismissed(_ notification: Notification) {
        Task { @MainActor in
            messagesDismissed += 1
            UserDefaults.standard.set(messagesDismissed, forKey: "in_app_dismissed_count")
        }
    }
    
    private func updateStatus() {
        inAppEnabled = !IterableAPI.inAppManager.isAutoDisplayPaused
        messagesAvailable = IterableAPI.inAppManager.getMessages().count
        
        if let lastSyncDate = UserDefaults.standard.object(forKey: "iterable_last_in_app_sync") as? Date {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            lastSyncTime = formatter.string(from: lastSyncDate)
        } else {
            lastSyncTime = "Never"
        }
        
        loadStatistics()
    }
    
    private func loadStatistics() {
        messagesShown = UserDefaults.standard.integer(forKey: "in_app_shown_count")
        messagesClicked = UserDefaults.standard.integer(forKey: "in_app_clicked_count")
        messagesDismissed = UserDefaults.standard.integer(forKey: "in_app_dismissed_count")
    }
    
    private func showAlert(title: String, message: String) {
        alertMessage = AlertMessage(title: title, message: message)
    }
    
    private func createAPIClient() -> IterableAPIClient? {
        let apiKey = AppDelegate.loadApiKeyFromConfig()
        let serverKey = AppDelegate.loadServerKeyFromConfig()
        let projectId = AppDelegate.loadProjectIdFromConfig()
        
        return IterableAPIClient(
            apiKey: apiKey,
            serverKey: serverKey,
            projectId: projectId
        )
    }
    
    private func createPushSender() -> PushNotificationSender? {
        guard let apiClient = createAPIClient() else { return nil }
        
        let serverKey = AppDelegate.loadServerKeyFromConfig()
        let projectId = AppDelegate.loadProjectIdFromConfig()
        
        return PushNotificationSender(
            apiClient: apiClient,
            serverKey: serverKey,
            projectId: projectId
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let iterableInAppShown = Notification.Name("IterableInAppShown")
    static let iterableInAppClicked = Notification.Name("IterableInAppClicked")
    static let iterableInAppDismissed = Notification.Name("IterableInAppDismissed")
}

