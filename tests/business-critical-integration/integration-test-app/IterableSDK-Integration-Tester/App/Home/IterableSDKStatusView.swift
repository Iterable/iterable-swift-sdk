import UIKit
import IterableSDK
import ObjectiveC

final class IterableSDKStatusView: UIView {
    
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
        label.text = "Iterable SDK Status"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let initializationStatusView = StatusRowView(title: "SDK Initialized")
    private let emailStatusView = StatusRowView(title: "Email")
    private let userIdStatusView = StatusRowView(title: "User ID")
    
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
        containerStackView.addArrangedSubview(initializationStatusView)
        containerStackView.addArrangedSubview(emailStatusView)
        containerStackView.addArrangedSubview(userIdStatusView)
        
        // Add accessibility identifiers for testing
        initializationStatusView.accessibilityIdentifier = "sdk-initialization-status"
        initializationStatusView.setValueAccessibilityIdentifier("sdk-ready-indicator")
        emailStatusView.accessibilityIdentifier = "sdk-email-status"
        emailStatusView.setValueAccessibilityIdentifier("sdk-email-value")
        userIdStatusView.accessibilityIdentifier = "sdk-user-id-status"
        userIdStatusView.setValueAccessibilityIdentifier("sdk-user-id-value")
        
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
        // Check SDK initialization status
        let isInitialized = isSDKInitialized()
        
        // Get user data - these can exist even without SDK initialization
        // because they're stored in keychain and accessed directly
        let currentEmail = IterableAPI.email
        let currentUserId = IterableAPI.userId
        
        // SDK Initialization status
        initializationStatusView.setValue(isInitialized ? "✓" : "✗", 
                                        color: isInitialized ? .systemGreen : .systemRed)
        
        // Email status - can exist independently of SDK initialization
        emailStatusView.setValue(currentEmail ?? "Not set", 
                               color: currentEmail != nil ? .systemGreen : .systemOrange)
        
        // UserId status - can exist independently of SDK initialization  
        userIdStatusView.setValue(currentUserId ?? "Not set", 
                                color: currentUserId != nil ? .systemGreen : .systemOrange)
    }
    
    private func isSDKInitialized() -> Bool {
        return IterableSDKStatusView.isSDKInitialized()
    }
    
    static func isSDKInitialized() -> Bool {
        // The correct check: SDK is initialized if the implementation property is not nil
        // This is the actual indicator that IterableAPI.initialize() was called
        
        // Method: Test if attributionInfo can store and retrieve values
        // Before initialization: setting becomes no-op (implementation is nil)  
        // After initialization: values get stored in the implementation
        
        let originalAttribution = IterableAPI.attributionInfo
        
        // Create a test attribution info
        let testAttribution = IterableAttributionInfo(campaignId: 999999, templateId: 999999, messageId: "init_test")
        
        // Try to set it
        IterableAPI.attributionInfo = testAttribution
        
        // Check if it was actually stored
        let storedAttribution = IterableAPI.attributionInfo
        let wasStored = storedAttribution?.campaignId == 999999 && storedAttribution?.messageId == "init_test"
        
        // Restore original value
        IterableAPI.attributionInfo = originalAttribution
        
        return wasStored
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
}