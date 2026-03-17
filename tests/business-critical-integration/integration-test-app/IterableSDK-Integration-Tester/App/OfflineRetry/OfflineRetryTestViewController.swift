import UIKit
import IterableSDK

final class OfflineRetryTestViewController: UIViewController {

    // MARK: - Properties

    private var statusTimer: Timer?
    private var logEntries: [String] = []
    private var notificationObservers: [NSObjectProtocol] = []
    private var jwtExpiry: JwtExpiry = .oneMin

    // MARK: - UI Components

    // Status Bar
    private let jwtModeSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Valid JWT", "Expired JWT"])
        sc.selectedSegmentIndex = 0
        return sc
    }()

    private let authStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .systemGray
        label.text = "Auth: --"
        return label
    }()

    private let jwtExpiryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("JWT: 60s", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        return button
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 13)
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        return tf
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        return button
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        return button
    }()

    // Tabs
    private let tabSegment: UISegmentedControl = {
        let items = ["Startup", "401 Pause", "Token Expiry", "Net Flap", "Flags", "Free"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 10)], for: .normal)
        return sc
    }()

    // Tab content container
    private let tabContentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Log panel
    private let logTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "LogCell")
        table.separatorStyle = .none
        table.backgroundColor = UIColor(white: 0.96, alpha: 1)
        table.layer.cornerRadius = 8
        return table
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JWT Auth Retry Testing"
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        setupNotificationObservers()
        startPolling()
        showTab(0)

        if let configEmail = AppDelegate.loadTestUserEmailFromConfig() {
            emailField.text = configEmail
        }
    }

    deinit {
        statusTimer?.invalidate()
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // --- Status bar ---
        let jwtModeRow = UIStackView(arrangedSubviews: [
            makeLabel("JWT Mode:", bold: true),
            jwtModeSegment
        ])
        jwtModeRow.spacing = 8
        jwtModeRow.alignment = .center

        let authRow = UIStackView(arrangedSubviews: [authStatusLabel, UIView(), jwtExpiryButton])
        authRow.spacing = 8
        authRow.alignment = .center

        let emailRow = UIStackView(arrangedSubviews: [emailField, loginButton, logoutButton])
        emailRow.spacing = 8
        emailRow.alignment = .center
        emailField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let statusStack = UIStackView(arrangedSubviews: [jwtModeRow, authRow, emailRow])
        statusStack.axis = .vertical
        statusStack.spacing = 6

        // --- Log header ---
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 12)
        clearButton.addTarget(self, action: #selector(clearLog), for: .touchUpInside)

        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 12)
        copyButton.addTarget(self, action: #selector(copyLog), for: .touchUpInside)

        let logHeader = UIStackView(arrangedSubviews: [
            makeLabel("SDK Logs", bold: true),
            UIView(),
            copyButton,
            clearButton
        ])
        logHeader.spacing = 8
        logHeader.alignment = .center

        // --- Main layout ---
        let mainStack = UIStackView(arrangedSubviews: [
            statusStack,
            makeDivider(),
            tabSegment,
            tabContentView,
            makeDivider(),
            logHeader,
            logTableView
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        logTableView.dataSource = self
        logTableView.delegate = self

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            tabContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            logTableView.heightAnchor.constraint(equalTo: mainStack.heightAnchor, multiplier: 0.4)
        ])
    }

    private func setupActions() {
        tabSegment.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        jwtModeSegment.addTarget(self, action: #selector(jwtModeChanged), for: .valueChanged)
        loginButton.addTarget(self, action: #selector(performLogin), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(performLogout), for: .touchUpInside)
        jwtExpiryButton.showsMenuAsPrimaryAction = true
        jwtExpiryButton.menu = makeJwtExpiryMenu()
    }

    // MARK: - Tabs

    @objc private func tabChanged() {
        showTab(tabSegment.selectedSegmentIndex)
    }

    private func showTab(_ index: Int) {
        tabContentView.subviews.forEach { $0.removeFromSuperview() }

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        tabContentView.addSubview(scroll)

        let content: UIView
        switch index {
        case 0: content = buildTabStartup()
        case 1: content = buildTab401Pause()
        case 2: content = buildTabTokenExpiry()
        case 3: content = buildTabNetworkFlap()
        case 4: content = buildTabFeatureFlag()
        case 5: content = buildTabFreeStyle()
        default: content = UIView()
        }

        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: tabContentView.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: tabContentView.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: tabContentView.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: tabContentView.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    // MARK: - Tab 1: Startup

    private func buildTabStartup() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario: Startup with expired JWT"))
        stack.addArrangedSubview(makeSectionDescription(
            "Start with expired JWT. Fire multiple parallel offline calls. " +
            "Expect: single auth refresh, all requests retried after refresh, no drops."
        ))

        let row = makeButtonRow([
            ("Track + Cart", #selector(fireAll)),
        ])
        stack.addArrangedSubview(row)

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Login with email\n" +
            "2. Set JWT Mode to 'Expired JWT'\n" +
            "3. Press 'Track + Cart' -> logs: 401, queue paused\n" +
            "4. Switch JWT Mode back to 'Valid JWT'\n" +
            "5. Wait for SDK to refresh token\n" +
            "   -> new valid JWT -> queue resumes\n" +
            "6. Check logs: queued tasks succeed"
        ))

        return stack
    }

    // MARK: - Tab 2: 401 Pause

    private func buildTab401Pause() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario: 401 handling and pause behavior"))
        stack.addArrangedSubview(makeSectionDescription(
            "Force expired JWT. Verify offline tasks are retained, processing pauses " +
            "for JWT-required APIs. Only POST endpoints go through the offline queue."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Login with email (Valid JWT mode)\n" +
            "2. Set JWT Mode to 'Expired JWT'\n" +
            "3. Press Track -> check logs: 401 received, queue paused\n" +
            "4. Press Track again -> check logs: task queued\n" +
            "   but not sent to server while paused\n" +
            "5. Switch back to 'Valid JWT' -> tasks flush"
        ))

        return stack
    }

    // MARK: - Tab 3: Token Expiry

    private func buildTabTokenExpiry() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario: Token expiry flushes paused queue"))
        stack.addArrangedSubview(makeSectionDescription(
            "Pause the queue with an expired JWT, then let the SDK's " +
            "auth timer request a new valid token. The queue should resume."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Set JWT expiry dropdown to '30s'\n" +
            "2. Login with email (Valid JWT mode)\n" +
            "3. Set JWT Mode to 'Expired JWT'\n" +
            "4. Press Track -> gets 401, queue pauses\n" +
            "5. Set JWT Mode back to 'Valid JWT'\n" +
            "6. Wait for JWT to expire (~30s, watch Auth status)\n" +
            "7. Token refreshes -> queue resumes -> tasks flush\n" +
            "8. Check logs: all tasks succeed"
        ))

        return stack
    }

    // MARK: - Tab 4: Network Flap

    private func buildTabNetworkFlap() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario: Network flapping"))
        stack.addArrangedSubview(makeSectionDescription(
            "Queue tasks while offline (airplane mode), then restore connectivity. " +
            "Ensure no data loss, no stuck queue after recovery."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Login with email (Valid JWT mode)\n" +
            "2. Turn on Airplane Mode\n" +
            "3. Press Track / Update Cart (tasks queue in DB)\n" +
            "4. Turn off Airplane Mode\n" +
            "5. Verify all tasks eventually succeed\n" +
            "6. Try: Airplane On -> queue tasks ->\n" +
            "   Expired JWT -> Airplane Off ->\n" +
            "   observe 401 pause -> Valid JWT -> tasks flush"
        ))

        return stack
    }

    // MARK: - Tab 5: Feature Flags

    private func buildTabFeatureFlag() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario: Feature flag & backend config"))
        stack.addArrangedSubview(makeSectionDescription(
            "Verify legacy behavior with flags off, new behavior with flags on. " +
            "Flags are set via Config Overrides page and take effect on SDK reinit."
        ))

        let offlineMode = UserDefaults.standard.bool(forKey: "itbl_offline_mode")
        let autoRetry = UserDefaults.standard.bool(forKey: "itbl_auto_retry")
        let flagsLabel = makeLabel("Current: offlineMode=\(offlineMode), autoRetry=\(autoRetry)", bold: false)
        flagsLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        flagsLabel.textColor = (offlineMode && autoRetry) ? .systemGreen : .systemOrange
        stack.addArrangedSubview(flagsLabel)

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps (flag OFF):\n" +
            "1. Go to Config Overrides, uncheck both flags\n" +
            "2. Reinitialize SDK, login, Track event\n" +
            "3. Verify: request goes online (no queueing)\n\n" +
            "Steps (flag ON):\n" +
            "1. Go to Config Overrides, check both flags\n" +
            "2. Reinitialize SDK, login\n" +
            "3. Set 'Expired JWT' mode, Track event\n" +
            "4. Verify: task queued, 401 pauses, retry fires"
        ))

        return stack
    }

    // MARK: - Tab 6: Free Style

    private func buildTabFreeStyle() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Free Style"))
        stack.addArrangedSubview(makeSectionDescription(
            "All actions available. Try different combinations and observe the logs."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeButtonRow([
            ("Track 3 Events", #selector(trackThreeEvents)),
        ]))

        let goHome = UIButton(type: .system)
        goHome.setTitle("Go Back to Home Screen", for: .normal)
        goHome.backgroundColor = .systemGray3
        goHome.setTitleColor(.white, for: .normal)
        goHome.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        goHome.layer.cornerRadius = 8
        goHome.heightAnchor.constraint(equalToConstant: 40).isActive = true
        goHome.addTarget(self, action: #selector(goHome), for: .touchUpInside)
        stack.addArrangedSubview(goHome)

        return stack
    }

    // MARK: - Actions

    @objc private func jwtModeChanged() {
        let expired = jwtModeSegment.selectedSegmentIndex == 1
        AppDelegate.mockAuthDelegate?.forceExpired = expired
        log(expired ? "JWT Mode: EXPIRED (real API will return 401)" : "JWT Mode: VALID")
    }

    @objc private func performLogin() {
        guard let email = emailField.text, !email.isEmpty else {
            log("Login: email empty")
            return
        }
        AppDelegate.currentTestEmail = email
        IterableAPI.email = email
        log("Login: \(email)")
    }

    @objc private func performLogout() {
        AppDelegate.currentTestEmail = nil
        IterableAPI.email = nil
        log("Logout")
    }

    @objc private func performTrack() {
        IterableAPI.track(
            event: "screenView",
            dataFields: ["screenName": "TestScreen", "timestamp": Int(Date().timeIntervalSince1970)]
        )
        log("Track: screenView queued")
    }

    @objc private func performUpdateCart() {
        IterableAPI.updateCart(items: [
            CommerceItem(id: "test-item-1", name: "Test Item", price: 9.99 as NSNumber, quantity: 1)
        ])
        log("Update Cart: queued")
    }

    @objc private func fireAll() {
        performTrack()
        performUpdateCart()
    }

    @objc private func trackThreeEvents() {
        for i in 1...3 {
            IterableAPI.track(
                event: "batch_\(i)",
                dataFields: ["timestamp": Int(Date().timeIntervalSince1970), "index": i]
            )
        }
        log("Tracked 3 batch events")
    }

    @objc private func goHome() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func clearLog() {
        logEntries.removeAll()
        logTableView.reloadData()
    }

    @objc private func copyLog() {
        UIPasteboard.general.string = logEntries.joined(separator: "\n")
    }

    // MARK: - JWT Expiry Menu

    private func makeJwtExpiryMenu() -> UIMenu {
        UIMenu(title: "JWT Expiry", children: JwtExpiry.allCases.map { expiry in
            UIAction(title: expiry.rawValue) { [weak self] _ in
                self?.jwtExpiry = expiry
                JwtHelper.expiry = expiry
                self?.jwtExpiryButton.setTitle("JWT: \(expiry.rawValue)", for: .normal)
            }
        })
    }

    // MARK: - Polling

    private func startPolling() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.updateAuthStatus() }
        }
    }

    private func updateAuthStatus() {
        let token = IterableAPI.email != nil ? (AppDelegate.mockAuthDelegate?.tokenRequestCount ?? 0) : 0
        let remaining = JwtHelper.remainingLabel(token: nil) // TODO: get current token from SDK
        let expired = jwtModeSegment.selectedSegmentIndex == 1
        let mode = expired ? "Expired" : "Valid"
        authStatusLabel.text = "Auth: \(mode) | Tokens: \(token) | \(remaining)"
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        let notifications: [(String, String)] = [
            ("itbl_task_finished_with_success", "Task SUCCESS"),
            ("itbl_task_finished_with_retry", "Task RETRY"),
            ("itbl_task_finished_with_no_retry", "Task NO_RETRY (deleted)"),
            ("itbl_auth_token_refreshed", "Auth token refreshed")
        ]

        for (name, label) in notifications {
            let observer = NotificationCenter.default.addObserver(
                forName: Notification.Name(rawValue: name),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                let taskId = (notification.userInfo?["taskId"] as? String).map { " [\(String($0.prefix(8)))]" } ?? ""
                self?.log("\(label)\(taskId)")
            }
            notificationObservers.append(observer)
        }
    }

    // MARK: - Logging

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let line = "\(formatter.string(from: Date())) \(message)"
        logEntries.insert(line, at: 0)
        logTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
    }

    // MARK: - UI Helpers

    private func makeLabel(_ text: String, bold: Bool) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = bold ? .systemFont(ofSize: 13, weight: .semibold) : .systemFont(ofSize: 12)
        return label
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.numberOfLines = 0
        return label
    }

    private func makeSectionDescription(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11)
        label.textColor = .systemGray
        label.numberOfLines = 0
        return label
    }

    private func makeSectionHint(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        label.numberOfLines = 0

        let container = UIView()
        container.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1.0)
        container.layer.cornerRadius = 8
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    private func makeButtonRow(_ buttons: [(String, Selector)]) -> UIStackView {
        let row = UIStackView()
        row.spacing = 8
        row.distribution = .fillEqually
        for (title, selector) in buttons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            button.addTarget(self, action: selector, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }
}

// MARK: - UITableViewDataSource & Delegate

extension OfflineRetryTestViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = logEntries[indexPath.row]
        config.textProperties.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        config.textProperties.color = .label
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        24
    }
}
