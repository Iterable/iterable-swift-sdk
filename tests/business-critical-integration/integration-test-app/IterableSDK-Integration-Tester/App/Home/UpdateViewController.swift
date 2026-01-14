import UIKit

/// UpdateViewController - Displayed when deep link navigates to tsetester.com/update/*
class UpdateViewController: UIViewController {
    
    // MARK: - Properties
    
    private let updatePath: String
    
    // MARK: - UI Components
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "👋 Hi!"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "update-view-header"
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Successfully navigated from deep link!"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "update-view-message"
        return label
    }()
    
    private let pathLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .tertiaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "update-view-path"
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "update-view-timestamp"
        return label
    }()
    
    private let infoBox: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = """
        ✅ Deep Link Flow Complete
        
        1. Wrapped link: links.tsetester.com/a/click
        2. SDK unwrapped to: tsetester.com/update/hi
        3. SDK followed exactly ONE redirect
        4. App received unwrapped URL
        5. App navigated to this Update screen
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
        button.accessibilityIdentifier = "update-view-close-button"
        return button
    }()
    
    // MARK: - Initialization
    
    init(path: String) {
        self.updatePath = path
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Set path and timestamp
        pathLabel.text = "Path: \(updatePath)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        timestampLabel.text = "Opened at: \(formatter.string(from: Date()))"
        
        setupUI()
        setupActions()
        
        print("✅ UpdateViewController loaded successfully for path: \(updatePath)")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(headerLabel)
        view.addSubview(messageLabel)
        view.addSubview(pathLabel)
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
            
            // Path
            pathLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            pathLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pathLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Timestamp
            timestampLabel.topAnchor.constraint(equalTo: pathLabel.bottomAnchor, constant: 8),
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
            print("✅ UpdateViewController dismissed")
        }
    }
}
