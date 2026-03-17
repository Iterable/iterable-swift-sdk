import UIKit
@testable import IterableSDK

final class OfflineRetryTestViewController: UIViewController {

    // MARK: - Properties

    private var statusTimer: Timer?
    private var logEntries: [String] = []
    private var notificationObservers: [NSObjectProtocol] = []
    private var jwtExpiry: JwtExpiry = .oneMin

    // MARK: - UI Components

    // Response mode radio buttons (matches Android)
    private var radioButtons: [UIButton] = []
    private var selectedResponseMode: MockAPIServer.APIResponseMode = .normal

    // Auth status
    private let authStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .systemGreen
        label.text = "Valid (--)"
        return label
    }()

    private let jwtExpiryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("30s", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray3.cgColor
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
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

    }

    deinit {
        statusTimer?.invalidate()
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // --- Response mode radio row ---
        let responseLabel = makeLabel("Response:", bold: true)

        let radioRow = UIStackView()
        radioRow.spacing = 4
        radioRow.alignment = .center
        radioRow.addArrangedSubview(responseLabel)

        for mode in MockAPIServer.APIResponseMode.allCases {
            let button = makeRadioButton(title: mode.rawValue, tag: radioButtons.count)
            radioButtons.append(button)
            radioRow.addArrangedSubview(button)
        }
        // Select first radio
        radioButtons.first?.isSelected = true
        updateRadioAppearance()

        // --- Auth row ---
        let authLabel = makeLabel("Auth:", bold: true)
        let jwtLabel = makeLabel("JWT:", bold: true)

        let authRow = UIStackView(arrangedSubviews: [authLabel, authStatusLabel, UIView(), jwtLabel, jwtExpiryButton])
        authRow.spacing = 6
        authRow.alignment = .center

        let statusStack = UIStackView(arrangedSubviews: [radioRow, authRow])
        statusStack.axis = .vertical
        statusStack.spacing = 8

        // --- Log header ---
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 12)
        clearButton.addTarget(self, action: #selector(clearLog), for: .touchUpInside)

        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 12)
        copyButton.addTarget(self, action: #selector(copyLog), for: .touchUpInside)

        let showDbButton = UIButton(type: .system)
        showDbButton.setTitle("Show DB", for: .normal)
        showDbButton.titleLabel?.font = .systemFont(ofSize: 12)
        showDbButton.addTarget(self, action: #selector(showDatabase), for: .touchUpInside)

        let logHeader = UIStackView(arrangedSubviews: [
            makeLabel("SDK Logs", bold: true),
            UIView(),
            showDbButton,
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

        stack.addArrangedSubview(makeSectionHeader("Scenario 1: Startup with expired JWT"))
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
            "1. Select '401' response mode\n" +
            "2. Press 'Track + Cart' -> logs: 401, queue paused\n" +
            "3. Switch response back to 'Normal'\n" +
            "4. Wait for SDK to refresh token\n" +
            "   -> new valid JWT -> queue resumes\n" +
            "5. Check logs: queued tasks succeed"
        ))

        return stack
    }

    // MARK: - Tab 2: 401 Pause

    private func buildTab401Pause() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario 2: 401 handling and pause behavior"))
        stack.addArrangedSubview(makeSectionDescription(
            "Force 401 responses. Verify offline tasks are retained, processing pauses " +
            "for JWT-required APIs. Only POST endpoints go through the offline queue."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Select '401' response mode\n" +
            "2. Press Track -> check logs: 401 received, queue paused\n" +
            "3. Press Track again -> check logs: task queued\n" +
            "   but not sent to server while paused\n" +
            "4. Switch back to 'Normal' -> tasks flush"
        ))

        return stack
    }

    // MARK: - Tab 3: Token Expiry

    private func buildTabTokenExpiry() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario 3: Token expiry flushes paused queue"))
        stack.addArrangedSubview(makeSectionDescription(
            "Pause the queue with a 401 response, then let the SDK's " +
            "auth timer request a new valid token. The queue should resume."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Set JWT expiry to '30s'\n" +
            "2. Select '401' response mode\n" +
            "3. Press Track -> gets 401, queue pauses\n" +
            "4. Switch response back to 'Normal'\n" +
            "5. Wait for JWT to expire (~30s, watch Auth status)\n" +
            "6. Token refreshes -> queue resumes -> tasks flush\n" +
            "7. Check logs: all tasks succeed"
        ))

        return stack
    }

    // MARK: - Tab 4: Network Flap

    private func buildTabNetworkFlap() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario 4: Network flapping"))
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
            "1. Select 'Conn Err' response mode\n" +
            "2. Press Track / Update Cart (tasks queue in DB)\n" +
            "3. Switch back to 'Normal'\n" +
            "4. Verify all tasks eventually succeed\n" +
            "5. Try: 'Conn Err' -> queue tasks ->\n" +
            "   switch to '401' -> then 'Normal' ->\n" +
            "   observe 401 pause -> auth refresh -> tasks flush"
        ))

        return stack
    }

    // MARK: - Tab 5: Feature Flags

    private func buildTabFeatureFlag() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario 5: Feature flag & backend config"))
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
            "2. Reinitialize SDK, Track event\n" +
            "3. Verify: request goes online (no queueing)\n\n" +
            "Steps (flag ON):\n" +
            "1. Go to Config Overrides, check both flags\n" +
            "2. Reinitialize SDK\n" +
            "3. Select '401' response mode, Track event\n" +
            "4. Verify: task queued, 401 pauses, retry fires"
        ))

        return stack
    }

    // MARK: - Tab 6: Free Style

    private func buildTabFreeStyle() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        stack.addArrangedSubview(makeSectionHeader("Scenario 6: Free Style"))
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

        let goHomeButton = UIButton(type: .system)
        goHomeButton.setTitle("Go Back to Home Screen", for: .normal)
        goHomeButton.backgroundColor = .systemGray3
        goHomeButton.setTitleColor(.white, for: .normal)
        goHomeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        goHomeButton.layer.cornerRadius = 8
        goHomeButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        goHomeButton.addTarget(self, action: #selector(goHome), for: .touchUpInside)
        stack.addArrangedSubview(goHomeButton)

        return stack
    }

    // MARK: - Actions

    @objc private func radioTapped(_ sender: UIButton) {
        let modes = MockAPIServer.APIResponseMode.allCases
        guard sender.tag < modes.count else { return }

        radioButtons.forEach { $0.isSelected = false }
        sender.isSelected = true
        updateRadioAppearance()

        let mode = modes[sender.tag]
        selectedResponseMode = mode
        MockAPIServer.shared.apiResponseMode = mode

        if mode == .normal {
            MockAPIServer.shared.deactivate()
            log("Response: Normal (real API)")
        } else {
            MockAPIServer.shared.activate()
            log("Response: \(mode.rawValue) (mock)")
        }
    }

    @objc private func showDatabase() {
        guard let container = PersistentContainer.shared else {
            log("DB: CoreData not initialized (offline mode may be off)")
            return
        }

        let context = container.newBackgroundContext()
        context.perform { [weak self] in
            do {
                let request = IterableTaskManagedObject.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                let tasks = try context.fetch(request)

                var lines: [String] = []
                lines.append("=== Offline Task DB (\(tasks.count) tasks) ===")
                for task in tasks {
                    let id = (task.id ?? "?").prefix(8)
                    let name = task.name ?? "?"
                    let attempts = task.attempts
                    let failed = task.failed
                    let processing = task.processing
                    let created = task.createdAt.map { self?.shortDate($0) ?? "?" } ?? "?"
                    lines.append("[\(id)] \(name) | att:\(attempts) fail:\(failed) proc:\(processing) | \(created)")
                }
                if tasks.isEmpty {
                    lines.append("(empty — no pending tasks)")
                }
                lines.append("=================================")

                DispatchQueue.main.async {
                    for line in lines {
                        self?.log(line)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.log("DB Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
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
                self?.jwtExpiryButton.setTitle(expiry.rawValue, for: .normal)
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
        // Try to read the current auth token from the SDK's keychain
        let remaining = JwtHelper.remainingLabel(token: nil) // TODO: get current token from SDK
        if remaining == "Expired" || remaining == "No Token" {
            authStatusLabel.text = remaining
            authStatusLabel.textColor = .systemRed
        } else {
            authStatusLabel.text = "Valid (\(remaining))"
            authStatusLabel.textColor = .systemGreen
        }
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

    private func makeRadioButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "circle.inset.filled"), for: .selected)
        button.tintColor = .systemPurple
        button.setTitle(" \(title)", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.addTarget(self, action: #selector(radioTapped(_:)), for: .touchUpInside)
        return button
    }

    private func updateRadioAppearance() {
        for button in radioButtons {
            button.tintColor = button.isSelected ? .systemPurple : .systemGray3
        }
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
