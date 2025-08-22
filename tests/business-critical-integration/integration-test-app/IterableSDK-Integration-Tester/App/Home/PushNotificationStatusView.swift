import UIKit
import UserNotifications

final class PushNotificationStatusView: UIView {
    
    // MARK: - UI Components
    
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Push Notification Status"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let authorizationStatusView = StatusRowView(title: "Authorization")
    private let alertStatusView = StatusRowView(title: "Alert Setting")
    private let badgeStatusView = StatusRowView(title: "Badge Setting")
    private let soundStatusView = StatusRowView(title: "Sound Setting")
    private let deviceTokenStatusView = StatusRowView(title: "Device Token")
    private let deviceTokenDetailView = StatusRowView(title: "Token Details")
    
    private var statusTimer: Timer?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        startObserving()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        startObserving()
    }
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(titleLabel)
        containerStackView.addArrangedSubview(authorizationStatusView)
        containerStackView.addArrangedSubview(alertStatusView)
        containerStackView.addArrangedSubview(badgeStatusView)
        containerStackView.addArrangedSubview(soundStatusView)
        containerStackView.addArrangedSubview(deviceTokenStatusView)
        containerStackView.addArrangedSubview(deviceTokenDetailView)
        
        // Add accessibility identifiers for testing
        authorizationStatusView.accessibilityIdentifier = "push-authorization-status"
        authorizationStatusView.setValueAccessibilityIdentifier("push-authorization-value")
        alertStatusView.accessibilityIdentifier = "push-alert-status"
        alertStatusView.setValueAccessibilityIdentifier("push-alert-value")
        badgeStatusView.accessibilityIdentifier = "push-badge-status"
        badgeStatusView.setValueAccessibilityIdentifier("push-badge-value")
        soundStatusView.accessibilityIdentifier = "push-sound-status"
        soundStatusView.setValueAccessibilityIdentifier("push-sound-value")
        deviceTokenStatusView.accessibilityIdentifier = "push-device-token-status"
        deviceTokenStatusView.setValueAccessibilityIdentifier("push-device-token-value")
        deviceTokenDetailView.accessibilityIdentifier = "push-device-token-detail"
        deviceTokenDetailView.setValueAccessibilityIdentifier("push-device-token-detail-value")
        
        // Make device token detail tappable for copying
        deviceTokenDetailView.makeValueTappable(target: self, action: #selector(copyDeviceTokenToClipboard))
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        updateStatus()
    }
    
    // MARK: - Status Observing
    
    private func startObserving() {
        // Update status every 0.5 seconds to observe changes
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateStatus()
            }
        }
    }
    
    private func stopObserving() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    private func updateStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.updateUI(with: settings)
            }
        }
    }
    
    private func updateUI(with settings: UNNotificationSettings) {
        // Authorization Status
        let authStatus = settings.authorizationStatus
        let authText: String
        let authColor: UIColor
        
        switch authStatus {
        case .authorized:
            authText = "✓ Authorized"
            authColor = .systemGreen
        case .denied:
            authText = "✗ Denied"
            authColor = .systemRed
        case .notDetermined:
            authText = "? Not Determined"
            authColor = .systemOrange
        case .provisional:
            authText = "⚠ Provisional"
            authColor = .systemYellow
        case .ephemeral:
            authText = "⏱ Ephemeral"
            authColor = .systemBlue
        @unknown default:
            authText = "? Unknown"
            authColor = .systemGray
        }
        
        authorizationStatusView.setValue(authText, color: authColor)
        
        // Alert Setting
        let alertText: String
        let alertColor: UIColor
        
        switch settings.alertSetting {
        case .enabled:
            alertText = "✓ Enabled"
            alertColor = .systemGreen
        case .disabled:
            alertText = "✗ Disabled"
            alertColor = .systemRed
        case .notSupported:
            alertText = "⚠ Not Supported"
            alertColor = .systemOrange
        @unknown default:
            alertText = "? Unknown"
            alertColor = .systemGray
        }
        
        alertStatusView.setValue(alertText, color: alertColor)
        
        // Badge Setting
        let badgeText: String
        let badgeColor: UIColor
        
        switch settings.badgeSetting {
        case .enabled:
            badgeText = "✓ Enabled"
            badgeColor = .systemGreen
        case .disabled:
            badgeText = "✗ Disabled"
            badgeColor = .systemRed
        case .notSupported:
            badgeText = "⚠ Not Supported"
            badgeColor = .systemOrange
        @unknown default:
            badgeText = "? Unknown"
            badgeColor = .systemGray
        }
        
        badgeStatusView.setValue(badgeText, color: badgeColor)
        
        // Sound Setting
        let soundText: String
        let soundColor: UIColor
        
        switch settings.soundSetting {
        case .enabled:
            soundText = "✓ Enabled"
            soundColor = .systemGreen
        case .disabled:
            soundText = "✗ Disabled"
            soundColor = .systemRed
        case .notSupported:
            soundText = "⚠ Not Supported"
            soundColor = .systemOrange
        @unknown default:
            soundText = "? Unknown"
            soundColor = .systemGray
        }
        
        soundStatusView.setValue(soundText, color: soundColor)
        
        // Device Token Status - only show as registered if we received token in current session
        if AppDelegate.hasValidDeviceTokenInCurrentSession(), let deviceToken = AppDelegate.getRegisteredDeviceToken() {
            deviceTokenStatusView.setValue("✓ Registered", color: .systemGreen)
            
            // Show token details with timestamp
            if let timestamp = AppDelegate.getDeviceTokenTimestamp() {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                let timeString = formatter.string(from: timestamp)
                let tokenPreview = String(deviceToken.prefix(16)) + "..."
                deviceTokenDetailView.setValue("\(tokenPreview) (\(timeString))", color: .systemBlue)
            } else {
                let tokenPreview = String(deviceToken.prefix(16)) + "..."
                deviceTokenDetailView.setValue(tokenPreview, color: .systemBlue)
            }
        } else {
            deviceTokenStatusView.setValue("✗ Not Registered", color: .systemRed)
            deviceTokenDetailView.setValue("No token available", color: .systemGray)
        }
    }
    
    @objc private func copyDeviceTokenToClipboard() {
        guard let deviceToken = AppDelegate.getRegisteredDeviceToken() else {
            print("⚠️ No device token available to copy")
            return
        }
        
        UIPasteboard.general.string = deviceToken
        print("📋 Device token copied to clipboard: \(String(deviceToken.prefix(16)))...")
        
        // Show visual feedback
        if let parentVC = findViewController() {
            let alert = UIAlertController(
                title: "Token Copied",
                message: "Device token has been copied to clipboard",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            parentVC.present(alert, animated: true)
        }
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

// MARK: - StatusRowView

private final class StatusRowView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Ensure title label takes up available space and value label shrinks to fit
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
    
    func setValue(_ value: String, color: UIColor) {
        valueLabel.text = value
        valueLabel.textColor = color
    }
    
    func setValueAccessibilityIdentifier(_ identifier: String) {
        valueLabel.accessibilityIdentifier = identifier
    }
    
    func getValue() -> String? {
        return valueLabel.text
    }
    
    func makeValueTappable(target: Any?, action: Selector) {
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        valueLabel.isUserInteractionEnabled = true
        valueLabel.addGestureRecognizer(tapGesture)
    }
}
