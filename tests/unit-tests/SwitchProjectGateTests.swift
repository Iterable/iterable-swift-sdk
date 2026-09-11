//
//  Copyright © 2026 Iterable. All rights reserved.
//

import UserNotifications
import XCTest

@testable import IterableSDK

extension ProjectSwitchGate {
    /// Raises the gate without running a teardown, for the tests that only exercise what the
    /// gate holds and releases. `apiKey` matters only where a test drives two destinations.
    ///
    /// `liveApiKey` defaults to a key no test uses as a destination, so the routing decision
    /// turns on the chain alone. The tests that care about the live project pass it.
    @discardableResult
    func beginSwitchForTesting(apiKey: String = "gate-test-key",
                               liveApiKey: String = "gate-test-live-key",
                               callback: ((Bool) -> Void)? = nil) -> BeginSwitchOutcome {
        beginSwitch(PendingSwitchRequest(apiKey: apiKey,
                                         config: IterableConfig(),
                                         apiEndPointOverride: nil,
                                         dependencyContainer: nil,
                                         callbacks: callback.map { [$0] } ?? []),
                    liveApiKey: liveApiKey)
    }
}

/// What `ProjectSwitchGate` is allowed to hold, and what it must never hold.
///
/// A call belongs in the gate when replaying it against the new project is what the app
/// wanted: identity and generic tracking. A call must stay out of the gate when it carries the
/// outgoing project's campaign, template or message IDs, or when deferring it is itself
/// harmful. `SwitchProjectTests` covers the switch sequence; this file covers the boundary.
class SwitchProjectGateTests: XCTestCase {
    private let apiKeyA = "project-a-key"
    private let apiKeyB = "project-b-key"
    private let apiKeyC = "project-c-key"
    private let apiKeyD = "project-d-key"
    private let emailA = "user-a@example.com"
    private let emailB = "user-b@example.com"

    /// Shared across the switch, the way UserDefaults and the keychain are in a real app.
    private var localStorage: MockLocalStorage!

    override func setUp() {
        super.setUp()
        localStorage = MockLocalStorage()
        ProjectSwitchGate.shared.resetForTesting()
        IterableAPI.implementation = nil
    }

    override func tearDown() {
        ProjectSwitchGate.shared.resetForTesting()
        IterableAPI.implementation = nil
        super.tearDown()
    }

    // MARK: - Push must not be gated

    /// The defect this file exists for: a gated push is replayed at the end of the switch,
    /// by which point `IterableAppIntegration.implementation` has been rebuilt around the new
    /// project, so project A's campaign is reported to project B and project A's attribution
    /// is written into the storage project B reads.
    func testAPushTappedDuringTheSwitchWindowIsNotHandedToTheNewProject() {
        let networkSessionB = MockNetworkSession()
        initializeProjectA(email: emailA)

        let switched = expectation(description: #function)
        IterableAPI.switchProject(apiKey: apiKeyB,
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container(networkSession: networkSessionB)) { _ in switched.fulfill() }

        XCTAssertTrue(ProjectSwitchGate.shared.isSwitchInProgress,
                      "the push has to land inside the switch window for this test to mean anything")
        // Identity first, so that if the push open were queued it would replay behind an
        // identified project B and genuinely reach it, rather than being dropped by project
        // B's "not initialized" guard and hiding the leak.
        IterableAPI.setEmail(emailB)
        let payload = pushPayload(messageId: "project-a-message")
        let pushHandled = expectation(description: "the tapped push is handled")
        IterableAppIntegration.implementation?.userNotificationCenter(nil,
                                                                     didReceive: MockNotificationResponse(userInfo: payload,
                                                                                                          actionIdentifier: UNNotificationDefaultActionIdentifier),
                                                                     withCompletionHandler: { pushHandled.fulfill() })
        IterableAPI.track(pushOpen: payload, dataFields: nil)

        wait(for: [pushHandled], timeout: testExpectationTimeout)
        wait(for: [switched], timeout: testExpectationTimeout)

        XCTAssertNil(IterableAPI.attributionInfo,
                     "project A's campaign must not be readable as project B's attribution")
        XCTAssertNil(localStorage.getAttributionInfo(currentDate: Date()))
        XCTAssertFalse(networkSessionB.requests.contains { $0.url?.absoluteString.contains(Const.Path.trackPushOpen) == true },
                       "a pushOpen for a campaign that only exists in project A must not be posted to project B")
    }

    /// The silent-push handler answers the OS. Holding it for a switch defers a
    /// `UIBackgroundFetchResult` past a Core Data purge.
    func testTheSilentPushCompletionHandlerIsNotHeldForTheSwitch() {
        initializeProjectA(email: emailA)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(), .run)

        var fetchResult: UIBackgroundFetchResult?
        IterableAppIntegration.application(UIApplication.shared,
                                           didReceiveRemoteNotification: pushPayload(messageId: "project-a-message"),
                                           fetchCompletionHandler: { fetchResult = $0 })

        XCTAssertEqual(fetchResult, .noData, "the OS completion handler must not wait for the switch")
    }

