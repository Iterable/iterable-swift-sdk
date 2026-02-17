import UIKit
import IterableSDK

final class RemoteConfigOverrideViewController: UIViewController {

    // MARK: - Properties

    private var pollTimer: Timer?
    private let mockServer = MockAPIServer.shared

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

    // Mock Server Section
    private let mockServerSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Mock Server"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let mockServerToggle = SwitchRowView(title: "Enable Mock Server")

    // Remote Config Overrides Section
    private let overridesSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Remote Config Overrides"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let offlineModeToggle = SwitchRowView(title: "Offline Mode")
    private let autoRetryToggle = SwitchRowView(title: "Auto Retry")

    // Current SDK Values Section
    private let currentValuesSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Current SDK Values"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let currentOfflineModeRow = ValueRowView(title: "Offline Mode")
    private let currentAutoRetryRow = ValueRowView(title: "Auto Retry")

    // Reinitialize Button
    private let reinitializeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reinitialize SDK", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()

    private let reinitializeInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Re-fetches remote config with overridden values"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Remote Config Override"
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        syncUIFromMockServer()
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        // Mock Server card
        let mockServerCard = createCard(subviews: [mockServerToggle])

        // Overrides card
        let overridesCard = createCard(subviews: [offlineModeToggle, autoRetryToggle])

        // Current values card
        let currentValuesCard = createCard(subviews: [currentOfflineModeRow, currentAutoRetryRow])

        contentStack.addArrangedSubview(mockServerSectionLabel)
        contentStack.addArrangedSubview(mockServerCard)
        contentStack.addArrangedSubview(overridesSectionLabel)
        contentStack.addArrangedSubview(overridesCard)
        contentStack.addArrangedSubview(currentValuesSectionLabel)
        contentStack.addArrangedSubview(currentValuesCard)
        contentStack.addArrangedSubview(reinitializeButton)
        contentStack.addArrangedSubview(reinitializeInfoLabel)

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

        updateOverridesEnabled()
    }

    private func setupActions() {
        mockServerToggle.onToggle = { [weak self] isOn in
            if isOn {
                self?.mockServer.activate()
            } else {
                self?.mockServer.deactivate()
            }
            self?.updateOverridesEnabled()
        }

        offlineModeToggle.onToggle = { [weak self] isOn in
            self?.mockServer.overrideOfflineMode = isOn
        }

        autoRetryToggle.onToggle = { [weak self] isOn in
            self?.mockServer.overrideAutoRetry = isOn
        }

        reinitializeButton.addTarget(self, action: #selector(reinitializeSDK), for: .touchUpInside)
    }

    private func createCard(subviews: [UIView]) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray4.cgColor

        let stack = UIStackView(arrangedSubviews: subviews)
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        return container
    }

    // MARK: - State

    private func syncUIFromMockServer() {
        mockServerToggle.setOn(mockServer.isActive)
        offlineModeToggle.setOn(mockServer.overrideOfflineMode)
        autoRetryToggle.setOn(mockServer.overrideAutoRetry)
    }

    private func updateOverridesEnabled() {
        let enabled = mockServer.isActive
        offlineModeToggle.isUserInteractionEnabled = enabled
        offlineModeToggle.alpha = enabled ? 1.0 : 0.5
        autoRetryToggle.isUserInteractionEnabled = enabled
        autoRetryToggle.alpha = enabled ? 1.0 : 0.5
    }

    // MARK: - Polling

    private func startPolling() {
        updateCurrentValues()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.updateCurrentValues() }
        }
    }

    private func updateCurrentValues() {
        let offlineMode = UserDefaults.standard.bool(forKey: "itbl_offline_mode")
        let autoRetry = UserDefaults.standard.bool(forKey: "itbl_auto_retry")
        currentOfflineModeRow.setValue(offlineMode)
        currentAutoRetryRow.setValue(autoRetry)
    }

    // MARK: - Actions

    @objc private func reinitializeSDK() {
        AppDelegate.initializeIterableSDK()

        let alert = UIAlertController(
            title: "SDK Reinitialized",
            message: "Remote config will be fetched with overridden values. Check Current SDK Values in ~2s.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SwitchRowView

private final class SwitchRowView: UIView {

    var onToggle: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    private let toggle: UISwitch = {
        let sw = UISwitch()
        return sw
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, toggle])
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        toggle.addTarget(self, action: #selector(toggled), for: .valueChanged)
    }

    @objc private func toggled() {
        onToggle?(toggle.isOn)
    }

    func setOn(_ on: Bool) {
        toggle.isOn = on
    }
}

// MARK: - ValueRowView

private final class ValueRowView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .right
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func setValue(_ enabled: Bool) {
        valueLabel.text = enabled ? "ON" : "OFF"
        valueLabel.textColor = enabled ? .systemGreen : .systemRed
    }
}
