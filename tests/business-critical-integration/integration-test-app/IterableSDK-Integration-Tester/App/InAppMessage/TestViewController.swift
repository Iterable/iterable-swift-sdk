import UIKit

/// TestViewController - Displayed when user taps the "Show Test View" button in the in-app message
class TestViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "🎉 Test View"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "test-view-header"
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Successfully navigated from in-app message!"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "test-view-message"
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "test-view-timestamp"
        return label
    }()
    
    private let infoBox: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemGreen.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = """
        ✅ In-App Message Flow Complete
        
        1. App received in-app message
        2. Message was displayed
        3. User tapped "Show Test View" button
        4. SDK dismissed the in-app message
        5. App navigated to this Test View
        """
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "test-view-close-button"
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Set timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        timestampLabel.text = "Opened at: \(formatter.string(from: Date()))"
        
        setupUI()
        setupActions()
        
        print("✅ TestViewController loaded successfully")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(headerLabel)
        view.addSubview(messageLabel)
        view.addSubview(timestampLabel)
        view.addSubview(infoBox)
        infoBox.addSubview(infoLabel)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Timestamp
            timestampLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timestampLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Info Box
            infoBox.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 40),
            infoBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Info Label inside box
            infoLabel.topAnchor.constraint(equalTo: infoBox.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: infoBox.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: infoBox.trailingAnchor, constant: -20),
            infoLabel.bottomAnchor.constraint(equalTo: infoBox.bottomAnchor, constant: -20),
            
            // Close Button
            closeButton.topAnchor.constraint(equalTo: infoBox.bottomAnchor, constant: 40),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true) {
            print("✅ TestViewController dismissed")
        }
    }
}

