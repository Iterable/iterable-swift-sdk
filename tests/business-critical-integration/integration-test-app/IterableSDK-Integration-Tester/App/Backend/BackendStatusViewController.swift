import UIKit

final class BackendStatusViewController: UIViewController {
    
    // MARK: - Properties
    
    private var apiClient: IterableAPIClient?
    private var pushSender: PushNotificationSender?
    private var registeredUsers: [[String: Any]] = []
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Backend Status"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let connectionStatusView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray4.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let connectionStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Connection Status: Not Connected"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Refresh Backend Status", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let usersHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Registered Users"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usersCountLabel: UILabel = {
        let label = UILabel()
        label.text = "Count: 0"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usersTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.layer.cornerRadius = 8
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray4.cgColor
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let sendPushButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Push Notification", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupActions()
        setupBackendClient()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshBackendStatus()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Backend Status"
        
        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        connectionStatusView.addSubview(connectionStatusLabel)
        
        contentView.addSubview(statusLabel)
        contentView.addSubview(connectionStatusView)
        contentView.addSubview(refreshButton)
        contentView.addSubview(usersHeaderLabel)
        contentView.addSubview(usersCountLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(usersTableView)
        contentView.addSubview(sendPushButton)
        contentView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Connection status view
            connectionStatusView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            connectionStatusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            connectionStatusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            connectionStatusView.heightAnchor.constraint(equalToConstant: 50),
            
            // Connection status label
            connectionStatusLabel.centerYAnchor.constraint(equalTo: connectionStatusView.centerYAnchor),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: connectionStatusView.leadingAnchor, constant: 16),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: connectionStatusView.trailingAnchor, constant: -16),
            
            // Refresh button
            refreshButton.topAnchor.constraint(equalTo: connectionStatusView.bottomAnchor, constant: 16),
            refreshButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            refreshButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            refreshButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Users header
            usersHeaderLabel.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 30),
            usersHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Users count
            usersCountLabel.centerYAnchor.constraint(equalTo: usersHeaderLabel.centerYAnchor),
            usersCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Error label
            errorLabel.topAnchor.constraint(equalTo: usersHeaderLabel.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Users table view
            usersTableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            usersTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            usersTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            usersTableView.heightAnchor.constraint(equalToConstant: 300),
            
            // Send push button
            sendPushButton.topAnchor.constraint(equalTo: usersTableView.bottomAnchor, constant: 20),
            sendPushButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sendPushButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sendPushButton.heightAnchor.constraint(equalToConstant: 44),
            sendPushButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: refreshButton.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        usersTableView.delegate = self
        usersTableView.dataSource = self
        usersTableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
    }
    
    private func setupActions() {
        refreshButton.addTarget(self, action: #selector(refreshBackendStatus), for: .touchUpInside)
        sendPushButton.addTarget(self, action: #selector(sendPushNotification), for: .touchUpInside)
    }
    
    private func setupBackendClient() {
        // Load API keys from config
        guard let apiKey = loadAPIKey(),
              let serverKey = loadServerKey() else {
            updateConnectionStatus(false, message: "Missing API keys in config")
            return
        }
        
        let projectId = "integration-test"
        apiClient = IterableAPIClient(apiKey: apiKey, serverKey: serverKey, projectId: projectId)
        pushSender = PushNotificationSender(apiClient: apiClient!, serverKey: serverKey, projectId: projectId)
        
        updateConnectionStatus(true, message: "Backend client initialized")
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func refreshBackendStatus() {
        guard let apiClient = apiClient else {
            showAlert(title: "Error", message: "Backend client not initialized")
            return
        }
        
        activityIndicator.startAnimating()
        refreshButton.isEnabled = false
        
        apiClient.getRegisteredUsers { [weak self] success, users in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.refreshButton.isEnabled = true
                
                if success {
                    self?.registeredUsers = users
                    self?.usersCountLabel.text = "Count: \(users.count)"
                    self?.usersTableView.reloadData()
                    self?.updateSendPushButtonState()
                    self?.hideError()
                    
                    if users.isEmpty {
                        print("⚠️ Successfully connected but no users found in project")
                        self?.showError("Successfully connected to Iterable API but no users found in your project.")
                    } else {
                        print("✅ Successfully loaded \(users.count) registered users")
                    }
                } else {
                    print("❌ Failed to load registered users from Iterable API")
                    self?.registeredUsers = []
                    self?.usersCountLabel.text = "Count: 0"
                    self?.usersTableView.reloadData()
                    self?.updateSendPushButtonState()
                    self?.showError("Failed to load users from Iterable API. The endpoints /api/users/search and /api/export/userEvents returned 404 errors. Check your API keys and project configuration.")
                }
            }
        }
    }
    
    @objc private func sendPushNotification() {
        guard let pushSender = pushSender,
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Push sender not initialized or test user email not found")
            return
        }
        
        sendPushButton.isEnabled = false
        
        pushSender.sendIntegrationTestPush(to: testUserEmail) { [weak self] success, messageId, error in
            DispatchQueue.main.async {
                self?.sendPushButton.isEnabled = true
                
                if success {
                    let message = "Push notification sent successfully!"
                    if let messageId = messageId {
                        print("✅ Push sent with message ID: \(messageId)")
                    }
                    self?.showAlert(title: "Success", message: message)
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self?.showAlert(title: "Error", message: "Failed to send push notification: \(errorMessage)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateConnectionStatus(_ connected: Bool, message: String) {
        connectionStatusLabel.text = "Connection Status: \(message)"
        connectionStatusLabel.textColor = connected ? .systemGreen : .systemRed
    }
    
    private func updateSendPushButtonState() {
        let hasUsers = !registeredUsers.isEmpty
        sendPushButton.isEnabled = hasUsers
        sendPushButton.alpha = hasUsers ? 1.0 : 0.5
    }
    
    private func loadAPIKey() -> String? {
        return AppDelegate.loadApiKeyFromConfig()
    }
    
    private func loadServerKey() -> String? {
        return AppDelegate.loadServerKeyFromConfig()
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        usersTableView.isHidden = true
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        usersTableView.isHidden = false
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BackendStatusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registeredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        let user = registeredUsers[indexPath.row]
        cell.configure(with: user)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BackendStatusViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UserTableViewCell

class UserTableViewCell: UITableViewCell {
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userIdLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(emailLabel)
        contentView.addSubview(userIdLabel)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            emailLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            
            userIdLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            userIdLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userIdLabel.trailingAnchor.constraint(equalTo: statusLabel.leadingAnchor, constant: -8),
            userIdLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configure(with user: [String: Any]) {
        emailLabel.text = user["email"] as? String ?? "Unknown"
        userIdLabel.text = "ID: \(user["userId"] as? String ?? "N/A")"
        
        // Set status based on device registration
        if let devices = user["devices"] as? [[String: Any]], !devices.isEmpty {
            statusLabel.text = "✓ Active"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "○ No Device"
            statusLabel.textColor = .systemOrange
        }
    }
}
