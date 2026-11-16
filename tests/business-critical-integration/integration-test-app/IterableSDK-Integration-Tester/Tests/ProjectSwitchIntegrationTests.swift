import XCTest
@testable import IterableSDK

class ProjectSwitchIntegrationTests: IntegrationTestBase {

    private var projectBApiKey: String!

    override func setUpWithError() throws {
        guard let projectBApiKey = loadProjectBApiKey() else {
            throw XCTSkip("No projectB block in test-config.json, skipping project switch tests")
        }
        self.projectBApiKey = projectBApiKey
        try super.setUpWithError()
    }

    // MARK: - Test Cases

    func testSwitchFromAToBSendsLaterRequestsWithBKey() {
        print("🚀 Starting project switch A -> B integration test")
        openProjectSwitchScreenOnA()

        app.buttons["project-switch-to-b-button"].tap()
        waitUntilSettled(on: "B")

        app.buttons["project-switch-track-button"].tap()
        let lines = waitForTrackThenQuiet(afterCallbackTo: "B")
        assertRequests(after: "B", in: lines, carry: projectBApiKey, notLeavingProject: "A", key: testConfig.apiKey)

        let result = app.staticTexts["project-switch-result-label"].label
        if isRunningInCI {
            // CI registers a mock token on A first, so A's device disable is confirmed and the teardown is clean.
            XCTAssertTrue(lines.contains { $0.contains("/api/users/disableDevice key=\(mask(testConfig.apiKey)) [A]") },
                          "Leaving A should disable the device on A with A's key")
            XCTAssertTrue(netLines(afterCallbackTo: "B", in: lines).contains {
                $0.contains("/api/users/registerDeviceToken key=\(mask(projectBApiKey)) [B]")
            }, "The token should be registered on B with B's key after the callback")
            XCTAssertEqual(result, ".switchedCleanly", "A switch with a registered token and an identified user should be clean")
        } else {
            assertIsAProjectSwitchResult(result)
        }

        screenshotCapture.captureScreenshot(named: "project-switch-a-to-b")
        print("✅ Project switch A -> B integration test complete")
    }

    func testRapidABASettlesOnA() {
        print("🚀 Starting project switch rapid A -> B -> A integration test")
        openProjectSwitchScreenOnA()

        // Off so B's own re-identify traffic cannot land after A's callback and be read as a leak
        let reidentifyToggle = app.switches["project-switch-reidentify-toggle"]
        reidentifyToggle.tap()
        XCTAssertEqual(reidentifyToggle.value as? String, "0", "Re-identify should be off for the rapid chain")

        app.buttons["project-switch-rapid-aba-button"].tap()
        _ = waitForLog { lines in lines.contains { $0.contains("CALLBACK A result=") } }
        waitUntilSettled(on: "A")
        assertIsAProjectSwitchResult(app.staticTexts["project-switch-result-label"].label)

        let settled = logLines()
        let requestB = settled.firstIndex { $0.hasSuffix("REQUEST switch -> B") }
        let requestA = settled.firstIndex { $0.hasSuffix("REQUEST switch -> A") }
        let callbackB = settled.firstIndex { $0.contains("CALLBACK B result=") }
        let callbackA = settled.firstIndex { $0.contains("CALLBACK A result=") }
        XCTAssertNotNil(requestB, "Rapid A -> B -> A should request B")
        XCTAssertNotNil(requestA, "Rapid A -> B -> A should request A")
        XCTAssertNotNil(callbackB, "B's callback should fire")
        XCTAssertNotNil(callbackA, "A's callback should fire")
        XCTAssertLessThan(requestB ?? .max, requestA ?? .min, "Requests should be logged in the order they were made")
        XCTAssertLessThan(callbackB ?? .max, callbackA ?? .min, "Callbacks should fire in request order, B then A")

        app.buttons["project-switch-identify-button"].tap()
        app.buttons["project-switch-track-button"].tap()
        let lines = waitForTrackThenQuiet(afterCallbackTo: "A")
        assertRequests(after: "A", in: lines, carry: testConfig.apiKey, notLeavingProject: "B", key: projectBApiKey)

        screenshotCapture.captureScreenshot(named: "project-switch-rapid-aba")
        print("✅ Project switch rapid A -> B -> A integration test complete")
    }

    // MARK: - Helpers

    private func loadProjectBApiKey() -> String? {
        guard let path = Bundle(for: type(of: self)).path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let block = json["projectB"] as? [String: Any],
              let mobileApiKey = block["mobileApiKey"] as? String, !mobileApiKey.isEmpty else {
            return nil
        }
        return mobileApiKey
    }

