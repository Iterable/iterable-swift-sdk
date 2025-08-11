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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Integration Test App"

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
                                                   statusView])
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

    @objc private func onTextChanged() {
        updateButtonStates()
    }
    
    // MARK: - Private Methods
    
    private func updateButtonStates() {
        updateRegisterButtonStates()
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
