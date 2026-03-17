import UIKit
import IterableSDK

final class OfflineRetryTestViewController: UIViewController {

    // MARK: - Properties

    private var statusTimer: Timer?
    private var logEntries: [LogEntry] = []
    private var notificationObservers: [NSObjectProtocol] = []
    private let mockServer = MockAPIServer.shared

    // MARK: - Models

    private struct LogEntry {
        let timestamp: Date
        let type: EntryType
        let detail: String

        enum EntryType: String {
            case success = "Success"
            case retry = "Retry"
            case noRetry = "No Retry"
            case authRefresh = "Auth Refreshed"
            case eventSent = "Event Sent"
            case setup = "Setup"
        }

        var color: UIColor {
            switch type {
            case .success: return .systemGreen
            case .retry: return .systemOrange
            case .noRetry: return .systemRed
            case .authRefresh: return .systemBlue
            case .eventSent: return .systemTeal
            case .setup: return .systemPurple
            }
        }
    }

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Setup Section
    private let setupSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "1. Setup"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let setupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Enable Mock JWT Server & Reinitialize SDK", for: .normal)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    private let teardownButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Disable Mock Server & Reset", for: .normal)
        button.backgroundColor = .systemGray3
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return button
    }()

    private let setupStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.numberOfLines = 0
        label.text = "Not configured"
        return label
    }()

    // Mock API Response Section
    private let mockAPISectionLabel: UILabel = {
        let label = UILabel()
        label.text = "2. Mock API Response Mode"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let responseModeSegment: UISegmentedControl = {
        let items = MockAPIServer.APIResponseMode.allCases.map { $0.rawValue }
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 1 // default: jwt401ThenSuccess
        return sc
    }()

    private let mockStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.numberOfLines = 0
        label.text = "Mock: inactive"
        return label
    }()

    // Test Actions Section
    private let actionsSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "3. Track Events"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let trackOneEventButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Track Test Event", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    private let trackThreeEventsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Track 3 Events", for: .normal)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    // Event Log Section
    private let logSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "4. Event Log"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let logTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "LogCell")
        return table
    }()

    private let goHomeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Go Back to Home Screen", for: .normal)
        button.backgroundColor = .systemGray3
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JWT Auth Retry Testing"
        view.backgroundColor = .systemBackground

        setupNavigation()
        setupUI()
        setupActions()
        setupNotificationObservers()
        startPolling()
        syncUIFromMockServer()
    }

    deinit {
        statusTimer?.invalidate()
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Setup

    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear Log",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(clearLog))
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        // Setup card
        let setupCard = createSectionContainer()
        let setupStack = UIStackView(arrangedSubviews: [setupButton, teardownButton, setupStatusLabel])
        setupStack.axis = .vertical
        setupStack.spacing = 8
        setupStack.translatesAutoresizingMaskIntoConstraints = false
        setupCard.addSubview(setupStack)
        NSLayoutConstraint.activate([
            setupStack.topAnchor.constraint(equalTo: setupCard.topAnchor, constant: 12),
            setupStack.leadingAnchor.constraint(equalTo: setupCard.leadingAnchor, constant: 16),
            setupStack.trailingAnchor.constraint(equalTo: setupCard.trailingAnchor, constant: -16),
            setupStack.bottomAnchor.constraint(equalTo: setupCard.bottomAnchor, constant: -12)
        ])

        // Mock API card
        let mockAPICard = createSectionContainer()
        let mockAPIStack = UIStackView(arrangedSubviews: [responseModeSegment, mockStatusLabel])
        mockAPIStack.axis = .vertical
        mockAPIStack.spacing = 10
        mockAPIStack.translatesAutoresizingMaskIntoConstraints = false
        mockAPICard.addSubview(mockAPIStack)
        NSLayoutConstraint.activate([
            mockAPIStack.topAnchor.constraint(equalTo: mockAPICard.topAnchor, constant: 12),
            mockAPIStack.leadingAnchor.constraint(equalTo: mockAPICard.leadingAnchor, constant: 16),
            mockAPIStack.trailingAnchor.constraint(equalTo: mockAPICard.trailingAnchor, constant: -16),
            mockAPIStack.bottomAnchor.constraint(equalTo: mockAPICard.bottomAnchor, constant: -12)
        ])

        // Actions section
        let actionsStack = UIStackView(arrangedSubviews: [trackOneEventButton, trackThreeEventsButton])
        actionsStack.axis = .vertical
        actionsStack.spacing = 8

        // Log section with table
        logTableView.dataSource = self
        logTableView.delegate = self
        logTableView.heightAnchor.constraint(equalToConstant: 300).isActive = true

        contentStack.addArrangedSubview(setupSectionLabel)
        contentStack.addArrangedSubview(setupCard)
        contentStack.addArrangedSubview(mockAPISectionLabel)
        contentStack.addArrangedSubview(mockAPICard)
        contentStack.addArrangedSubview(actionsSectionLabel)
        contentStack.addArrangedSubview(actionsStack)
        contentStack.addArrangedSubview(logSectionLabel)
        contentStack.addArrangedSubview(logTableView)
        contentStack.addArrangedSubview(goHomeButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        updateSetupState()
    }

    private func setupActions() {
        setupButton.addTarget(self, action: #selector(performSetup), for: .touchUpInside)
        teardownButton.addTarget(self, action: #selector(performTeardown), for: .touchUpInside)
        trackOneEventButton.addTarget(self, action: #selector(trackOneEvent), for: .touchUpInside)
        trackThreeEventsButton.addTarget(self, action: #selector(trackThreeEvents), for: .touchUpInside)
        responseModeSegment.addTarget(self, action: #selector(responseModeChanged), for: .valueChanged)
        goHomeButton.addTarget(self, action: #selector(goHome), for: .touchUpInside)
    }

    private func createSectionContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor
        return container
    }

    private func syncUIFromMockServer() {
        let modes = MockAPIServer.APIResponseMode.allCases
        if let index = modes.firstIndex(of: mockServer.apiResponseMode) {
            responseModeSegment.selectedSegmentIndex = index
        }
    }

    // MARK: - Setup / Teardown

    @objc private func performSetup() {
        addLogEntry(type: .setup, detail: "Setting up mock JWT environment...")

        // Step 1: Activate mock server (registers URLProtocol via swizzling)
        mockServer.activate()
        addLogEntry(type: .setup, detail: "Mock JWT server activated")

        // Step 2: Reinitialize SDK with mock JWT auth delegate
        // This creates NEW URLSessions that pick up the swizzled protocols
        AppDelegate.reinitializeSDKWithMockJWT()
        addLogEntry(type: .setup, detail: "SDK reinitialized with mock JWT auth")

        // Step 3: Register a test user so events can be tracked
        IterableAPI.email = "offline-retry-test@test.com"
        addLogEntry(type: .setup, detail: "Registered test email")

        updateSetupState()

        // Verify flags after remote config fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            let offlineMode = UserDefaults.standard.bool(forKey: "itbl_offline_mode")
            let autoRetry = UserDefaults.standard.bool(forKey: "itbl_auto_retry")
            self?.addLogEntry(type: .setup, detail: "SDK flags: offlineMode=\(offlineMode), autoRetry=\(autoRetry)")
            if offlineMode && autoRetry {
                self?.addLogEntry(type: .setup, detail: "Ready! Track events to test 401 retry flow.")
            } else {
                self?.addLogEntry(type: .setup, detail: "Warning: offlineMode or autoRetry not enabled. Enable them from Config Overrides and reinitialize.")
            }
        }
    }

    @objc private func performTeardown() {
        mockServer.deactivate()
        AppDelegate.mockAuthDelegate = nil
        AppDelegate.initializeIterableSDK()
        addLogEntry(type: .setup, detail: "Mock JWT server disabled, SDK reset to normal")
        updateSetupState()
    }

    private func updateSetupState() {
        let mockActive = mockServer.isActive
        let hasAuth = AppDelegate.mockAuthDelegate != nil
        let offlineMode = UserDefaults.standard.bool(forKey: "itbl_offline_mode")
        let autoRetry = UserDefaults.standard.bool(forKey: "itbl_auto_retry")

        if mockActive && hasAuth {
            var status = "Mock JWT: ON | Auth: Mock"
            if offlineMode && autoRetry {
                status += " | Flags: OK"
                setupStatusLabel.textColor = .systemGreen
            } else {
                status += " | Flags: offlineMode=\(offlineMode), autoRetry=\(autoRetry)"
                setupStatusLabel.textColor = .systemOrange
            }
            setupStatusLabel.text = status
            setupButton.backgroundColor = .systemGray4
            setupButton.setTitle("Re-setup (already configured)", for: .normal)
            teardownButton.isHidden = false
        } else {
            setupStatusLabel.text = "Not configured — tap Setup to begin"
            setupStatusLabel.textColor = .systemGray
            setupButton.backgroundColor = .systemPurple
            setupButton.setTitle("Enable Mock JWT Server & Reinitialize SDK", for: .normal)
            teardownButton.isHidden = true
        }
    }

    // MARK: - Polling

    private func startPolling() {
        updateMockStatus()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.updateMockStatus() }
        }
    }

    private func updateMockStatus() {
        let active = mockServer.isActive ? "active" : "inactive"
        let requests = mockServer.requestCount
        let authRefreshed = mockServer.authHasRefreshed ? "yes" : "no"
        let tokenCount = AppDelegate.mockAuthDelegate?.tokenRequestCount ?? 0
        mockStatusLabel.text = "Mock: \(active) | Requests: \(requests) | Auth refreshed: \(authRefreshed) | Tokens: \(tokenCount)"
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        let notifications: [(String, LogEntry.EntryType)] = [
            ("itbl_task_finished_with_success", .success),
            ("itbl_task_finished_with_retry", .retry),
            ("itbl_task_finished_with_no_retry", .noRetry),
            ("itbl_auth_token_refreshed", .authRefresh)
        ]

        for (name, type) in notifications {
            let observer = NotificationCenter.default.addObserver(
                forName: Notification.Name(rawValue: name),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let taskId = (notification.userInfo?["taskId"] as? String) ?? ""
                let detail = taskId.isEmpty ? type.rawValue : "\(type.rawValue) - \(taskId.prefix(8))..."
                self?.addLogEntry(type: type, detail: detail)
            }
            notificationObservers.append(observer)
        }
    }

    // MARK: - Actions

    @objc private func responseModeChanged() {
        let modes = MockAPIServer.APIResponseMode.allCases
        let index = responseModeSegment.selectedSegmentIndex
        guard index >= 0, index < modes.count else { return }
        mockServer.apiResponseMode = modes[index]
        mockServer.resetAuthState()
        print("[OFFLINE RETRY] API response mode: \(modes[index].rawValue)")
    }

    @objc private func trackOneEvent() {
        let timestamp = Int(Date().timeIntervalSince1970)
        IterableAPI.track(
            event: "offline_retry_test",
            dataFields: ["timestamp": timestamp, "source": "integration_tester"]
        )
        addLogEntry(type: .eventSent, detail: "Tracked: offline_retry_test")
        print("[OFFLINE RETRY] Tracked test event at \(timestamp)")
    }

    @objc private func trackThreeEvents() {
        for i in 1...3 {
            let timestamp = Int(Date().timeIntervalSince1970)
            IterableAPI.track(
                event: "offline_retry_batch_\(i)",
                dataFields: ["timestamp": timestamp, "index": i, "source": "integration_tester"]
            )
            addLogEntry(type: .eventSent, detail: "Tracked: offline_retry_batch_\(i)")
        }
        print("[OFFLINE RETRY] Tracked 3 batch events")
    }

    @objc private func goHome() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func clearLog() {
        logEntries.removeAll()
        logTableView.reloadData()
    }

    // MARK: - Log Management

    private func addLogEntry(type: LogEntry.EntryType, detail: String) {
        let entry = LogEntry(timestamp: Date(), type: type, detail: detail)
        logEntries.insert(entry, at: 0)
        logTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension OfflineRetryTestViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath)
        let entry = logEntries[indexPath.row]

        let formatter = DateFormatter()
        formatter.timeStyle = .medium

        var config = cell.defaultContentConfiguration()
        config.text = entry.detail
        config.textProperties.color = entry.color
        config.textProperties.font = .systemFont(ofSize: 14, weight: .medium)
        config.secondaryText = formatter.string(from: entry.timestamp)
        config.secondaryTextProperties.font = .systemFont(ofSize: 11)
        config.secondaryTextProperties.color = .systemGray
        cell.contentConfiguration = config

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}
