import UIKit
@testable import IterableSDK

/// A project the switch screen can move to. C is a second mobile key on A's project and D a
/// second mobile key on B's, so C and D share their parent's region and test user.
struct BCITSwitchProject {
    let label: String
    let mobileApiKey: String
    let testUserEmail: String
    /// One of the `IterableDataRegion` endpoints.
    let dataRegion: String
}

/// Drives `IterableAPI.switchProject` for the switch screen and records an ordered event log in
/// the format shared with the Android BCIT harness. Lives for the whole process so callbacks and
/// requests are still logged after the screen is popped.
final class ProjectSwitchCoordinator {
    static let shared = ProjectSwitchCoordinator()
    static let didChange = Notification.Name("ProjectSwitchCoordinatorDidChange")
    static let labels = ["A", "B", "C", "D"]
    static let trackEventName = "bcit_project_switch"

    let projects: [String: BCITSwitchProject]
    private let iterableProjects: [String: IterableProject]

    var logLines: [String] { entries.map { $0.line } }
    private var entries: [(date: Date, line: String)] = []
    private(set) var lastRequestedLabel: String?
    private(set) var pendingCallbacks = 0
    private(set) var hasSwitched = false
    private let isRunningInCI = AppDelegate.isRunningInCI
    private(set) var lastResult: IterableProjectSwitchResult?
    private(set) var requestCountsSinceLastSwitch: [String: Int] = [:]
    var reidentifyFromCallback = true

    private let maxLogLines = 2000
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private init() {
        let configA = (email: AppDelegate.loadTestUserEmailFromConfig() ?? "", region: IterableDataRegion.US)
        var projects = ["A": BCITSwitchProject(label: "A", mobileApiKey: AppDelegate.loadApiKeyFromConfig(),
                                               testUserEmail: configA.email, dataRegion: configA.region)]
        if let configB = AppDelegate.loadProjectBConfig() {
            let emailB = configB.testUserEmail ?? configA.email
            projects["B"] = BCITSwitchProject(label: "B", mobileApiKey: configB.mobileApiKey,
                                              testUserEmail: emailB, dataRegion: configB.dataRegion)
            if let keyD = AppDelegate.loadProjectDApiKeyFromConfig() {
                projects["D"] = BCITSwitchProject(label: "D", mobileApiKey: keyD,
                                                  testUserEmail: emailB, dataRegion: configB.dataRegion)
            }
        }
        if let keyC = AppDelegate.loadProjectCApiKeyFromConfig() {
            projects["C"] = BCITSwitchProject(label: "C", mobileApiKey: keyC,
                                              testUserEmail: configA.email, dataRegion: configA.region)
        }
        self.projects = projects
        self.iterableProjects = projects.compactMapValues { project in
            IterableProject(apiKey: project.mobileApiKey, config: ProjectSwitchCoordinator.makeConfig(for: project))
        }

        NotificationCenter.default.addObserver(forName: NetworkMonitor.didAddRequest, object: nil, queue: .main) { [weak self] note in
            guard let request = note.userInfo?["request"] as? NetworkRequest else { return }
            self?.logRequest(request)
        }
    }

    // MARK: - State

    var liveApiKey: String? { IterableAPI.implementation?.apiKey }
    var liveBaseURL: String? { IterableAPI.implementation?.apiEndPointForTest }
    var liveLabel: String { liveApiKey.map(label(forKey:)) ?? "-" }
    var requestedLabel: String { lastRequestedLabel ?? liveLabel }
    var canInitialize: Bool { pendingCallbacks == 0 && !hasSwitched }

    func label(forKey key: String?) -> String {
        guard let key = key else { return "?" }
        return Self.labels.first { projects[$0]?.mobileApiKey == key } ?? "?"
    }

    static func mask(_ key: String?) -> String {
        guard let key = key, !key.isEmpty else { return "none" }
        return "\(key.prefix(4))...\(key.suffix(4))"
    }

    static func name(of result: IterableProjectSwitchResult) -> String {
        switch result {
        case .switchedCleanly: return "switchedCleanly"
        case .switchedWithWarnings: return "switchedWithWarnings"
        @unknown default: return "unknown(\(result.rawValue))"
        }
    }

    // MARK: - Actions

    /// Calls `initialize` directly, so it is refused once a switch has run until the log is cleared.
    func initializeOnA() {
        guard canInitialize, let project = iterableProjects["A"] else { return }
        AppDelegate.lastInitMode = .standard
        IterableAPI.initialize(apiKey: project.apiKey, launchOptions: nil, config: project.config)
        lastRequestedLabel = "A"
        info("init on A re-initializes the SDK without a switch, autoPushRegistration=true")
        if isRunningInCI {
            registerCIMockToken(project: "A")
        }
    }

