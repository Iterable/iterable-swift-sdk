import UIKit
import IterableSDK

final class HomeViewController: UIViewController, UITextFieldDelegate {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Initialize Test SDK"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "SDK Not Initialized"
        label.textColor = .systemRed
        label.textAlignment = .center
        label.accessibilityIdentifier = "sdk-status-label"
        return label
    }()

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

    private var isSDKInitialized = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Integration Test App"

        initializeButton.addTarget(self, action: #selector(initializeSDK), for: .touchUpInside)
        userIdField.delegate = self
        emailField.delegate = self

        let stack = UIStackView(arrangedSubviews: [titleLabel, initializeButton, statusLabel, userIdField, emailField])
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
    }

    @objc private func initializeSDK() {
        AppDelegate.initializeIterableSDK()
        isSDKInitialized = true
        statusLabel.text = "SDK Initialized"
        statusLabel.textColor = .systemGreen
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        applyUserFields()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        applyUserFields()
    }

    private func applyUserFields() {
        let trimmedUserId = userIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let userId = trimmedUserId, !userId.isEmpty {
            IterableAPI.userId = userId
        }
        if let email = trimmedEmail, !email.isEmpty {
            IterableAPI.email = email
        }
    }
}