    // MARK: - The rest of the boundary

    func testTheGateHoldsIdentityAndReleasesEverythingProjectScoped() {
        let networkSessionA = MockNetworkSession()
        initializeProjectA(config: configWithPush(), networkSession: networkSessionA, email: emailA)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(), .run)

        // Ungated: the payload names project A's campaign, so replaying it against project B
        // would report a campaign that does not exist there.
        let pushOpenSent = expectation(description: "the pushOpen goes out during the switch window")
        networkSessionA.requestCallback = { request in
            guard request.url?.absoluteString.contains(Const.Path.trackPushOpen) == true else { return }
            pushOpenSent.fulfill()
        }
        IterableAPI.track(pushOpen: NSNumber(value: 1234),
                          templateId: NSNumber(value: 4321),
                          messageId: "project-a-message",
                          appAlreadyRunning: false,
                          dataFields: nil)

        // Ungated: the app is asking to disable the device on the project it is on. Replayed,
        // it would disable the device on the project it just moved to.
        var disableReported = false
        IterableAPI.disableDeviceForCurrentUser(withOnSuccess: { _ in disableReported = true },
                                                onFailure: { _, _ in disableReported = true })
        XCTAssertTrue(disableReported, "the device disable must reach the outgoing project, not be deferred")

        // Ungated: visitor consent is project-agnostic and survives the switch, so deferring a
        // consent change would leave it unapplied for the length of the switch.
        localStorage.visitorUsageTracked = false
        IterableAPI.setVisitorUsageTracked(isVisitorUsageTracked: true)
        XCTAssertTrue(localStorage.visitorUsageTracked)
        XCTAssertNotNil(localStorage.visitorConsentTimestamp, "consent must be recorded when it is given")

        // Gated: identity is the one thing the app wants to land on the new project.
        IterableAPI.setEmail(emailB)
        XCTAssertEqual(IterableAPI.email, emailA, "identity must be held until the new project is up")