    func identifyOnRequestedProject() {
        guard let project = projects[requestedLabel] else { return }
        log("CALL setEmail project=\(requestedLabel)")
        IterableAPI.setEmail(project.testUserEmail)
    }

    func track() {
        log("CALL track name=\(Self.trackEventName) project=\(requestedLabel)")
        IterableAPI.track(event: Self.trackEventName)
    }

    /// - Parameter reidentify: whether the callback calls `setEmail`, fixed at request time.
    ///   Defaults to the re-identify toggle.
    func switchTo(_ label: String, reidentify: Bool? = nil) {
        let reidentify = reidentify ?? reidentifyFromCallback
        guard let project = iterableProjects[label] else {
            info("project \(label) is not configured")
            return
        }
        lastRequestedLabel = label
        hasSwitched = true
        pendingCallbacks += 1
        lastResult = nil
        requestCountsSinceLastSwitch = [:]
        log("REQUEST switch -> \(label)")
        IterableAPI.switchProject(project: project) { [weak self] result in
            self?.handleCallback(label: label, result: result, reidentify: reidentify)
        }
    }

    /// Fires every step back to back without waiting for callbacks. The first step is the
    /// starting point of the path, so it is skipped when the SDK is already headed there.
    func rapidFire(_ path: [String]) {
        info("rapid \(path.joined(separator: " -> "))")
        let steps = path.first == requestedLabel ? Array(path.dropFirst()) : path
        steps.forEach { switchTo($0) }
    }

    /// Never re-identifies from the callback, which would mask whether the setEmail made
    /// during the switch was replayed against the right project.
    func switchAndCallDuring() {
        let target = ["A", "C"].contains(requestedLabel) ? "B" : "A"
        switchTo(target, reidentify: false)
        identifyOnRequestedProject()
        track()
    }

    func clearLog() {
        entries.removeAll()
        requestCountsSinceLastSwitch = [:]
        if pendingCallbacks == 0 {
            hasSwitched = false
        }
        notifyChange()
    }

    // MARK: - Private

    private static func makeConfig(for project: BCITSwitchProject) -> IterableConfig {
        let config = IterableConfig()
        // IterableConfig holds its delegates weakly. Both are process-lifetime objects.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        config.customActionDelegate = appDelegate
        config.urlDelegate = appDelegate
        config.logDelegate = SDKLogCapture.shared
        config.inAppDisplayInterval = 1
        // On, unlike the rest of BCIT: with it off the teardown never disables the device on the outgoing project.
        config.autoPushRegistration = true
        config.allowedProtocols = ["tester", "https", "http"]
        config.enableEmbeddedMessaging = true
        config.dataRegion = project.dataRegion
        return config
    }

    private func handleCallback(label: String, result: IterableProjectSwitchResult, reidentify: Bool) {
        pendingCallbacks -= 1
        lastResult = result
        log("CALLBACK \(label) result=\(Self.name(of: result))")
        guard reidentify, let project = projects[label] else { return }
        info("re-identify from callback \(label)")
        log("CALL setEmail project=\(label)")
        IterableAPI.setEmail(project.testUserEmail)
        if isRunningInCI {
            registerCIMockToken(project: label)
        }
    }

    /// CI simulators get no APNs token, so this stands in for the token the OS hands back after
    /// `autoPushRegistration` asks for one. Only the app can register it, as on a device.
    private func registerCIMockToken(project label: String) {
        let token = AppDelegate.getRegisteredDeviceToken() ?? AppDelegate.generateMockDeviceToken()
        info("CI mock device token stands in for APNs")
        log("CALL registerToken project=\(label)")
        AppDelegate.registerDeviceToken(token.hexStringToData())
    }

    private func logRequest(_ request: NetworkRequest) {
        guard let key = request.headers.first(where: { $0.key.caseInsensitiveCompare("Api-Key") == .orderedSame })?.value else {
            return
        }
        let label = label(forKey: key)
        requestCountsSinceLastSwitch[label, default: 0] += 1
        let host = request.url.host ?? "?"
        log("NET \(request.method) \(host)\(request.url.path) key=\(Self.mask(key)) [\(label)]", at: request.timestamp)
    }

    private func info(_ text: String) {
        log("INFO \(text)")
    }

    /// Inserted by timestamp: a request is stamped when it is captured but reaches the main
    /// queue later, so appending would put it after events that happened after it.
    private func log(_ event: String, at date: Date = Date()) {
        let index = entries.lastIndex { $0.date <= date }.map { $0 + 1 } ?? 0
        entries.insert((date, "\(timeFormatter.string(from: date)) \(event)"), at: index)
        if entries.count > maxLogLines {
            entries.removeFirst(entries.count - maxLogLines)
        }
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
}
