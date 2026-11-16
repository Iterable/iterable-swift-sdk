import UIKit
import IterableSDK

final class ProjectSwitchTestViewController: UIViewController {

    // MARK: - Properties

    private let coordinator = ProjectSwitchCoordinator.shared
    private var statusTimer: Timer?
    private var changeObserver: NSObjectProtocol?
    private var isLogStale = false
    private lazy var initButton = makeButton("Init on A", "project-switch-init-a-button", .systemGreen, #selector(initializeOnA))

    // MARK: - UI Components

    private let activeValueLabel = makeValueLabel("project-switch-active-label")
    private let requestedValueLabel = makeValueLabel("project-switch-requested-label")
    private let keyValueLabel = makeValueLabel("project-switch-key-label")
    private let baseURLValueLabel = makeValueLabel("project-switch-base-url-label")
    private let identityValueLabel = makeValueLabel("project-switch-identity-label")
    private let pendingValueLabel = makeValueLabel("project-switch-pending-label")
    private let resultValueLabel = makeValueLabel("project-switch-result-label")
    private let summaryValueLabel = makeValueLabel("project-switch-summary-label")

    private let reidentifyToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.accessibilityIdentifier = "project-switch-reidentify-toggle"
        return toggle
    }()

    private let logTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        tv.backgroundColor = UIColor(white: 0.96, alpha: 1)
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tv.accessibilityIdentifier = "project-switch-log"
        tv.setContentHuggingPriority(.init(1), for: .vertical)
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Project Switch Testing"
        view.backgroundColor = .systemBackground
        reidentifyToggle.isOn = coordinator.reidentifyFromCallback
        reidentifyToggle.addTarget(self, action: #selector(reidentifyChanged), for: .valueChanged)
        setupUI()

        changeObserver = NotificationCenter.default.addObserver(forName: ProjectSwitchCoordinator.didChange,
                                                                object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
        statusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshState()
            if self?.isLogStale == true {
                self?.refreshLog()
            }
        }
        refresh()
    }

