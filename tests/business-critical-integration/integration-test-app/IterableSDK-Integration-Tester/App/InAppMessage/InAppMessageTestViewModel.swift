//
//  InAppMessageTestViewModel.swift
//  IterableSDK-Integration-Tester
//

import SwiftUI
import Combine
import WebKit
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
    private var apiClient: IterableAPIClient?
    private var pushSender: PushNotificationSender?
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        loadStatistics()
        updateStatus()
        apiClient = createAPIClient()
        pushSender = createPushSender()
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
        
        guard let apiClient,
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
    
    func sendSilentPush(_ campaignId: Int) {
        guard let pushSender,
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Push sender not initialized or test user email not found")
            return
        }
        
        isTriggeringCampaign = true
        pushSender.sendSilentPush(to: testUserEmail, campaignId: campaignId) {
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
    
    func showLocalFullScreenIAM() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let pocVC = FullScreenPOCViewController()
        pocVC.modalPresentationStyle = .overFullScreen
        topVC.present(pocVC, animated: false)
    }

    func clearMessageQueue() {
        print("🗑️ Clearing message queue...")
        
        guard let apiClient,
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

// MARK: - Full Screen IAM Proof of Concept

/// Temporary POC view controller to test full-screen IAM presentation
/// using .overFullScreen modal style instead of a custom UIWindow.
class FullScreenPOCViewController: UIViewController, WKNavigationDelegate {
    private lazy var webView: WKWebView = {
        let wv = WKWebView(frame: .zero)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.bounces = false
        wv.navigationDelegate = self
        return wv
    }()

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view background to match the HTML background so
        // the safe area gaps (notch/status bar) are filled with the same color
        view.backgroundColor = UIColor(red: 106/255, green: 27/255, blue: 154/255, alpha: 1)

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        webView.loadHTMLString(Self.fullScreenHTML, baseURL: URL(string: ""))
    }

    // Catch link taps to dismiss
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            dismiss(animated: false)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    private static let fullScreenHTML = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body {
                height: 100%;
                background-color: #6A1B9A;
                color: white;
                font-family: -apple-system, sans-serif;
            }
            body {
                display: flex;
                flex-direction: column;
                padding-top: env(safe-area-inset-top);
                padding-right: env(safe-area-inset-right);
                padding-bottom: env(safe-area-inset-bottom);
                padding-left: env(safe-area-inset-left);
            }
            .content {
                flex: 1;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                padding: 20px;
                text-align: center;
            }
            h1 { font-size: 28px; margin-bottom: 16px; }
            p { font-size: 16px; opacity: 0.9; margin-bottom: 16px; line-height: 1.5; }
            .close-btn {
                display: inline-block;
                background: white;
                color: #6A1B9A;
                text-decoration: none;
                padding: 14px 40px;
                border-radius: 25px;
                font-size: 18px;
                font-weight: 600;
                margin-top: 16px;
            }
        </style>
    </head>
    <body>
        <div class="content">
            <h1>Full Screen IAM POC</h1>
            <p>This proves .overFullScreen modal presentation works for full-screen in-app messages.</p>
            <p>The purple background extends behind the safe area (status bar / notch / Dynamic Island), while this text content stays within the safe area.</p>
            <p>viewport-fit=cover + CSS env(safe-area-inset-*) handles safe area padding in HTML.</p>
            <a href="iterable://dismiss" class="close-btn">Close</a>
        </div>
    </body>
    </html>
    """
}

