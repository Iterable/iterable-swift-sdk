//
//  Copyright © 2026 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

/// Covers `IterableAPI.switchProject` with offline mode off, which is the default.
/// The persisted-queue half of the switch lives in `SwitchProjectOfflineTests`.
class SwitchProjectTests: XCTestCase {
    private let apiKeyA = "project-a-key"
    private let apiKeyB = "project-b-key"
    private let emailA = "user-a@example.com"
    private let emailB = "user-b@example.com"

    /// Shared across the switch on purpose: UserDefaults, the keychain and the on-disk
    /// in-app cache all survive the instance swap in a real app, so project A's state has to
    /// be cleared rather than left behind for the new instance to pick up.
    private var localStorage: MockLocalStorage!
    private var inAppPersister: MockInAppPersister!

    override func setUp() {
        super.setUp()
        localStorage = MockLocalStorage()
        inAppPersister = MockInAppPersister()
        ProjectSwitchGate.shared.resetForTesting()
        IterableAPI.implementation = nil
    }

    override func tearDown() {
        ProjectSwitchGate.shared.resetForTesting()
        IterableAPI.implementation = nil
        super.tearDown()
    }

    // MARK: - Public surface

    func testSwitchBeforeInitializeBehavesAsInitialize() {
        XCTAssertNil(IterableAPI.implementation)

        XCTAssertTrue(awaitSwitch(to: apiKeyB))

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB)
    }

    func testSwitchWithUnchangedApiKeyIsANoOpAndDoesNotReplaceTheInstance() {
        let projectA = initializeProjectA(email: emailA)

        XCTAssertTrue(awaitSwitch(to: apiKeyA))

        XCTAssertTrue(IterableAPI.implementation === projectA, "nothing may be torn down for the key already in use")
        XCTAssertEqual(localStorage.email, emailA)
    }

    func testTheCallbackIsDeliveredOnTheMainThread() {
        initializeProjectA(email: emailA)

        let switched = expectation(description: #function)
        var onMainThread = false
        IterableAPI.switchProject(apiKey: apiKeyB,
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container()) { _ in
            onMainThread = Thread.isMainThread
            switched.fulfill()
        }

        wait(for: [switched], timeout: testExpectationTimeout)
        XCTAssertTrue(onMainThread)
    }

    func testThePublicMethodReturnsImmediately() {
        initializeProjectA(email: emailA)

        let switched = expectation(description: #function)
        let startedAt = Date()
        IterableAPI.switchProject(apiKey: apiKeyB,
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container()) { _ in switched.fulfill() }
        let elapsed = Date().timeIntervalSince(startedAt)

        XCTAssertLessThan(elapsed, 0.05, "switchProject must not block the caller, it took \(elapsed)s")
        wait(for: [switched], timeout: testExpectationTimeout)
    }

    // MARK: - Teardown

    func testSwitchClearsStoredIdentityAndLaterRequestsCarryOnlyTheNewProject() {
        initializeProjectA(email: emailA)
        localStorage.authToken = "project-a-jwt"
        localStorage.userIdUnknownUser = "project-a-unknown-user"

        let networkSessionB = MockNetworkSession()
        let tracked = expectation(description: "an event tracked after the switch")
        networkSessionB.requestCallback = { request in
            guard request.url?.absoluteString.contains(Const.Path.trackEvent) == true else { return }
            TestUtils.validateHeader(request, self.apiKeyB)
            XCTAssertNil(request.allHTTPHeaderFields?[JsonKey.Header.authorization],
                         "project A's auth token must not be attached to a project B request")
            let body = TestUtils.getRequestBody(request: request) ?? [:]
            XCTAssertEqual(body[JsonKey.email] as? String, self.emailB)
            tracked.fulfill()
        }

        awaitSwitch(to: apiKeyB, dependencyContainer: container(networkSession: networkSessionB))

        XCTAssertNil(localStorage.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertNil(localStorage.authToken)
        XCTAssertNil(localStorage.userIdUnknownUser)
        XCTAssertNil(IterableAPI.email)

        IterableAPI.setEmail(emailB)
        IterableAPI.track(event: "afterSwitch")
        wait(for: [tracked], timeout: testExpectationTimeout)
    }

    func testTeardownCompletesAndReportsSuccessWithOfflineModeDisabled() {
        XCTAssertFalse(localStorage.offlineMode, "this test covers the branch with no persisted queue to purge")
        // A clean teardown needs a device disable to confirm, so project A has push on and a
        // registered token. This is the only shape that reports true.
        initializeProjectA(config: configWithPush(), email: emailA, pushToken: "project-a-token")

        XCTAssertTrue(awaitSwitch(to: apiKeyB))

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB)
        XCTAssertNil(localStorage.email, "the purge completion must still run so identity is cleared")
    }

    /// Push is on but nothing ever registered a token, so the disable fails on the synchronous
    /// `no token present` guard. A disable that fails on the wire is covered by
    /// `SwitchProjectGateTests`.
    func testASwitchWithNoTokenToDisableReportsFalseAndStillCompletes() {
        initializeProjectA(config: configWithPush(), email: emailA)

        XCTAssertFalse(awaitSwitch(to: apiKeyB), "a noisy teardown step must report false")

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB, "the swap must still complete")
        XCTAssertNil(localStorage.email, "local cleanup must still complete")
    }

    /// Parity with Android, which reports a noisy teardown whenever no device disable was
    /// confirmed for the outgoing project. For an app that does not use push this is the
    /// normal outcome, not an error.
    func testSwitchWithoutPushRegistrationReportsFalseAndStillCompletes() {
        initializeProjectA(config: configWithoutPush(), email: emailA)

        XCTAssertFalse(awaitSwitch(to: apiKeyB), "no device disable could be confirmed, so the teardown is noisy")

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB, "the swap must still complete")
        XCTAssertNil(localStorage.email)
    }

    func testSwitchWithNoIdentifiedUserReportsFalseAndStillCompletes() {
        initializeProjectA(config: configWithPush(), email: nil, pushToken: nil)

        XCTAssertFalse(awaitSwitch(to: apiKeyB), "with no user there is nothing to disable, so the teardown is noisy")

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB)
    }

    func testSwitchClearsTheOutgoingProjectsAttributionInfo() {
        let projectA = initializeProjectA(email: emailA)
        projectA.attributionInfo = IterableAttributionInfo(campaignId: 1234, templateId: 4321, messageId: "project-a-message")
        XCTAssertEqual(IterableAPI.attributionInfo?.campaignId, 1234)

        let networkSessionB = MockNetworkSession()
        let tracked = expectation(description: "an event tracked after the switch")
        networkSessionB.requestCallback = { request in
            guard request.url?.absoluteString.contains(Const.Path.trackEvent) == true else { return }
            let body = TestUtils.getRequestBody(request: request) ?? [:]
            let dataFields = body[JsonKey.dataFields] as? [AnyHashable: Any] ?? [:]
            XCTAssertNil(dataFields[JsonKey.campaignId],
                         "project A's campaignId does not exist in project B and must not be attached")
            tracked.fulfill()
        }

        awaitSwitch(to: apiKeyB, dependencyContainer: container(networkSession: networkSessionB))

        XCTAssertNil(IterableAPI.attributionInfo, "project A's attribution must not be readable on project B")

        IterableAPI.setEmail(emailB)
        // The pattern the sample app documents: read the stored attribution and attach it to
        // the event. With the attribution cleared there is nothing to attach.
        var dataFields = [AnyHashable: Any]()
        if let attributionInfo = IterableAPI.attributionInfo {
            dataFields[JsonKey.campaignId] = attributionInfo.campaignId
            dataFields[JsonKey.templateId] = attributionInfo.templateId
        }
        IterableAPI.track(event: "afterSwitch", dataFields: dataFields)
        wait(for: [tracked], timeout: testExpectationTimeout)
    }

    // MARK: - Instance and manager rebuild

    func testPreviousInstanceIsReplacedAndDeallocated() {
        weak var previous = initializeProjectA(email: emailA)
        XCTAssertNotNil(previous)

        awaitSwitch(to: apiKeyB)

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB)
        // The outgoing instance's deinit is what removes its observers and stops its request
        // handler, so it has to actually be released.
        let released = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in previous == nil }, object: nil)
        wait(for: [released], timeout: testExpectationTimeout)
    }

    func testNewInstanceUsesTheSuppliedConfig() {
        initializeProjectA(email: emailA)

        let authDelegate = TokenRequestRecorder()
        let tokenRequested = expectation(description: "the new project's authHandler is asked for a token")
        authDelegate.onTokenRequested = { tokenRequested.fulfill() }
        let configB = configWithoutPush()
        configB.authDelegate = authDelegate
        configB.dataRegion = IterableDataRegion.EU

        awaitSwitch(to: apiKeyB, config: configB)

        XCTAssertEqual(IterableAPI.implementation?.apiEndPointForTest, IterableDataRegion.EU)
        IterableAPI.setEmail(emailB)
        wait(for: [tokenRequested], timeout: testExpectationTimeout)
    }

    func testManagersAreRebuiltAndCarryNoPreviousProjectContent() {
        let fetcherA = MockInAppFetcher()
        let configA = configWithoutPush()
        // Keep the message in the queue rather than letting it display and get consumed.
        configA.inAppDelegate = MockInAppDelegate(showInApp: .skip)
        let projectA = initializeProjectA(config: configA,
                                          dependencyContainer: container(inAppFetcher: fetcherA),
                                          email: emailA)
        fetcherA.mockMessagesAvailableFromServer(internalApi: projectA,
                                                 messages: [InAppTestHelper.emptyInAppMessage(messageId: "project-a-message")]).wait()
        XCTAssertEqual(projectA.inAppManager.getMessages().map(\.messageId), ["project-a-message"])
        let inAppManagerA = projectA.inAppManager as AnyObject
        let embeddedManagerA = projectA.embeddedManager as AnyObject

        awaitSwitch(to: apiKeyB)

        XCTAssertFalse(inAppManagerA === (IterableAPI.implementation?.inAppManager as AnyObject))
        XCTAssertFalse(embeddedManagerA === (IterableAPI.implementation?.embeddedManager as AnyObject))
        XCTAssertTrue(IterableAPI.inAppManager.getMessages().isEmpty, "project A's in-apps must not show up on project B")
        XCTAssertTrue(IterableAPI.embeddedManager.getMessages().isEmpty)
        XCTAssertTrue(inAppPersister.getMessages().isEmpty, "project A's persisted in-apps must be purged")
    }

    // MARK: - Switch window

    func testTheGateQueuesCallsFIFOAndDrainsThemWhenTheSwitchEnds() {
        var order = [String]()

        XCTAssertTrue(ProjectSwitchGate.shared.beginSwitch(callback: nil))
        XCTAssertTrue(ProjectSwitchGate.shared.queueOrExecute("first") { order.append("first") })
        XCTAssertTrue(ProjectSwitchGate.shared.queueOrExecute("second") { order.append("second") })
        XCTAssertEqual(order, [], "nothing may run while the gate is raised")

        ProjectSwitchGate.shared.endSwitch(succeeded: true)

        XCTAssertEqual(order, ["first", "second"], "queued calls must replay in FIFO order")
        XCTAssertFalse(ProjectSwitchGate.shared.queueOrExecute("third") { order.append("third") })
        XCTAssertEqual(order, ["first", "second", "third"], "with the gate down, calls run immediately")
    }

    func testACallMadeDuringTheSwitchWindowRunsAgainstTheNewInstance() {
        initializeProjectA(email: emailA)

        let switched = expectation(description: #function)
        var emailAtCallback: String?
        var apiKeyAtCallback: String?
        IterableAPI.switchProject(apiKey: apiKeyB,
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container()) { _ in
            emailAtCallback = IterableAPI.email
            apiKeyAtCallback = IterableAPI.implementation?.apiKey
            switched.fulfill()
        }
        // The gate goes up synchronously inside switchProject, so this is queued.
        IterableAPI.setEmail(emailB)

        wait(for: [switched], timeout: testExpectationTimeout)
        XCTAssertEqual(apiKeyAtCallback, apiKeyB)
        // The new instance starts with no identity, so seeing emailB proves the queued call
        // was drained against the new instance rather than lost with the old one.
        XCTAssertEqual(emailAtCallback, emailB)
    }

    // MARK: - Nested and repeated switches

    func testRapidSwitchesRunOneTeardownAndFireEveryCallback() {
        initializeProjectA(email: emailA)

        let firstCallback = expectation(description: "first callback")
        let secondCallback = expectation(description: "second callback")
        IterableAPI.switchProject(apiKey: apiKeyB,
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container()) { _ in firstCallback.fulfill() }
        IterableAPI.switchProject(apiKey: "project-c-key",
                                  config: configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container()) { _ in secondCallback.fulfill() }

        wait(for: [firstCallback, secondCallback], timeout: testExpectationTimeout)
        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB,
                       "the second call only registers its callback, its API key is ignored")
        XCTAssertFalse(ProjectSwitchGate.shared.isSwitchInProgress)
    }

    func testSwitchingAToBToALeavesNoResidueFromProjectB() {
        initializeProjectA(email: emailA)

        awaitSwitch(to: apiKeyB)
        IterableAPI.setEmail(emailB)
        XCTAssertEqual(localStorage.email, emailB)
        let inAppManagerB = IterableAPI.implementation?.inAppManager as AnyObject

        awaitSwitch(to: apiKeyA)

        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyA)
        XCTAssertNil(localStorage.email, "project B's identity must not survive")
        XCTAssertNil(localStorage.authToken)
        XCTAssertFalse(inAppManagerB === (IterableAPI.implementation?.inAppManager as AnyObject))
        XCTAssertTrue(IterableAPI.inAppManager.getMessages().isEmpty)
    }

    // MARK: - Helpers

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
                                inAppPersister: inAppPersister,
                                urlOpener: MockUrlOpener(),
                                applicationStateProvider: MockApplicationStateProvider(applicationState: .active),
                                notificationCenter: NotificationCenter.default,
                                maxTasks: 1000,
                                apnsTypeChecker: MockAPNSTypeChecker(apnsType: .sandbox),
                                persistenceContextProvider: nil)
    }

    @discardableResult
    private func initializeProjectA(config: IterableConfig? = nil,
                                    dependencyContainer: DependencyContainerProtocol? = nil,
                                    email: String? = nil,
                                    pushToken: String? = nil) -> InternalIterableAPI {
        let projectA = InternalIterableAPI(apiKey: apiKeyA,
                                           launchOptions: nil,
                                           config: config ?? configWithoutPush(),
                                           apiEndPointOverride: nil,
                                           dependencyContainer: dependencyContainer ?? container())
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
                             config: IterableConfig? = nil,
                             dependencyContainer: DependencyContainerProtocol? = nil,
                             file: StaticString = #filePath,
                             line: UInt = #line) -> Bool {
        let switched = expectation(description: "switch to \(apiKey)")
        var reported: Bool?
        IterableAPI.switchProject(apiKey: apiKey,
                                  config: config ?? configWithoutPush(),
                                  apiEndPointOverride: nil,
                                  dependencyContainer: dependencyContainer ?? container()) { cleanTeardown in
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

private class TokenRequestRecorder: NSObject, IterableAuthDelegate {
    var onTokenRequested: (() -> Void)?

    func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
        onTokenRequested?()
        completion(nil)
    }

    func onAuthFailure(_: AuthFailure) {}
}
