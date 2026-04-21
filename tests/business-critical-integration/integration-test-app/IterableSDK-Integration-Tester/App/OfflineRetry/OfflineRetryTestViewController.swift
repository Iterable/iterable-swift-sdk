import UIKit
@testable import IterableSDK

final class OfflineRetryTestViewController: UIViewController {

    // MARK: - Properties

    private var statusTimer: Timer?
    private var notificationObservers: [NSObjectProtocol] = []
    private var jwtExpiry: JwtExpiry = .thirtySec
    private let logStore = LogStore.shared
    private var lastAuthTokenState: AuthTokenValidityState = .unknown

    // MARK: - UI Components

    // Initialize button
    private let initButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Initialize with JWT Auth", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return button
    }()

    // Email + Login/Logout
    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "user@example.com"
        field.font = .systemFont(ofSize: 13)
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .emailAddress
        field.returnKeyType = .done
        return field
    }()

    // Response mode radio buttons (matches Android)
    private var radioButtons: [UIButton] = []
    private var selectedResponseMode: MockAPIServer.APIResponseMode = .normal

    // Hint beside the radios: "→ real backend" vs "→ local mock"
    private let responseDestinationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .systemGray
        label.text = "→ real backend (direct)"
        return label
    }()

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
        button.setTitle(JwtExpiry.thirtySec.rawValue, for: .normal)
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

    private let logCountLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .systemGray
        label.text = "(0)"
        return label
    }()

    // Log panel (UITextView — simple, scrollable, guaranteed to render)
    private let logTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        tv.backgroundColor = UIColor(white: 0.96, alpha: 1)
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return tv
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        log("📱 JWT Auth Retry screen opened")

        // Re-initialize SDK with JWT auth every time screen appears
        // (e.g. returning from Config Override Panel picks up new settings)
        AppDelegate.reinitializeSDKWithJWTOnly()
        log("Initialized SDK with JWT auth")

        refreshLogDisplay()
    }

    deinit {
        statusTimer?.invalidate()
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // --- Email + Login/Logout row ---
        // Restore last-used email from UserDefaults (empty on first launch)
        emailField.text = UserDefaults.standard.string(forKey: "jwtRetry_lastEmail") ?? ""
        emailField.delegate = self

        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        loginButton.layer.cornerRadius = 6
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        loginButton.addTarget(self, action: #selector(performLogin), for: .touchUpInside)
        loginButton.setContentHuggingPriority(.required, for: .horizontal)
        loginButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        logoutButton.layer.cornerRadius = 6
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        logoutButton.addTarget(self, action: #selector(performLogout), for: .touchUpInside)
        logoutButton.setContentHuggingPriority(.required, for: .horizontal)
        logoutButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let emailRow = UIStackView(arrangedSubviews: [emailField, loginButton, logoutButton])
        emailRow.spacing = 6
        emailRow.alignment = .center

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
        radioRow.addArrangedSubview(responseDestinationLabel)
        // Select first radio
        radioButtons.first?.isSelected = true
        updateRadioAppearance()

        // --- Auth row ---
        let authLabel = makeLabel("Auth:", bold: true)
        let jwtLabel = makeLabel("JWT:", bold: true)

        let authRow = UIStackView(arrangedSubviews: [authLabel, authStatusLabel, UIView(), jwtLabel, jwtExpiryButton])
        authRow.spacing = 6
        authRow.alignment = .center

        let jwtHint = UILabel()
        jwtHint.text = "JWT expiry time takes effect on next initialization"
        jwtHint.font = .systemFont(ofSize: 9)
        jwtHint.textColor = .systemGray
        jwtHint.textAlignment = .right

        let statusStack = UIStackView(arrangedSubviews: [emailRow, radioRow, authRow, jwtHint])
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
            logCountLabel,
            UIView(),
            showDbButton,
            copyButton,
            clearButton
        ])
        logHeader.spacing = 8
        logHeader.alignment = .center

        // --- Go Home button ---
        let goHomeBtn = UIButton(type: .system)
        goHomeBtn.setTitle("Go Back to Home Screen", for: .normal)
        goHomeBtn.backgroundColor = .systemGray3
        goHomeBtn.setTitleColor(.white, for: .normal)
        goHomeBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        goHomeBtn.layer.cornerRadius = 8
        goHomeBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        goHomeBtn.addTarget(self, action: #selector(goHome), for: .touchUpInside)

        // --- Main layout ---
        let mainStack = UIStackView(arrangedSubviews: [
            statusStack,
            makeDivider(),
            tabSegment,
            tabContentView,
            makeDivider(),
            logHeader,
            logTextView,
            goHomeBtn
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 6
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            tabContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            logTextView.heightAnchor.constraint(equalTo: mainStack.heightAnchor, multiplier: 0.25)
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

        stack.addArrangedSubview(makeSectionHeader("Scenario: Startup with invalid/expired JWT"))
        stack.addArrangedSubview(makeSectionDescription(
            "Start with invalid JWT. Fire multiple parallel offline calls. " +
            "Expect: single auth refresh, all requests retried after refresh, no drops."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Fire All (Track + Cart)", #selector(fireAll)),
            ("Sync Embedded", #selector(performSyncEmbedded))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Make sure autoRetry, offlineMode enabled\n" +
            "2. Login with email\n" +
            "3. Set Response Mode to 401\n" +
            "4. Press 'Fire All' → logs: 401, queue paused\n" +
            "5. Switch Response Mode to Normal\n" +
            "6. Press 'Sync Embedded' → online call triggers\n" +
            "   new valid JWT → queue resumes\n" +
            "7. Check logs: queued tasks succeed"
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
            "Force 401 responses. Verify offline tasks are retained, processing pauses " +
            "for JWT-required APIs. Only POST endpoints go through the offline queue."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeOutlinedButton("Show DB", action: #selector(showDatabase)))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Make sure autoRetry, offlineMode enabled\n" +
            "2. Login with email (Normal mode)\n" +
            "3. Set Response Mode to 401\n" +
            "4. Press Track → check logs: 401 received, queue paused\n" +
            "5. Show DB: task retained (PENDING)\n" +
            "6. Press Track again → check logs: no new request sent\n" +
            "   (task queued in DB but not sent to server while paused)"
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
            "Pause the queue with a 401, then let the token expire and refresh. " +
            "The new valid token should resume the queue and flush pending tasks."
        ))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeOutlinedButton("Show DB", action: #selector(showDatabase)))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Make sure autoRetry, offlineMode enabled\n" +
            "2. Set JWT dropdown to 30s\n" +
            "3. Login with email (Normal mode)\n" +
            "4. Set Response Mode to 401\n" +
            "5. Press Track → gets 401, queue pauses\n" +
            "6. Show DB: task is PENDING\n" +
            "7. Set Response Mode back to Normal\n" +
            "8. Wait for JWT to expire (~30s, watch Auth status)\n" +
            "9. Token refreshes → queue resumes → tasks flush\n" +
            "10. Show DB: queue should be empty"
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
            "Queue tasks while offline, then restore connectivity. " +
            "Ensure no data loss, no stuck queue after recovery."
        ))

        stack.addArrangedSubview(makeColorButtonRow([
            ("Go Offline", #selector(goOffline), UIColor(red: 0.9, green: 0.32, blue: 0, alpha: 1)),
            ("Go Online", #selector(goOnline), UIColor(red: 0.18, green: 0.49, blue: 0.2, alpha: 1))
        ]))

        stack.addArrangedSubview(makeButtonRow([
            ("Track", #selector(performTrack)),
            ("Update Cart", #selector(performUpdateCart))
        ]))

        stack.addArrangedSubview(makeSectionHint(
            "Steps:\n" +
            "1. Make sure autoRetry, offlineMode enabled\n" +
            "2. Login with email (Normal mode)\n" +
            "3. Press 'Go Offline'\n" +
            "4. Press Track / Update Cart (tasks queue in DB)\n" +
            "5. Show DB: tasks are PENDING\n" +
            "6. Press 'Go Online'\n" +
            "7. Verify all tasks eventually succeed\n" +
            "8. Try: Go Offline → queue tasks → 401 mode →\n" +
            "   Go Online → observe 401 pause → Normal mode"
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
            "Flags take effect on next SDK init (app restart)."
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
            "Steps (legacy behavior):\n" +
            "1. Uncheck both switches in Config Override Panel\n" +
            "2. Login, Track event\n" +
            "3. Verify: request goes online (no queueing)\n\n" +
            "Steps (new behavior):\n" +
            "1. Check both switches in Config Override Panel\n" +
            "2. Login, set 401 mode, Track event\n" +
            "3. Verify: task queued, 401 pauses, retry fires"
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
            ("Register Push", #selector(performRegisterPush)),
            ("Sync Embedded", #selector(performSyncEmbedded))
        ]))

        stack.addArrangedSubview(makeColorButtonRow([
            ("Go Offline", #selector(goOffline), UIColor(red: 0.9, green: 0.32, blue: 0, alpha: 1)),
            ("Go Online", #selector(goOnline), UIColor(red: 0.18, green: 0.49, blue: 0.2, alpha: 1))
        ]))

        stack.addArrangedSubview(makeOutlinedButton("Show DB", action: #selector(showDatabase)))

        return stack
    }

    // MARK: - Actions

    @objc private func initializeWithJWT() {
        view.endEditing(true)
        AppDelegate.reinitializeSDKWithJWTOnly()
        log("Initialized SDK with JWT auth")
        updateAuthStatus()
    }

    @objc private func performLogin() {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else {
            log("Login: email empty")
            return
        }
        view.endEditing(true)

        // Remember this email for next time
        UserDefaults.standard.set(email, forKey: "jwtRetry_lastEmail")

        // Clear first so setEmail doesn't early-return for same email
        // (matches Android: performLogin clears then sets)
        let currentEmail = IterableAPI.email
        if currentEmail != nil && currentEmail == email {
            IterableAPI.email = nil
        }
        AppDelegate.currentTestEmail = email
        IterableAPI.email = email
        log("Login: \(email)")
        updateAuthStatus()
    }

    @objc private func performLogout() {
        AppDelegate.currentTestEmail = nil
        IterableAPI.email = nil
        log("Logout")
        updateAuthStatus()
    }

    @objc private func radioTapped(_ sender: UIButton) {
        let modes = MockAPIServer.APIResponseMode.allCases
        guard sender.tag < modes.count else { return }

        radioButtons.forEach { $0.isSelected = false }
        sender.isSelected = true
        updateRadioAppearance()

        let mode = modes[sender.tag]
        selectedResponseMode = mode
        MockAPIServer.shared.apiResponseMode = mode

        let destination: String
        switch mode {
        case .normal:          destination = "→ real backend (direct)"
        case .jwt401:          destination = "→ real backend (expired JWT)"
        case .server500:       destination = "→ local mock"
        case .connectionError: destination = "→ local mock"
        }
        responseDestinationLabel.text = destination
        log("Response: \(mode.rawValue) \(destination)")
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

    @objc private func performSyncEmbedded() {
        IterableAPI.embeddedManager.syncMessages {
            LogStore.shared.log("Sync Embedded: completed")
        }
        log("Sync Embedded: triggered")
    }

    @objc private func performRegisterPush() {
        AppDelegate.registerForPushNotifications()
        log("Push: registerForPush called")
    }

    @objc private func goOffline() {
        MockAPIServer.shared.apiResponseMode = .connectionError
        log("Network: OFFLINE (conn err)")
    }

    @objc private func goOnline() {
        MockAPIServer.shared.apiResponseMode = .normal
        log("Network: ONLINE (normal)")
    }

    @objc private func goHome() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc private func clearLog() {
        logStore.clear()
        refreshLogDisplay()
    }

    @objc private func copyLog() {
        UIPasteboard.general.string = logStore.entries.joined(separator: "\n")
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
            DispatchQueue.main.async {
                self?.updateAuthStatus()
                self?.refreshLogDisplay()
            }
        }
    }

    private func refreshLogDisplay() {
        let entries = logStore.entries
        logCountLabel.text = "(\(entries.count))"
        logTextView.text = entries.joined(separator: "\n")
    }

    private func updateAuthStatus() {
        // When in JWT test mode, ONLY use delegate's token — IterableAPI.authToken
        // may return stale expired tokens from keychain across sessions
        let token: String?
        if AppDelegate.mockAuthDelegate != nil {
            token = AppDelegate.mockAuthDelegate?.lastGeneratedToken
        } else {
            token = IterableAPI.authToken
        }
        let remaining = JwtHelper.remainingLabel(token: token)

        // Use cached auth token state from SDK notification
        switch lastAuthTokenState {
        case .valid:
            if remaining == "Expired" || remaining == "No Token" {
                authStatusLabel.text = remaining
                authStatusLabel.textColor = .systemRed
            } else {
                authStatusLabel.text = "Valid (\(remaining))"
                authStatusLabel.textColor = .systemGreen
            }
        case .invalid:
            authStatusLabel.text = "Invalid (\(remaining))"
            authStatusLabel.textColor = .systemRed
        case .unknown:
            if remaining == "Expired" || remaining == "No Token" {
                authStatusLabel.text = remaining
                authStatusLabel.textColor = .systemRed
            } else {
                authStatusLabel.text = "Unknown (\(remaining))"
                authStatusLabel.textColor = .systemOrange
            }
        }
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        // SDK lifecycle notifications → route to shared LogStore
        let notifications: [(String, String)] = [
            ("itbl_task_scheduled", "Task SCHEDULED"),
            ("itbl_task_finished_with_success", "Task SUCCESS"),
            ("itbl_task_finished_with_retry", "Task RETRY"),
            ("itbl_task_finished_with_no_retry", "Task NO_RETRY (deleted)"),
            ("itbl_network_offline", "Network OFFLINE"),
            ("itbl_network_online", "Network ONLINE"),
            ("itbl_auth_token_refreshed", "Auth token REFRESHED")
        ]

        for (name, label) in notifications {
            let observer = NotificationCenter.default.addObserver(
                forName: Notification.Name(rawValue: name),
                object: nil,
                queue: nil
            ) { notification in
                let taskId = (notification.userInfo?["taskId"] as? String).map { " [\(String($0.prefix(8)))]" } ?? ""
                LogStore.shared.log("\(label)\(taskId)")
            }
            notificationObservers.append(observer)
        }

        // Track auth token state changes from the SDK
        let authStateObserver = NotificationCenter.default.addObserver(
            forName: .iterableAuthTokenStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let rawState = notification.userInfo?["state"] as? Int,
               let state = AuthTokenValidityState(rawValue: rawState) {
                self?.lastAuthTokenState = state
                self?.updateAuthStatus()
            }
        }
        notificationObservers.append(authStateObserver)

        // Listen for ANY new log entry added to the shared store
        let logObserver = NotificationCenter.default.addObserver(
            forName: LogStore.didAddEntry,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshLogDisplay()
        }
        notificationObservers.append(logObserver)
    }

    // MARK: - Logging

    /// Convenience to log from this view controller's actions
    private func log(_ message: String) {
        logStore.log(message)
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

    private func makeOutlinedButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeColorButtonRow(_ buttons: [(String, Selector, UIColor)]) -> UIStackView {
        let row = UIStackView()
        row.spacing = 8
        row.distribution = .fillEqually
        for (title, selector, color) in buttons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.backgroundColor = color
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            button.addTarget(self, action: selector, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
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

// MARK: - UITextFieldDelegate

extension OfflineRetryTestViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