        wait(for: [pushOpenSent], timeout: testExpectationTimeout)
        ProjectSwitchGate.shared.endSwitch(succeeded: true)
        XCTAssertEqual(IterableAPI.email, emailB, "the held identity call must replay when the gate drops")
    }

    // MARK: - Request routing
    //
    // Which project the SDK ends on when requests overlap. Every case here turns on the same
    // rule: a request is resolved against the project the app most recently *asked* for, which
    // for the whole length of a teardown is not the project that is live.

    func testARequestForTheLiveProjectWithNothingInFlightIsANoOp() {
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyA, liveApiKey: apiKeyA),
                       .alreadyThere)
        XCTAssertFalse(ProjectSwitchGate.shared.isSwitchInProgress, "a no-op must not start a chain")
    }

    /// Rapid A to B to A. While B is tearing down the live instance is still A, so resolving
    /// against it calls the second request a no-op: it reports a clean switch to A, tears
    /// nothing down, and B lands anyway. The app is then told it is on A while every event goes
    /// to B, with nothing in the API to notice it with.
    func testARequestForTheProjectBeingLeftIsARealSwitchNotANoOp() {
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB, liveApiKey: apiKeyA), .run)

        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyA, liveApiKey: apiKeyA),
                       .joinedOrQueued,
                       "asking to go back to the project being left is a switch, not a no-op")
        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyA,
                       "the SDK must end on the project the app asked for last")
    }

    /// A repeat of the destination in flight can only join it while nothing is queued behind it.
    /// With C already queued the app's most recent ask is B again, so joining B's callbacks
    /// would fire them and then let C land, leaving the SDK on the project asked for second to
    /// last while both callbacks reported success.
    func testARepeatOfTheInFlightProjectCannotJoinItOnceSomethingIsQueuedBehindIt() {
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .run)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .joinedOrQueued,
                       "with nothing queued, a repeat joins the switch in flight")
        XCTAssertNil(ProjectSwitchGate.shared.endSwitch(succeeded: true),
                     "joining must not queue a second teardown of the same project")

        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .run)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyC), .joinedOrQueued)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .joinedOrQueued)

        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyC)
        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyB,
                       "the repeat has to run after the destination that was already queued")
        XCTAssertNil(ProjectSwitchGate.shared.endSwitch(succeeded: true), "the chain is empty now")
    }

    /// B in flight, then C, D, C. Merging the last C into the queued one leaves the chain as
    /// C then D, so the SDK settles on D, and reports the last request when the first C lands,
    /// two switches early.
    func testARepeatIsNotMergedAcrossAnotherDestination() {
        let lastRequestReported = expectation(description: "the last request for C reports when its own switch lands")
        lastRequestReported.assertForOverFulfill = true

        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .run)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyC), .joinedOrQueued)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyD), .joinedOrQueued)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyC,
                                                                     callback: { _ in lastRequestReported.fulfill() }),
                       .joinedOrQueued)

        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyC)
        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyD)
        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyC,
                       "the SDK must end on the project the app asked for last")
        XCTAssertNil(ProjectSwitchGate.shared.endSwitch(succeeded: true), "the chain is empty now")

        wait(for: [lastRequestReported], timeout: testExpectationTimeout)
    }

    /// An adjacent repeat still shares one teardown, which is the double-tapped picker.
    func testAnAdjacentRepeatOfAQueuedDestinationSharesItsSwitch() {
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .run)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyC), .joinedOrQueued)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyC), .joinedOrQueued)

        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyC)
        XCTAssertNil(ProjectSwitchGate.shared.endSwitch(succeeded: true),
                     "two taps on the same queued destination must not run two teardowns")
    }

    /// The call-queueing gate has to drop at the handover even though the chain stays up. At
    /// that moment the SDK is fully live on the project that just landed, and the contract tells
    /// apps to re-identify from the callback, so a `setEmail` made there has to reach that
    /// project. Holding the gate across the handover queues it and then replays it into the next
    /// switch, sending B's identity to C.
    func testCallsRunAgainstTheProjectThatJustLandedWhileTheNextSwitchIsStillQueued() {
        var ran = [String]()

        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyB), .run)
        XCTAssertEqual(ProjectSwitchGate.shared.beginSwitchForTesting(apiKey: apiKeyC), .joinedOrQueued)
        XCTAssertTrue(ProjectSwitchGate.shared.queueOrExecute("duringB") { ran.append("duringB") })

        XCTAssertEqual(ProjectSwitchGate.shared.endSwitch(succeeded: true)?.apiKey, apiKeyC)
        XCTAssertEqual(ran, ["duringB"], "the calls queued during B's teardown replay against B")
        XCTAssertTrue(ProjectSwitchGate.shared.isSwitchInProgress,
                      "the chain must stay up so C keeps its place ahead of anything arriving now")

        XCTAssertFalse(ProjectSwitchGate.shared.queueOrExecute("fromBsCallback") { ran.append("fromBsCallback") },
                       "a call made from B's callback must run against B, not be queued into C")
        XCTAssertEqual(ran, ["duringB", "fromBsCallback"])

        // What C's switchProject does when it picks up the chain it inherited.
        ProjectSwitchGate.shared.resumeSwitch()
        XCTAssertTrue(ProjectSwitchGate.shared.queueOrExecute("duringC") { ran.append("duringC") },
                      "C's own teardown queues again")
        XCTAssertEqual(ran, ["duringB", "fromBsCallback"])

        XCTAssertNil(ProjectSwitchGate.shared.endSwitch(succeeded: true))
        XCTAssertEqual(ran, ["duringB", "fromBsCallback", "duringC"])
        XCTAssertFalse(ProjectSwitchGate.shared.isSwitchInProgress, "the chain is done")
    }

    // MARK: - Attribution owned by a project that has been left

    /// A universal link redirect resolves over the network and can land after the teardown has
    /// cleared attribution but while the outgoing instance is still installed. Its campaign
    /// belongs to the project that is gone.
    func testAttributionResolvedAfterTheTeardownIsNotWrittenBack() {
        let projectA = initializeProjectA(email: emailA)

        let torndown = expectation(description: "teardown for project switch")
        projectA.tearDownForProjectSwitch { _ in torndown.fulfill() }
        wait(for: [torndown], timeout: testExpectationTimeout)

        projectA.attributionInfo = IterableAttributionInfo(campaignId: 1234, templateId: 4321, messageId: "project-a-message")

        XCTAssertNil(projectA.attributionInfo)
        XCTAssertNil(localStorage.getAttributionInfo(currentDate: Date()),
                     "the storage the new project reads must not carry project A's campaign")
    }

    // MARK: - API key validation

    func testAnEmptyOrBlankApiKeyIsRejectedAndNothingIsTornDown() {
        let projectA = initializeProjectA(email: emailA)

        for apiKey in ["", "   "] {
            XCTAssertFalse(awaitSwitch(to: apiKey), "a rejected switch cannot report a clean teardown")

            XCTAssertTrue(IterableAPI.implementation === projectA, "nothing may be torn down for an unusable API key")
            XCTAssertEqual(localStorage.email, emailA)
            XCTAssertFalse(ProjectSwitchGate.shared.isSwitchInProgress, "the gate must not be left raised")
        }
    }

    // MARK: - Re-initialization

    /// Parity with Android, which reports an unclean teardown when its own re-initialization
    /// does not complete. Project A has push on and a registered token, the one shape that
    /// reports a clean teardown, so the `false` here can only come from the new project.
    func testASwitchWhoseNewProjectFailsToStartReportsFalse() {
        initializeProjectA(config: configWithPush(), email: emailA, pushToken: "project-a-token")

        XCTAssertFalse(awaitSwitch(to: apiKeyB, inAppFetcher: FailingInAppFetcher()))

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB, "the switch still lands on the new project")
        XCTAssertFalse(ProjectSwitchGate.shared.isSwitchInProgress, "the gate must not be left raised")
    }

    // MARK: - The device disable hand-off bound

    func testTheDeviceDisableHandoffReportsFalseOnceItsBoundHasPassed() {
        let handoff = DeviceDisableHandoff()
        // What matters is what happens once the bound has passed, not how long it is, so the
        // bound is expired immediately rather than spent for real on every run.
        handoff.timeout = 0

        let timedOut = expectation(description: #function)
        var reported: Bool?
        handoff.await { handedOff in
            reported = handedOff
            timedOut.fulfill()
        }

        wait(for: [timedOut], timeout: testExpectationTimeout)
        XCTAssertEqual(reported, false, "a disable that never reaches the request layer is a noisy teardown")
    }

    /// The bound decides when a switch reports `false`, which is part of the contract shared
    /// with Android's `DISABLE_DISPATCH_TIMEOUT_MS`. Drift here is cross-platform drift.
    func testTheDeviceDisableHandoffBoundMatchesAndroid() {
        XCTAssertEqual(DeviceDisableHandoff.defaultTimeout, 2)
    }

    /// `IterableTaskScheduler.schedule` broadcasts a rejection and then a resolution on the
    /// same `Fulfill`, so a failed schedule reports twice and the failure has to win.
    func testTheDeviceDisableHandoffKeepsTheFirstSignal() {
        let handoff = DeviceDisableHandoff()
        handoff.signal(false)
        handoff.signal(true)

        let delivered = expectation(description: #function)
        var reported: Bool?
        handoff.await { handedOff in
            reported = handedOff
            delivered.fulfill()
        }

        wait(for: [delivered], timeout: testExpectationTimeout)
        XCTAssertEqual(reported, false)
    }

    // MARK: - Helpers

    private func pushPayload(messageId: String) -> [AnyHashable: Any] {
        [
            "itbl": [
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
            ] as [String: Any],
        ]
    }

    private func configWithoutPush() -> IterableConfig {
        let config = IterableConfig()
        config.autoPushRegistration = false
        return config
    }

    private func configWithPush() -> IterableConfig {
        let config = IterableConfig()
        config.autoPushRegistration = true
        return config
    }

    private func container(networkSession: NetworkSessionProtocol = MockNetworkSession(),
                           inAppFetcher: InAppFetcherProtocol = MockInAppFetcher()) -> MockDependencyContainer {
        MockDependencyContainer(dateProvider: MockDateProvider(),
                                networkSession: networkSession,
                                notificationStateProvider: MockNotificationStateProvider(enabled: true),
                                localStorage: localStorage,
                                inAppFetcher: inAppFetcher,
                                inAppDisplayer: MockInAppDisplayer(),
                                inAppPersister: MockInAppPersister(),
                                urlOpener: MockUrlOpener(),
                                applicationStateProvider: MockApplicationStateProvider(applicationState: .active),
                                notificationCenter: NotificationCenter.default,
                                maxTasks: 1000,
                                apnsTypeChecker: MockAPNSTypeChecker(apnsType: .sandbox),
                                persistenceContextProvider: nil)
    }

    @discardableResult
    private func initializeProjectA(config: IterableConfig? = nil,
                                    networkSession: NetworkSessionProtocol = MockNetworkSession(),
                                    email: String? = nil,
                                    pushToken: String? = nil) -> InternalIterableAPI {
        let projectA = InternalIterableAPI(apiKey: apiKeyA,
                                           launchOptions: nil,
                                           config: config ?? configWithoutPush(),
                                           apiEndPointOverride: nil,
                                           dependencyContainer: container(networkSession: networkSession))
        IterableAPI.implementation = projectA
        projectA.start().wait()
        if let email = email {
            projectA.email = email
        }
        if let pushToken = pushToken {
            projectA.register(token: pushToken)
        }
        return projectA
    }

    /// - Returns: the `cleanTeardown` value the switch reported.
    @discardableResult
    private func awaitSwitch(to apiKey: String,
                             inAppFetcher: InAppFetcherProtocol = MockInAppFetcher(),
                             file: StaticString = #filePath,
                             line: UInt = #line) -> Bool {
        let switched = expectation(description: "switch to \"\(apiKey)\"")
        var reported: Bool?
        IterableAPI.switchProject(apiKey: apiKey,
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container(inAppFetcher: inAppFetcher)) { cleanTeardown in
            reported = cleanTeardown
            switched.fulfill()
        }
        wait(for: [switched], timeout: testExpectationTimeout)
        guard let reported = reported else {
            XCTFail("switchProject never reported a result", file: file, line: line)
            return false
        }
        return reported
    }
}

/// Stands in for the new project's first in-app sync failing, which is the only way iOS's
/// re-initialization can report failure: `initialize2` itself cannot throw.
private struct FailingInAppFetcher: InAppFetcherProtocol {
    func fetch() -> Pending<[IterableInAppMessage], Error> {
        FailPending(error: IterableError.general(description: "in-app sync failed"))
    }
}