    deinit {
        statusTimer?.invalidate()
        if let changeObserver = changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        let stateStack = UIStackView(arrangedSubviews: [
            makeRow("Active project:", activeValueLabel),
            makeRow("Requested:", requestedValueLabel),
            makeRow("Live key:", keyValueLabel),
            makeRow("Base URL:", baseURLValueLabel),
            makeRow("Email / userId:", identityValueLabel),
            makeRow("Pending callbacks:", pendingValueLabel),
            makeRow("Result:", resultValueLabel),
            makeRow("Requests since switch:", summaryValueLabel)
        ])
        stateStack.axis = .vertical
        stateStack.spacing = 2

        let setupRow = makeButtonRow([
            initButton,
            makeButton("setEmail", "project-switch-identify-button", .systemBlue, #selector(identify)),
            makeButton("track", "project-switch-track-button", .systemIndigo, #selector(track))
        ])

        let switchButtons = ProjectSwitchCoordinator.labels.map { label -> UIButton in
            let button = makeButton("To \(label)", "project-switch-to-\(label.lowercased())-button", .systemTeal, #selector(switchTapped(_:)))
            button.tag = ProjectSwitchCoordinator.labels.firstIndex(of: label) ?? 0
            setEnabled(button, coordinator.projects[label] != nil)
            return button
        }

        let rapidBCDC = makeButton("B -> C -> D -> C", "project-switch-rapid-bcdc-button", .systemOrange, #selector(rapidBCDC))
        setEnabled(rapidBCDC, ["B", "C", "D"].allSatisfy { coordinator.projects[$0] != nil })
        let rapidRow = makeButtonRow([
            makeButton("A -> B -> A", "project-switch-rapid-aba-button", .systemOrange, #selector(rapidABA)),
            rapidBCDC
        ])

        let toggleRow = UIStackView(arrangedSubviews: [makeTitleLabel("Re-identify from callback"), UIView(), reidentifyToggle])
        toggleRow.alignment = .center
        let duringRow = makeButtonRow([
            makeButton("Switch + call during", "project-switch-call-during-button", .systemPurple, #selector(callDuring))
        ])

        let logHeader = UIStackView(arrangedSubviews: [
            makeTitleLabel("Event log"),
            UIView(),
            makeTextButton("Copy", "project-switch-copy-log-button", #selector(copyLog)),
            makeTextButton("Clear", "project-switch-clear-log-button", #selector(clearLog))
        ])
        logHeader.spacing = 12
        logHeader.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [
            stateStack, setupRow, makeButtonRow(switchButtons), rapidRow, duringRow, toggleRow, logHeader, logTextView
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            logTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }

    // MARK: - Actions

    @objc private func initializeOnA() { coordinator.initializeOnA() }
    @objc private func identify() { coordinator.identifyOnRequestedProject() }
    @objc private func track() { coordinator.track() }
    @objc private func rapidABA() { coordinator.rapidFire(["A", "B", "A"]) }
    @objc private func rapidBCDC() { coordinator.rapidFire(["B", "C", "D", "C"]) }
    @objc private func callDuring() { coordinator.switchAndCallDuring() }
    @objc private func clearLog() { coordinator.clearLog() }

    @objc private func switchTapped(_ sender: UIButton) {
        coordinator.switchTo(ProjectSwitchCoordinator.labels[sender.tag])
    }

    @objc private func reidentifyChanged() {
        coordinator.reidentifyFromCallback = reidentifyToggle.isOn
    }

    @objc private func copyLog() {
        UIPasteboard.general.string = coordinator.logLines.joined(separator: "\n")
    }

    // MARK: - Rendering

    private func refresh() {
        refreshState()
        refreshLog()
    }

    /// Held while the tester has text selected, and only follows the tail when already at the bottom.
    private func refreshLog() {
        guard logTextView.selectedRange.length == 0 else {
            isLogStale = true
            return
        }
        isLogStale = false
        let maxOffset = logTextView.contentSize.height - logTextView.bounds.height
        let wasAtBottom = logTextView.contentOffset.y >= maxOffset - 20
        logTextView.text = coordinator.logLines.joined(separator: "\n")
        if wasAtBottom {
            logTextView.scrollRangeToVisible(NSRange(location: (logTextView.text as NSString).length, length: 0))
        }
    }

    private func refreshState() {
        activeValueLabel.text = coordinator.liveLabel
        requestedValueLabel.text = coordinator.requestedLabel
        keyValueLabel.text = ProjectSwitchCoordinator.mask(coordinator.liveApiKey)
        baseURLValueLabel.text = coordinator.liveBaseURL ?? "-"
        identityValueLabel.text = "\(IterableAPI.email ?? "-") / \(IterableAPI.userId ?? "-")"
        pendingValueLabel.text = "\(coordinator.pendingCallbacks)"
        setEnabled(initButton, coordinator.canInitialize)
        resultValueLabel.text = coordinator.lastResult.map { ".\(ProjectSwitchCoordinator.name(of: $0))" } ?? "-"
        let counts = coordinator.requestCountsSinceLastSwitch
        summaryValueLabel.text = (ProjectSwitchCoordinator.labels + ["?"]).map { "\($0)=\(counts[$0] ?? 0)" }.joined(separator: " ")
    }

    // MARK: - Helpers

    private func makeTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }

    private func makeRow(_ title: String, _ value: UILabel) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [makeTitleLabel(title), value])
        row.spacing = 6
        return row
    }

    private func makeButtonRow(_ buttons: [UIButton]) -> UIStackView {
        let row = UIStackView(arrangedSubviews: buttons)
        row.spacing = 6
        row.distribution = .fillEqually
        return row
    }

    private func makeButton(_ title: String, _ identifier: String, _ color: UIColor, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.accessibilityIdentifier = identifier
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeTextButton(_ title: String, _ identifier: String, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.accessibilityIdentifier = identifier
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func setEnabled(_ button: UIButton, _ enabled: Bool) {
        button.isEnabled = enabled
        button.alpha = enabled ? 1.0 : 0.5
    }
}

private func makeValueLabel(_ identifier: String) -> UILabel {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    label.text = "-"
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.7
    label.accessibilityIdentifier = identifier
    return label
}