    private func openProjectSwitchScreenOnA() {
        let row = app.otherElements["project-switch-test-row"]
        XCTAssertTrue(row.waitForExistence(timeout: standardTimeout), "Project switch row should exist when projectB is configured")
        if !row.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        row.tap()

        let initButton = app.buttons["project-switch-init-a-button"]
        XCTAssertTrue(initButton.waitForExistence(timeout: standardTimeout), "Init on A button should exist")
        initButton.tap()

        let reidentifyToggle = app.switches["project-switch-reidentify-toggle"]
        XCTAssertEqual(reidentifyToggle.value as? String, "1", "Re-identify from callback should default to on")

        app.buttons["project-switch-identify-button"].tap()
        if isRunningInCI {
            let registeredOnA = { (lines: [String]) in
                lines.contains { $0.contains("/api/users/registerDeviceToken key=\(self.mask(self.testConfig.apiKey)) [A]") }
            }
            XCTAssertTrue(registeredOnA(waitForLog(until: registeredOnA)), "The CI mock token should be registered on A before switching")
        }
        _ = waitForQuiet()
        app.buttons["project-switch-clear-log-button"].tap()
    }

    private func waitUntilSettled(on label: String) {
        XCTAssertTrue(waitForLabel("project-switch-pending-label", toBe: "0", timeout: longTimeout), "Every switch callback should fire")
        XCTAssertTrue(waitForLabel("project-switch-active-label", toBe: label), "SDK should settle on project \(label)")
    }

    private func assertIsAProjectSwitchResult(_ result: String) {
        XCTAssertTrue([".switchedCleanly", ".switchedWithWarnings"].contains(result), "Unexpected switch result: \(result)")
        print("ℹ️ Switch result: \(result)")
    }

    private func waitForTrackThenQuiet(afterCallbackTo label: String) -> [String] {
        _ = waitForLog { lines in
            self.netLines(afterCallbackTo: label, in: lines).contains { $0.contains("/api/events/track") }
        }
        let lines = waitForQuiet()
        print("📋 Project switch log:\n\(lines.joined(separator: "\n"))")
        XCTAssertTrue(netLines(afterCallbackTo: label, in: lines).contains { $0.contains("/api/events/track") },
                      "track should reach the network after the callback for \(label)")
        return lines
    }

    /// Every request after `label`'s callback carries `label`'s key. The one exception is the
    /// project being left's `disableDevice`: it reaches the request layer before the callback but
    /// may only hit the network after it.
    private func assertRequests(after label: String, in lines: [String], carry apiKey: String,
                                notLeavingProject otherLabel: String, key otherKey: String) {
        let requests = netLines(afterCallbackTo: label, in: lines)
        let outgoingDisable = { (line: String) in line.contains("/api/users/disableDevice") && line.hasSuffix("[\(otherLabel)]") }
        let stray = requests.filter { !$0.hasSuffix("[\(label)]") && !outgoingDisable($0) }
        XCTAssertTrue(stray.isEmpty, "Requests after the \(label) callback should carry \(label)'s key, found:\n\(stray.joined(separator: "\n"))")
        let leaked = requests.filter { $0.contains("key=\(mask(otherKey))") && !outgoingDisable($0) }
        XCTAssertTrue(leaked.isEmpty, "No request after the \(label) callback should carry \(otherLabel)'s key, found:\n\(leaked.joined(separator: "\n"))")
        XCTAssertTrue(requests.contains { $0.contains("key=\(mask(apiKey)) [\(label)]") }, "Expected requests with \(label)'s key \(mask(apiKey))")
    }

    /// The app inserts log lines in timestamp order, so position in the log is time order.
    private func netLines(afterCallbackTo label: String, in lines: [String]) -> [String] {
        guard let index = lines.lastIndex(where: { $0.contains("CALLBACK \(label) result=") }) else { return [] }
        return lines[(index + 1)...].filter { $0.contains(" NET ") }
    }

    private func logLines() -> [String] {
        (app.textViews["project-switch-log"].value as? String ?? "").components(separatedBy: "\n")
    }

    private func waitForLog(timeout: TimeInterval = 60.0, until condition: @escaping ([String]) -> Bool) -> [String] {
        let deadline = Date().addingTimeInterval(timeout)
        var lines = logLines()
        while !condition(lines) && Date() < deadline {
            sleep(1)
            lines = logLines()
        }
        return lines
    }

    /// Returns once the log has not changed for `quietPeriod`, or at `timeout`.
    private func waitForQuiet(quietPeriod: TimeInterval = 2.0, timeout: TimeInterval = 20.0) -> [String] {
        let deadline = Date().addingTimeInterval(timeout)
        var lines = logLines()
        var lastChange = Date()
        while Date() < deadline && Date().timeIntervalSince(lastChange) < quietPeriod {
            usleep(500_000)
            let current = logLines()
            if current != lines {
                lines = current
                lastChange = Date()
            }
        }
        return lines
    }

    private func waitForLabel(_ identifier: String, toBe expected: String, timeout: TimeInterval = 30.0) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.staticTexts[identifier])
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func mask(_ key: String) -> String {
        "\(key.prefix(4))...\(key.suffix(4))"
    }
}
