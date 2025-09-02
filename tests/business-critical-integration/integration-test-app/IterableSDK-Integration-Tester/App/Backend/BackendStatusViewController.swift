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
        button.accessibilityIdentifier = "refresh-backend-status-button"
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
        button.accessibilityIdentifier = "test-push-notification-button"
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private let sendDeepLinkPushButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Deep Link Push (Campaign 14695444)", for: .normal)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "test-deep-link-push-button"
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private let resetDevicesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Disable User Devices", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let reenableDevicesButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Re-enable User Devices", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let showDisabledDevicesSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let showDisabledLabel: UILabel = {
        let label = UILabel()
        label.text = "Show Disabled Devices"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        let closeBarButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        closeBarButton.accessibilityIdentifier = "backend-close-button"
        navigationItem.leftBarButtonItem = closeBarButton
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        connectionStatusView.addSubview(connectionStatusLabel)
        
        contentView.addSubview(statusLabel)
        contentView.addSubview(connectionStatusView)
        contentView.addSubview(refreshButton)
        contentView.addSubview(testUserHeaderLabel)
        contentView.addSubview(testUserStatusLabel)
        contentView.addSubview(errorLabel)
        contentView.addSubview(showDisabledLabel)
        contentView.addSubview(showDisabledDevicesSwitch)
        contentView.addSubview(userDetailsTableView)
        contentView.addSubview(sendPushButton)
        contentView.addSubview(sendDeepLinkPushButton)
        contentView.addSubview(resetDevicesButton)
        contentView.addSubview(reenableDevicesButton)
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
            
            // Show disabled devices toggle
            showDisabledLabel.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            showDisabledLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            showDisabledDevicesSwitch.centerYAnchor.constraint(equalTo: showDisabledLabel.centerYAnchor),
            showDisabledDevicesSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // User details table view
            userDetailsTableView.topAnchor.constraint(equalTo: showDisabledLabel.bottomAnchor, constant: 12),
            userDetailsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            userDetailsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            userDetailsTableView.heightAnchor.constraint(equalToConstant: 300),
            
            // Send push button
            sendPushButton.topAnchor.constraint(equalTo: userDetailsTableView.bottomAnchor, constant: 20),
            sendPushButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sendPushButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sendPushButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Send deep link push button
            sendDeepLinkPushButton.topAnchor.constraint(equalTo: sendPushButton.bottomAnchor, constant: 12),
            sendDeepLinkPushButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sendDeepLinkPushButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sendDeepLinkPushButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Reset devices button
            resetDevicesButton.topAnchor.constraint(equalTo: sendDeepLinkPushButton.bottomAnchor, constant: 12),
            resetDevicesButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resetDevicesButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resetDevicesButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Re-enable devices button
            reenableDevicesButton.topAnchor.constraint(equalTo: resetDevicesButton.bottomAnchor, constant: 12),
            reenableDevicesButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            reenableDevicesButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            reenableDevicesButton.heightAnchor.constraint(equalToConstant: 44),
            reenableDevicesButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
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
        sendDeepLinkPushButton.addTarget(self, action: #selector(sendDeepLinkPushNotification), for: .touchUpInside)
        resetDevicesButton.addTarget(self, action: #selector(resetUserDevices), for: .touchUpInside)
        reenableDevicesButton.addTarget(self, action: #selector(reenableUserDevices), for: .touchUpInside)
        showDisabledDevicesSwitch.addTarget(self, action: #selector(toggleShowDisabledDevices), for: .valueChanged)
    }
    
    @objc private func toggleShowDisabledDevices() {
        // Reload the table view to apply the filter
        userDetailsTableView.reloadData()
    }
    
    // MARK: - Device Filtering Helper
    
    private func getFilteredDevices() -> [[String: Any]] {
        guard let userData = testUserData,
              let allDevices = userData["devices"] as? [[String: Any]] else {
            return []
        }
        
        var filteredDevices: [[String: Any]]
        
        if showDisabledDevicesSwitch.isOn {
            // Show all devices
            filteredDevices = allDevices
        } else {
            // Show only enabled devices
            filteredDevices = allDevices.filter { device in
                let endpointEnabled = device["endpointEnabled"] as? Bool ?? false
                let notificationsEnabled = device["notificationsEnabled"] as? Bool ?? false
                return endpointEnabled && notificationsEnabled
            }
        }
        
        // Sort devices to put current device first
        return sortDevicesWithCurrentFirst(filteredDevices)
    }
    
    private func sortDevicesWithCurrentFirst(_ devices: [[String: Any]]) -> [[String: Any]] {
        guard let currentDeviceToken = AppDelegate.getRegisteredDeviceToken() else {
            return devices
        }
        
        var currentDevice: [String: Any]?
        var otherDevices: [[String: Any]] = []
        
        for device in devices {
            if let deviceToken = device["token"] as? String, deviceToken == currentDeviceToken {
                currentDevice = device
            } else {
                otherDevices.append(device)
            }
        }
        
        // Return current device first, then others
        if let current = currentDevice {
            return [current] + otherDevices
        } else {
            return otherDevices
        }
    }
    
    private func isCurrentDevice(_ device: [String: Any]) -> Bool {
        guard let currentDeviceToken = AppDelegate.getRegisteredDeviceToken(),
              let deviceToken = device["token"] as? String else {
            return false
        }
        return deviceToken == currentDeviceToken
    }
    
    private func setupBackendClient() {
        // Load API keys from config
        guard let apiKey = loadAPIKey(),
              let serverKey = loadServerKey() else {
            updateConnectionStatus(false, message: "Missing API keys in config")
            return
        }
        
        let projectId = AppDelegate.loadProjectIdFromConfig()
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
    
    @objc private func sendDeepLinkPushNotification() {
        guard let pushSender = pushSender,
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Push sender not initialized or test user email not found")
            return
        }
        
        sendDeepLinkPushButton.isEnabled = false
        
        pushSender.sendDeepLinkPush(to: testUserEmail, campaignId: 14695444) { [weak self] success, messageId, error in
            DispatchQueue.main.async {
                self?.sendDeepLinkPushButton.isEnabled = true
                
                if success {
                    let message = "Deep link push notification sent successfully!\nCampaign ID: 14695444"
                    if let messageId = messageId {
                        print("✅ Deep link push sent with message ID: \(messageId)")
                    }
                    self?.showAlert(title: "Success", message: message)
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self?.showAlert(title: "Error", message: "Failed to send deep link push notification: \(errorMessage)")
                }
            }
        }
    }
    
    @objc private func resetUserDevices() {
        guard let apiClient = apiClient,
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Backend client not initialized or test user email not found")
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Reset User Devices", 
            message: "This will disable ALL registered devices for the test user:\n\(testUserEmail)\n\nAre you sure?", 
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset Devices", style: .destructive) { [weak self] _ in
            self?.performDeviceReset(apiClient: apiClient, email: testUserEmail)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func reenableUserDevices() {
        guard let apiClient = apiClient,
              let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            showAlert(title: "Error", message: "Backend client not initialized or test user email not found")
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Re-enable User Devices", 
            message: "This will re-enable ALL disabled devices for the test user:\n\(testUserEmail)\n\nAre you sure?", 
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Re-enable Devices", style: .default) { [weak self] _ in
            self?.performDeviceReenable(apiClient: apiClient, email: testUserEmail)
        })
        
        present(alert, animated: true)
    }
    
    private func performDeviceReset(apiClient: IterableAPIClient, email: String) {
        resetDevicesButton.isEnabled = false
        resetDevicesButton.setTitle("Resetting...", for: .normal)
        
        print("🔄 Starting device reset for user: \(email)")
        
        apiClient.disableAllUserDevices(email: email) { [weak self] success, deviceCount in
            DispatchQueue.main.async {
                self?.resetDevicesButton.isEnabled = true
                self?.resetDevicesButton.setTitle("Reset User Devices", for: .normal)
                
                if success {
                    let message = "Successfully disabled \(deviceCount) device(s) for the test user."
                    print("✅ Device reset completed: \(deviceCount) devices disabled")
                    self?.showAlert(title: "Success", message: message) { [weak self] in
                        // Refresh the backend status to show updated device list
                        self?.refreshBackendStatus()
                    }
                } else {
                    let message = "Failed to reset all devices. Some devices may have been disabled. Check the console for details."
                    print("❌ Device reset partially failed")
                    self?.showAlert(title: "Partial Failure", message: message) { [weak self] in
                        // Still refresh to show current state
                        self?.refreshBackendStatus()
                    }
                }
            }
        }
    }
    
    private func performDeviceReenable(apiClient: IterableAPIClient, email: String) {
        reenableDevicesButton.isEnabled = false
        reenableDevicesButton.setTitle("Re-enabling...", for: .normal)
        
        print("🔄 Starting device re-enable for user: \(email)")
        
        apiClient.reenableAllUserDevices(email: email) { [weak self] success, deviceCount in
            DispatchQueue.main.async {
                self?.reenableDevicesButton.isEnabled = true
                self?.reenableDevicesButton.setTitle("Re-enable User Devices", for: .normal)
                
                if success {
                    let message = "Successfully re-enabled \(deviceCount) device(s) for the test user."
                    print("✅ Device re-enable completed: \(deviceCount) devices re-enabled")
                    self?.showAlert(title: "Success", message: message) { [weak self] in
                        // Refresh the backend status to show updated device list
                        self?.refreshBackendStatus()
                    }
                } else {
                    let message = "Failed to re-enable all devices. Some devices may have been re-enabled. Check the console for details."
                    print("❌ Device re-enable partially failed")
                    self?.showAlert(title: "Partial Failure", message: message) { [weak self] in
                        // Still refresh to show current state
                        self?.refreshBackendStatus()
                    }
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
        sendDeepLinkPushButton.isEnabled = hasUserData
        sendDeepLinkPushButton.alpha = hasUserData ? 1.0 : 0.5
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
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BackendStatusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let userData = testUserData else { return 0 }
        
        // Only show device rows
        let filteredDevices = getFilteredDevices()
        if !filteredDevices.isEmpty {
            return filteredDevices.count + 1 // +1 for "Devices" header
        } else {
            return 1 // "No devices" row
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailCell", for: indexPath)
        
        guard let userData = testUserData else {
            cell.textLabel?.text = "No data"
            cell.detailTextLabel?.text = ""
            return cell
        }
        
        // Devices section (using filtered devices)
        let filteredDevices = getFilteredDevices()
        let allDevices = userData["devices"] as? [[String: Any]] ?? []
        
        if !filteredDevices.isEmpty {
            if indexPath.row == 0 {
                // Devices header with count info
                let headerText = showDisabledDevicesSwitch.isOn ? 
                    "Devices (\(filteredDevices.count) total)" : 
                    "Enabled Devices (\(filteredDevices.count) of \(allDevices.count))"
                
                cell.textLabel?.text = headerText
                cell.detailTextLabel?.text = ""
                cell.textLabel?.font = .boldSystemFont(ofSize: 16)
                cell.backgroundColor = .systemBackground
                return cell
            }
            
            // Individual devices
            let deviceIndex = indexPath.row - 1
            if deviceIndex < filteredDevices.count {
                let device = filteredDevices[deviceIndex]
                let platform = device["platform"] as? String ?? "Unknown"
                let systemName = device["systemName"] as? String ?? ""
                let systemVersion = device["systemVersion"] as? String ?? ""
                let token = device["token"] as? String ?? "No token"
                let enabled = device["endpointEnabled"] as? Bool ?? false
                let notificationsEnabled = device["notificationsEnabled"] as? Bool ?? false
                
                // Create a more descriptive device label
                var deviceLabel = platform
                if !systemName.isEmpty && !systemVersion.isEmpty {
                    deviceLabel += " (\(systemName) \(systemVersion))"
                }
                
                // Show token with status indicators and current device indicator
                let statusIndicator = (enabled && notificationsEnabled) ? "✅" : "❌"
                let currentDeviceIndicator = isCurrentDevice(device) ? " 📱 This Device" : ""
                let truncatedToken = token.count > 20 ? String(token.prefix(8)) + "..." + String(token.suffix(8)) : token
                
                cell.textLabel?.text = "\(statusIndicator) \(deviceLabel)\(currentDeviceIndicator)"
                cell.detailTextLabel?.text = truncatedToken
                
                // Style current device differently
                if isCurrentDevice(device) {
                    cell.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
                    cell.textLabel?.textColor = .systemBlue
                    cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
                } else {
                    cell.textLabel?.font = .systemFont(ofSize: 14)
                    cell.textLabel?.textColor = .label
                    cell.backgroundColor = .systemBackground
                }
                
                cell.detailTextLabel?.font = .systemFont(ofSize: 12)
                cell.detailTextLabel?.textColor = .systemGray
                return cell
            }
        } else {
            if indexPath.row == 0 {
                let noDevicesText = showDisabledDevicesSwitch.isOn ? 
                    "No devices registered" : 
                    "No enabled devices (\(allDevices.count) disabled)"
                
                cell.textLabel?.text = "Devices"
                cell.detailTextLabel?.text = noDevicesText
                cell.textLabel?.font = .boldSystemFont(ofSize: 16)
                cell.detailTextLabel?.textColor = .systemOrange
                cell.backgroundColor = .systemBackground
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let userData = testUserData else { return }
        
        // Check if it's a device row (using filtered devices)
        let filteredDevices = getFilteredDevices()
        if !filteredDevices.isEmpty && indexPath.row > 0 {
            // Skip header row (row 0)
            let deviceIndex = indexPath.row - 1
            if deviceIndex >= 0 && deviceIndex < filteredDevices.count {
                let device = filteredDevices[deviceIndex]
                if let token = device["token"] as? String {
                    showDeviceTokenDetails(device: device, token: token)
                }
            }
        }
    }
    
    private func showDeviceTokenDetails(device: [String: Any], token: String) {
        let platform = device["platform"] as? String ?? "Unknown"
        let systemName = device["systemName"] as? String ?? ""
        let systemVersion = device["systemVersion"] as? String ?? ""
        let enabled = device["endpointEnabled"] as? Bool ?? false
        let notificationsEnabled = device["notificationsEnabled"] as? Bool ?? false
        let deviceId = device["deviceId"] as? String ?? "N/A"
        
        var deviceInfo = "\(platform)"
        if !systemName.isEmpty && !systemVersion.isEmpty {
            deviceInfo += " (\(systemName) \(systemVersion))"
        }
        deviceInfo += "\n\nDevice ID: \(deviceId)"
        deviceInfo += "\nEndpoint Enabled: \(enabled ? "Yes" : "No")"
        deviceInfo += "\nNotifications Enabled: \(notificationsEnabled ? "Yes" : "No")"
        deviceInfo += "\n\nDevice Token:\n\(token)"
        
        let alert = UIAlertController(title: "Device Details", message: deviceInfo, preferredStyle: .alert)
        
        // Add copy token action
        alert.addAction(UIAlertAction(title: "Copy Token", style: .default) { _ in
            UIPasteboard.general.string = token
            print("📋 Device token copied to clipboard")
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
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
        userIdLabel.text = "ID: \(user["itblUserId"] as? String ?? "N/A")"
        
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
