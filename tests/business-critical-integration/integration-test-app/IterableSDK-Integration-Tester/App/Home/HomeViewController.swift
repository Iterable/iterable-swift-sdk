import UIKit

final class HomeViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI Components
    
    private let statusView = IterableSDKStatusView()

    private let initializeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Initialize SDK", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.accessibilityIdentifier = "initialize-sdk-button"
        return button
    }()

    private let userIdField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "User ID"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.accessibilityIdentifier = "user-id-textfield"
        return tf
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "User Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.accessibilityIdentifier = "user-email-textfield"
        return tf
    }()

    private let registerEmailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register Email", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.accessibilityIdentifier = "register-email-button"
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private let registerUserIdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register User ID", for: .normal)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.accessibilityIdentifier = "register-userid-button"
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout (Clear Keychain)", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.accessibilityIdentifier = "logout-button"
        return button
    }()

    private let clearLocalDataButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear Local Data", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.accessibilityIdentifier = "clear-local-data-button"
        return button
    }()

    private let pushNotificationTestRow: UIView = {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.isUserInteractionEnabled = true
        container.accessibilityIdentifier = "push-notification-test-row"
        
        let titleLabel = UILabel()
        titleLabel.text = "Push Notification Integration Testing"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }()

    private let inAppMessageTestRow: UIView = {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.isUserInteractionEnabled = true
        container.accessibilityIdentifier = "in-app-message-test-row"
        
        let titleLabel = UILabel()
        titleLabel.text = "In-App Message Integration Testing"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }()

    private let embeddedMessageTestRow: UIView = {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.isUserInteractionEnabled = true
        container.accessibilityIdentifier = "embedded-message-test-row"

        let titleLabel = UILabel()
        titleLabel.text = "Embedded Message Integration Testing"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }()

    private let remoteConfigOverrideRow: UIView = {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.isUserInteractionEnabled = true
        container.accessibilityIdentifier = "remote-config-override-row"

        let titleLabel = UILabel()
        titleLabel.text = "Remote Config Override"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }()

    private let offlineRetryTestRow: UIView = {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        container.isUserInteractionEnabled = true
        container.accessibilityIdentifier = "offline-retry-test-row"

        let titleLabel = UILabel()
        titleLabel.text = "Offline Retry Testing"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .systemGray3
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Integration Test App"
        
        // Setup network monitoring
        NetworkMonitor.shared.startMonitoring()

        initializeButton.addTarget(self, action: #selector(initializeSDK), for: .touchUpInside)
        userIdField.delegate = self
        emailField.delegate = self
        userIdField.addTarget(self, action: #selector(onTextChanged), for: .editingChanged)
        emailField.addTarget(self, action: #selector(onTextChanged), for: .editingChanged)

        if let configEmail = AppDelegate.loadTestUserEmailFromConfig() {
            emailField.text = configEmail
        }
        userIdField.text = HomeViewController.generateRandomUserId(length: 6)

        let stack = UIStackView(arrangedSubviews: [initializeButton,
                                                   userIdField,
                                                   registerUserIdButton,
                                                   emailField,
                                                   registerEmailButton,
                                                   logoutButton,
                                                   clearLocalDataButton,
                                                   statusView,
                                                   remoteConfigOverrideRow,
                                                   pushNotificationTestRow,
                                                   inAppMessageTestRow,
                                                   embeddedMessageTestRow,
                                                   offlineRetryTestRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        updateButtonStates()
    }

    @objc private func initializeSDK() {
        AppDelegate.initializeIterableSDK()
        updateButtonStates()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        updateButtonStates()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateButtonStates()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerEmailButton.addTarget(self, action: #selector(registerEmail), for: .touchUpInside)
        registerUserIdButton.addTarget(self, action: #selector(registerUserId), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        clearLocalDataButton.addTarget(self, action: #selector(clearLocalData), for: .touchUpInside)
        let pushTapGesture = UITapGestureRecognizer(target: self, action: #selector(showPushNotificationTest))
        pushNotificationTestRow.addGestureRecognizer(pushTapGesture)
        
        let inAppTapGesture = UITapGestureRecognizer(target: self, action: #selector(showInAppMessageTest))
        inAppMessageTestRow.addGestureRecognizer(inAppTapGesture)
        
        let embeddedTapGesture = UITapGestureRecognizer(target: self, action: #selector(showEmbeddedMessageTest))
        embeddedMessageTestRow.addGestureRecognizer(embeddedTapGesture)

        let offlineRetryTapGesture = UITapGestureRecognizer(target: self, action: #selector(showOfflineRetryTest))
        offlineRetryTestRow.addGestureRecognizer(offlineRetryTapGesture)

        let remoteConfigTapGesture = UITapGestureRecognizer(target: self, action: #selector(showRemoteConfigOverride))
        remoteConfigOverrideRow.addGestureRecognizer(remoteConfigTapGesture)
    }

    @objc private func registerEmail() {
        let trimmedEmail = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let email = trimmedEmail, !email.isEmpty {
            AppDelegate.registerEmailToIterableSDK(email: email)
        }
    }

    @objc private func registerUserId() {
        let trimmedUserId = userIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let userId = trimmedUserId, !userId.isEmpty {
            AppDelegate.registerUserIDToIterableSDK(userId: userId)
        }
    }

    @objc private func logout() {
        AppDelegate.logoutFromIterableSDK()
    }
    
    @objc private func clearLocalData() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        // Clear all keys
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        
        // Synchronize to ensure changes are written immediately
        defaults.synchronize()
        
        print("✅ All NSUserDefaults data cleared")
    }
    
    // MARK: - Navigation Setup
    
    @objc private func showNetworkMonitor() {
        let networkMonitorVC = NetworkMonitorViewController()
        let navController = UINavigationController(rootViewController: networkMonitorVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func showBackendStatus() {
        let backendStatusVC = BackendStatusViewController()
        let navController = UINavigationController(rootViewController: backendStatusVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func onTextChanged() {
        updateButtonStates()
    }
    
    // MARK: - Private Methods
    
    private func updateButtonStates() {
        updateRegisterButtonStates()
        updatePushNotificationButtonState()
        updateInAppMessageButtonState()
        updateEmbeddedMessageButtonState()
        updateOfflineRetryButtonState()
    }
    
    private func updateRegisterButtonStates() {
        let hasUserId = !userIdField.text.isEmptyOrWhitespace
        let hasEmail = !emailField.text.isEmptyOrWhitespace
        
        configureButton(registerUserIdButton, enabled: hasUserId)
        configureButton(registerEmailButton, enabled: hasEmail)
    }
    
    private func configureButton(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = enabled ? 1.0 : 0.5
    }
    
    private func updatePushNotificationButtonState() {
        let isSDKInitialized = IterableSDKStatusView.isSDKInitialized()
        pushNotificationTestRow.isUserInteractionEnabled = isSDKInitialized
        pushNotificationTestRow.alpha = isSDKInitialized ? 1.0 : 0.5
    }
    
    private func updateInAppMessageButtonState() {
        let isSDKInitialized = IterableSDKStatusView.isSDKInitialized()
        inAppMessageTestRow.isUserInteractionEnabled = isSDKInitialized
        inAppMessageTestRow.alpha = isSDKInitialized ? 1.0 : 0.5
    }
    
    @objc private func showPushNotificationTest() {
        let pushTestVC = PushNotificationTestViewController()
        navigationController?.pushViewController(pushTestVC, animated: true)
    }
    
    @objc private func showInAppMessageTest() {        
        let inAppVC = InAppMessageTestHostingController()
        navigationController?.pushViewController(inAppVC, animated: true)
    }
    
    private func updateEmbeddedMessageButtonState() {
        let isSDKInitialized = IterableSDKStatusView.isSDKInitialized()
        embeddedMessageTestRow.isUserInteractionEnabled = isSDKInitialized
        embeddedMessageTestRow.alpha = isSDKInitialized ? 1.0 : 0.5
    }
    
    @objc private func showEmbeddedMessageTest() {
        let embeddedVC = EmbeddedMessageTestHostingController()
        navigationController?.pushViewController(embeddedVC, animated: true)
    }

    private func updateOfflineRetryButtonState() {
        let isSDKInitialized = IterableSDKStatusView.isSDKInitialized()
        offlineRetryTestRow.isUserInteractionEnabled = isSDKInitialized
        offlineRetryTestRow.alpha = isSDKInitialized ? 1.0 : 0.5
    }

    @objc private func showOfflineRetryTest() {
        let offlineRetryVC = OfflineRetryTestViewController()
        navigationController?.pushViewController(offlineRetryVC, animated: true)
    }

    @objc private func showRemoteConfigOverride() {
        let remoteConfigVC = RemoteConfigOverrideViewController()
        navigationController?.pushViewController(remoteConfigVC, animated: true)
    }
}

// MARK: - Extensions

private extension HomeViewController {
    static func generateRandomUserId(length: Int) -> String {
        let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        var result = String()
        result.reserveCapacity(length)
        for _ in 0..<length {
            if let random = characters.randomElement() {
                result.append(random)
            }
        }
        return result
    }
}

private extension Optional where Wrapped == String {
    var isEmptyOrWhitespace: Bool {
        return self?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }
}
