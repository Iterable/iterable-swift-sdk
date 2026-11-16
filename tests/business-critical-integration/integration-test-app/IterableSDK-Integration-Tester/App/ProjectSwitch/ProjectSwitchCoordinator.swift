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
    static let trackEventName = "bcitProjectSwitch"

    let projects: [String: BCITSwitchProject]
    private let iterableProjects: [String: IterableProject]

    private(set) var logLines: [String] = []
    private(set) var lastRequestedLabel: String?
    private(set) var pendingCallbacks = 0
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

    func initializeOnA() {
        guard let project = iterableProjects["A"] else { return }
        AppDelegate.lastInitMode = .standard
        IterableAPI.initialize(apiKey: project.apiKey, launchOptions: nil, config: project.config)
        lastRequestedLabel = "A"
        info("initialized on A autoPushRegistration=true")
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

    func switchTo(_ label: String) {
        guard let project = iterableProjects[label] else {
            info("project \(label) is not configured")
            return
        }
        lastRequestedLabel = label
        pendingCallbacks += 1
        lastResult = nil
        requestCountsSinceLastSwitch = [:]
        log("REQUEST switch -> \(label)")
        IterableAPI.switchProject(project: project) { [weak self] result in
            self?.handleCallback(label: label, result: result)
        }
    }

    /// Fires every step back to back without waiting for callbacks. The first step is the
    /// starting point of the path, so it is skipped when the SDK is already headed there.
    func rapidFire(_ path: [String]) {
        info("rapid \(path.joined(separator: " -> "))")
        let steps = path.first == requestedLabel ? Array(path.dropFirst()) : path
        steps.forEach(switchTo)
    }

    func switchAndCallDuring() {
        let target = ["A", "C"].contains(requestedLabel) ? "B" : "A"
        switchTo(target)
        identifyOnRequestedProject()
        track()
    }

    func clearLog() {
        logLines.removeAll()
        requestCountsSinceLastSwitch = [:]
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
        // On, unlike the rest of BCIT: with it off every teardown reports warnings and B never gets a registerToken.
        config.autoPushRegistration = true
        config.allowedProtocols = ["tester", "https", "http"]
        config.enableEmbeddedMessaging = true
        config.dataRegion = project.dataRegion
        return config
    }

    private func handleCallback(label: String, result: IterableProjectSwitchResult) {
        pendingCallbacks -= 1
        lastResult = result
        log("CALLBACK \(label) result=\(Self.name(of: result))")
        guard reidentifyFromCallback, let project = projects[label] else { return }
        info("re-identify from callback \(label)")
        log("CALL setEmail project=\(requestedLabel)")
        IterableAPI.setEmail(project.testUserEmail)
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

    private func log(_ event: String, at date: Date = Date()) {
        logLines.append("\(timeFormatter.string(from: date)) \(event)")
        if logLines.count > maxLogLines {
            logLines.removeFirst(logLines.count - maxLogLines)
        }
        notifyChange()
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
}
