//
//  EmbeddedMessageTestViewModel.swift
//  IterableSDK-Integration-Tester
//

import Foundation
import SwiftUI
import IterableSDK
import Combine

class EmbeddedMessageTestViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isEmbeddedEnabled = true
    @Published var messagesCount = 0
    @Published var userEligibilityStatus = "Unknown"
    @Published var isPremiumMember = false
    @Published var profileUpdateStatus = "Not Updated"
    @Published var campaignStatus = "No Campaign"
    @Published var embeddedMessages: [IterableEmbeddedMessage] = []
    @Published var alertMessage: AlertMessage?
    
    // MARK: - Private Properties
    
    private var updateTimer: Timer?
    private var apiClient: IterableAPIClient?
    private var pushSender: PushNotificationSender?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupEmbeddedUpdateListener()
        apiClient = createAPIClient()
        pushSender = createPushSender()
    }
    
    // MARK: - Lifecycle
    
    func startMonitoring() {
        print("📡 Starting embedded message monitoring")
        
        // Start periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshState()
        }
        
        // Initial state refresh
        refreshState()
    }
    
    func stopMonitoring() {
        print("🛑 Stopping embedded message monitoring")
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Setup
    
    private func setupEmbeddedUpdateListener() {
        // Add listener for embedded message updates
        let embeddedManager = IterableAPI.embeddedManager
        embeddedManager.addUpdateListener(self)
        print("✅ Embedded update listener added")
    }
    
    // MARK: - State Management
    
    func refreshState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Get embedded messages
            let embeddedManager = IterableAPI.embeddedManager
            self.embeddedMessages = embeddedManager.getMessages()
            self.messagesCount = self.embeddedMessages.count
            
            // Update eligibility status based on profile
            self.userEligibilityStatus = self.isPremiumMember ? "✓ Eligible" : "✗ Ineligible"
        }
    }
    
    // MARK: - User Profile Actions
    
    func updateUserProfile() {
        print("👤 Updating user profile - Premium Member: \(isPremiumMember)")
        
        let dataFields: [String: Any] = [
            "isPremium": isPremiumMember,
            "membershipLevel": isPremiumMember ? "premium" : "standard"
        ]
        
        IterableAPI.updateUser(dataFields, mergeNestedObjects: false)
        
        DispatchQueue.main.async { [weak self] in
            self?.profileUpdateStatus = "✓ Updated at \(Date().formatted(date: .omitted, time: .shortened))"
            self?.userEligibilityStatus = self?.isPremiumMember == true ? "✓ Eligible" : "✗ Ineligible"
        }
        
        print("✅ User profile updated with premium status: \(isPremiumMember)")
    }
    
    // MARK: - Campaign Actions
    
    func sendSilentPushForSync() {
        print("🔔 Sending silent push notification for sync...")
        
        guard let pushSender,
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Push sender not initialized or test user email not found")
            return
        }
        
        pushSender.sendSilentPush(to: testUserEmail, campaignId: 15418588) {
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
            }
        }
    }
    
    // MARK: - Message Actions
    
    func syncMessages() {
        print("🔄 Syncing embedded messages...")
        
        let embeddedManager = IterableAPI.embeddedManager
        //            print("❌ Embedded manager not available")
        //            showAlert(title: "Error", message: "Embedded messaging not enabled")
        //            return
        //        }
        
        embeddedManager.syncMessages { [weak self] in
            print("✅ Embedded messages synced")
            DispatchQueue.main.async {
                self?.refreshState()
            }
        }
    }
    
    func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonId: String?, url: String) {
        print("👆 Handling embedded message click - Button: \(buttonId ?? "default"), URL: \(url)")
        
        let embeddedManager = IterableAPI.embeddedManager
        //            print("❌ Embedded manager not available")
        //            return
        //        }
        
        // Track the click
        embeddedManager.handleEmbeddedClick(message: message, buttonIdentifier: buttonId, clickedUrl: url)
        
//        // Handle deep link if present
//        if !url.isEmpty {
//            print("🔗 Processing deep link: \(url)")
//            if let deepLinkURL = URL(string: url) {
//                IterableAPI.handle(universalLink: deepLinkURL)
//            }
//        }
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Message Clicked", message: "Embedded message interaction tracked")
        }
    }
    
    func clearMessages() {
        print("🗑️ Clearing embedded messages...")
        
        // In a real scenario, you'd call an API to clear messages
        // For testing, we'll just refresh to show current state
        syncMessages()
        
        DispatchQueue.main.async { [weak self] in
            self?.showAlert(title: "Success", message: "Messages cleared")
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.alertMessage = AlertMessage(title: title, message: message)
        }
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

// MARK: - IterableEmbeddedUpdateDelegate

extension EmbeddedMessageTestViewModel: IterableEmbeddedUpdateDelegate {
    func onMessagesUpdated() {
        print("📨 Embedded messages updated callback received")
        DispatchQueue.main.async { [weak self] in
            self?.refreshState()
        }
    }
    
    func onEmbeddedMessagingDisabled() {
        print("⚠️ Embedded messaging disabled")
        DispatchQueue.main.async { [weak self] in
            self?.isEmbeddedEnabled = false
            self?.embeddedMessages = []
            self?.messagesCount = 0
        }
    }
}

