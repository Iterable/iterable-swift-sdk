import UIKit
import UserNotifications

final class PushNotificationTestViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let statusView = PushNotificationStatusView()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register for Remote Notifications", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.accessibilityIdentifier = "register-push-notifications-button"
        return button
    }()
    
    private let openSettingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open Notification Settings", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.accessibilityIdentifier = "open-settings-button"
        return button
    }()
    
    private let testPushButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test Local Notification", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.accessibilityIdentifier = "test-local-notification-button"
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Push Notification Testing"
        
        let stack = UIStackView(arrangedSubviews: [
            registerButton,
            openSettingsButton,
            testPushButton,
            statusView
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        registerButton.addTarget(self, action: #selector(registerForNotifications), for: .touchUpInside)
        openSettingsButton.addTarget(self, action: #selector(openNotificationSettings), for: .touchUpInside)
        testPushButton.addTarget(self, action: #selector(testLocalNotification), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func registerForNotifications() {
        AppDelegate.registerForPushNotifications()
        
        // Show immediate feedback
        showAlert(
            title: "Push Notification Request",
            message: "Push notification permission request sent. Check the console and status view for updates."
        )
    }
    
    @objc private func openNotificationSettings() {
        print("⚙️ Opening notification settings...")
        
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            showAlert(
                title: "Error",
                message: "Unable to open Settings app"
            )
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
    
    @objc private func testLocalNotification() {
        print("🧪 Testing local notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from the Integration Test App"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule test notification: \(error.localizedDescription)")
                    self?.showAlert(
                        title: "Error",
                        message: "Failed to schedule test notification: \(error.localizedDescription)"
                    )
                } else {
                    print("✅ Test notification scheduled")
                    self?.showAlert(
                        title: "Success",
                        message: "Test notification scheduled! It should appear in 1 second."
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
