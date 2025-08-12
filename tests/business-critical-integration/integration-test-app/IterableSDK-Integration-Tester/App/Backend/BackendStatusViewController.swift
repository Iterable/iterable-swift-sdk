import UIKit

final class BackendStatusViewController: UIViewController {
    
    // MARK: - Properties
    
    private var apiClient: IterableAPIClient?
    private var pushSender: PushNotificationSender?
    private var testUserData: [String: Any]?
    
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
    
    private let testUserHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Test User Details"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let testUserStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Status: Not Loaded"
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
    
    private let userDetailsTableView: UITableView = {
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
        contentView.addSubview(testUserHeaderLabel)
        contentView.addSubview(testUserStatusLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(userDetailsTableView)
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
            
            // Test user header
            testUserHeaderLabel.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 30),
            testUserHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Test user status
            testUserStatusLabel.centerYAnchor.constraint(equalTo: testUserHeaderLabel.centerYAnchor),
            testUserStatusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Error label
            errorLabel.topAnchor.constraint(equalTo: testUserHeaderLabel.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // User details table view
            userDetailsTableView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            userDetailsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            userDetailsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            userDetailsTableView.heightAnchor.constraint(equalToConstant: 300),
            
            // Send push button
            sendPushButton.topAnchor.constraint(equalTo: userDetailsTableView.bottomAnchor, constant: 20),
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
        userDetailsTableView.delegate = self
        userDetailsTableView.dataSource = self
        userDetailsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserDetailCell")
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
        
        apiClient.getTestUserDetails { [weak self] success, userData in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.refreshButton.isEnabled = true
                
                if success, let userData = userData {
                    self?.testUserData = userData
                    self?.testUserStatusLabel.text = "Status: Loaded"
                    self?.testUserStatusLabel.textColor = .systemGreen
                    self?.userDetailsTableView.reloadData()
                    self?.updateSendPushButtonState()
                    self?.hideError()
                    
                    if let email = userData["email"] as? String {
                        print("✅ Successfully loaded test user details for: \(email)")
                    } else {
                        print("✅ Successfully loaded test user details")
                    }
                } else {
                    print("❌ Failed to load test user details from Iterable API")
                    self?.testUserData = nil
                    self?.testUserStatusLabel.text = "Status: Failed to Load"
                    self?.testUserStatusLabel.textColor = .systemRed
                    self?.userDetailsTableView.reloadData()
                    self?.updateSendPushButtonState()
                    self?.showError("Failed to load test user details from Iterable API. Check that the test user exists and your API keys are correct.")
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
        let hasUserData = testUserData != nil
        sendPushButton.isEnabled = hasUserData
        sendPushButton.alpha = hasUserData ? 1.0 : 0.5
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
        userDetailsTableView.isHidden = true
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        userDetailsTableView.isHidden = false
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
        guard let userData = testUserData else { return 0 }
        
        // Show user details and devices as separate rows
        var count = 0
        
        // Basic user info rows
        if userData["email"] != nil { count += 1 }
        if userData["userId"] != nil { count += 1 }
        if userData["signupDate"] != nil { count += 1 }
        
        // Device rows
        if let devices = userData["devices"] as? [[String: Any]] {
            count += devices.count > 0 ? devices.count + 1 : 1 // +1 for "Devices" header
        } else {
            count += 1 // "No devices" row
        }
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailCell", for: indexPath)
        
        guard let userData = testUserData else {
            cell.textLabel?.text = "No data"
            cell.detailTextLabel?.text = ""
            return cell
        }
        
        var currentRow = 0
        
        // Basic user info
        if let email = userData["email"] as? String {
            if indexPath.row == currentRow {
                cell.textLabel?.text = "Email"
                cell.detailTextLabel?.text = email
                return cell
            }
            currentRow += 1
        }
        
        if let userId = userData["userId"] as? String {
            if indexPath.row == currentRow {
                cell.textLabel?.text = "User ID"
                cell.detailTextLabel?.text = userId
                return cell
            }
            currentRow += 1
        }
        
        if let signupDate = userData["signupDate"] as? String {
            if indexPath.row == currentRow {
                cell.textLabel?.text = "Signup Date"
                cell.detailTextLabel?.text = signupDate
                return cell
            }
            currentRow += 1
        }
        
        // Devices section
        if let devices = userData["devices"] as? [[String: Any]] {
            if indexPath.row == currentRow {
                // Devices header
                cell.textLabel?.text = "Devices"
                cell.detailTextLabel?.text = "\(devices.count) registered"
                cell.textLabel?.font = .boldSystemFont(ofSize: 16)
                return cell
            }
            currentRow += 1
            
            // Individual devices
            let deviceIndex = indexPath.row - currentRow
            if deviceIndex < devices.count {
                let device = devices[deviceIndex]
                let platform = device["platform"] as? String ?? "Unknown"
                let token = device["token"] as? String ?? "No token"
                let truncatedToken = token.count > 20 ? String(token.prefix(10)) + "..." + String(token.suffix(10)) : token
                
                cell.textLabel?.text = "\(platform) Device"
                cell.detailTextLabel?.text = truncatedToken
                cell.textLabel?.font = .systemFont(ofSize: 14)
                return cell
            }
        } else {
            if indexPath.row == currentRow {
                cell.textLabel?.text = "Devices"
                cell.detailTextLabel?.text = "No devices registered"
                return cell
            }
        }
        
        cell.textLabel?.text = "Unknown"
        cell.detailTextLabel?.text = ""
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
