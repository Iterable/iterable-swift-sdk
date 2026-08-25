//
//  Copyright © 2026 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

/// The persisted-queue half of `IterableAPI.switchProject`: the purge has to genuinely
/// complete before the instance is swapped, a queued device disable has to survive and still
/// reach the project it was created for, and everything else has to be gone.
class SwitchProjectOfflineTests: XCTestCase {
    private let apiKeyA = "project-a-key"
    private let apiKeyB = "project-b-key"
    private let emailA = "user-a@example.com"
    private let endpointA = IterableDataRegion.EU
    private let endpointB = IterableDataRegion.US

    /// One store shared by both projects, standing in for `PersistentContainer.shared`,
    /// which survives the instance swap.
    private var persistenceContext: MockPersistenceContext!
    private var persistenceContextInput: MockPersistenceContext.Input!
    private var persistenceContextProvider: MockPersistenceContextProvider!
    private var localStorage: MockLocalStorage!

    override func setUp() {
        super.setUp()
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                        logDelegate: DefaultLogDelegate())
        persistenceContextInput = MockPersistenceContext.Input()
        persistenceContext = MockPersistenceContext(input: persistenceContextInput)
        persistenceContextProvider = MockPersistenceContextProvider(context: persistenceContext)
        localStorage = MockLocalStorage()
        localStorage.offlineMode = true
        ProjectSwitchGate.shared.resetForTesting()
        IterableAPI.implementation = nil
    }

    override func tearDown() {
        persistenceContextInput.saveCallback = nil
        persistenceContextInput.countTasksCallback = nil
        ProjectSwitchGate.shared.resetForTesting()
        IterableAPI.implementation = nil
        super.tearDown()
    }

    func testTheFullSwitchLandsOnTheNewProjectWithOfflineModeOn() {
        XCTAssertTrue(localStorage.offlineMode, "this test covers the branch that has a queue to purge")
        _ = makeProjectA()

        let configB = IterableConfig()
        configB.autoPushRegistration = false
        configB.dataRegion = endpointB
        let switched = expectation(description: #function)
        var reported: Bool?
        IterableAPI.switchProject(apiKey: apiKeyB,
                                  config: configB,
                                  apiEndPointOverride: nil,
                                  dependencyContainer: container(networkSession: MockNetworkSession())) { cleanTeardown in
            reported = cleanTeardown
            switched.fulfill()
        }

        wait(for: [switched], timeout: testExpectationTimeout)
        // Project A has push registration off, so no device disable could be confirmed for
        // it and the teardown is reported as noisy. The switch itself still lands.
        XCTAssertEqual(reported, false)
        XCTAssertEqual(IterableAPI.implementation?.apiKey, apiKeyB)
        XCTAssertEqual(IterableAPI.implementation?.apiEndPointForTest, endpointB)
        XCTAssertNil(localStorage.email, "project A's identity must not survive into project B")
    }

    func testTeardownReportsCompletionOnlyAfterTheOfflineQueuePurgeHasLanded() throws {
        let projectA = makeProjectA()
        _ = try persistenceContext.create(task: task(named: Const.Path.trackEvent))
        _ = try persistenceContext.create(task: task(named: Const.Path.disableDevice))

        let torndown = expectation(description: #function)
        var namesLeftWhenTeardownReported: [String?]?
        var reported: Bool?
        projectA.tearDownForProjectSwitch { cleanTeardown in
            // Read the store from inside the completion. If the purge were still in flight
            // this would still see the trackEvent task, and `switchProject` would be swapping
            // the instance out from under an unfinished teardown.
            namesLeftWhenTeardownReported = (try? self.persistenceContext.findAllTasks())?.map { $0.name }
            reported = cleanTeardown
            torndown.fulfill()
        }

        wait(for: [torndown], timeout: testExpectationTimeout)
        // False because project A has push registration off, not because the purge failed.
        XCTAssertEqual(reported, false)
        XCTAssertEqual(namesLeftWhenTeardownReported, [Const.Path.disableDevice],
                       "the purge must have finished, keeping only the device disable, before teardown reports")
    }

    func testTheQueuedDeviceDisableSurvivesTheSwitchAndStillTargetsTheOutgoingProject() throws {
        let projectA = makeProjectA()
        XCTAssertEqual(queuePreSwitchTasks(on: projectA).sorted(),
                       [Const.Path.disableDevice, Const.Path.registerDeviceToken].sorted())

        awaitTeardown(of: projectA)

        let surviving = try persistenceContext.findAllTasks()
        XCTAssertEqual(surviving.compactMap { $0.name }, [Const.Path.disableDevice])
        // The API key and endpoint are baked into the persisted request at schedule time, so
        // the disable still goes to project A whatever project the SDK is on when it replays.
        let apiCallRequest = try JSONDecoder().decode(IterableAPICallRequest.self,
                                                     from: try XCTUnwrap(surviving.first?.data))
        XCTAssertEqual(apiCallRequest.apiKey, apiKeyA)
        XCTAssertEqual(apiCallRequest.endpoint, endpointA)
        XCTAssertNotEqual(endpointA, endpointB, "the two projects must be in different regions for this to mean anything")

        let urlRequest = try XCTUnwrap(apiCallRequest.convertToURLRequest(sentAt: Date(), processorType: .offline))
        XCTAssertTrue((urlRequest.url?.absoluteString ?? "").hasPrefix(endpointA))
        TestUtils.validateHeader(urlRequest, apiKeyA, processorType: .offline)
    }

    func testATaskQueuedForTheOutgoingProjectIsPurgedAndCannotReachTheNewProject() throws {
        let projectA = makeProjectA()
        XCTAssertTrue(queuePreSwitchTasks(on: projectA).contains(Const.Path.registerDeviceToken))

        awaitTeardown(of: projectA)

        // The store is shared with the new project, so a purged task being gone from it is
        // what stops it from ever being replayed against project B.
        let namesLeft = try persistenceContext.findAllTasks().compactMap { $0.name }
        XCTAssertFalse(namesLeft.contains(Const.Path.registerDeviceToken),
                       "the token registration queued for project A must have been purged")
        XCTAssertEqual(namesLeft, [Const.Path.disableDevice])
    }

    /// With offline mode on, the disable is built behind `HealthMonitor.canSchedule()` and
    /// `OfflineRequestProcessor` holds its auth provider weakly, so a teardown that reports
    /// before the request is persisted lets the switch release the outgoing instance and drop
    /// the disable — silently, and while still reporting a clean teardown.
    func testTheTeardownWaitsForTheOutgoingDeviceDisableToReachTheQueue() throws {
        let config = IterableConfig()
        // Off through setup so the token registration below is the only task in the queue,
        // then on so the teardown's logout actually disables the outgoing device. `config` is
        // held by reference, so the instance sees the flip.
        config.autoPushRegistration = false
        config.dataRegion = endpointA
        let projectA = InternalIterableAPI(apiKey: apiKeyA,
                                           launchOptions: nil,
                                           config: config,
                                           apiEndPointOverride: nil,
                                           dependencyContainer: container(networkSession: MockNetworkSession()))
        IterableAPI.implementation = projectA
        projectA.email = emailA
        projectA.requestHandler.stop()

        let registered = expectation(description: "the outgoing project's token is registered")
        persistenceContextInput.saveCallback = { registered.fulfill() }
        projectA.register(token: "project-a-token")
        wait(for: [registered], timeout: testExpectationTimeout)
        persistenceContextInput.saveCallback = nil

        config.autoPushRegistration = true
        // The disable is built behind `HealthMonitor.canSchedule()`, a Core Data count. On a
        // device with a populated store that count is slow enough for the queue purge to
        // overtake it, which is the ordering this test is about; the mock store answers
        // instantly, so the delay stands in for it.
        persistenceContextInput.countTasksCallback = { Thread.sleep(forTimeInterval: 0.3) }

        let torndown = expectation(description: #function)
        var namesWhenTeardownReported: [String?]?
        var reported: Bool?
        projectA.tearDownForProjectSwitch { cleanTeardown in
            namesWhenTeardownReported = (try? self.persistenceContext.findAllTasks())?.map { $0.name }
            reported = cleanTeardown
            torndown.fulfill()
        }

        wait(for: [torndown], timeout: testExpectationTimeout)
        persistenceContextInput.countTasksCallback = nil
        XCTAssertEqual(namesWhenTeardownReported, [Const.Path.disableDevice],
                       "the disable has to be on disk, and the registration purged, before teardown reports")
        XCTAssertEqual(reported, true, "a confirmed disable and a clean purge is a clean teardown")
    }

    func testHandleLogoutCompletionFiresWhenOfflineModeIsDisabled() throws {
        _ = try persistenceContext.create(task: task(named: Const.Path.trackEvent))
        let requestHandler = RequestHandler(onlineProcessor: makeOnlineProcessor(networkSession: MockNetworkSession()),
                                            offlineProcessor: nil,
                                            healthMonitor: nil,
                                            authProvider: nil,
                                            offlineMode: false)

        let purged = expectation(description: #function)
        try requestHandler.handleLogout { purged.fulfill() }

        wait(for: [purged], timeout: testExpectationTimeout)
        XCTAssertEqual(try persistenceContext.findAllTasks().count, 1,
                       "with offline mode off there is no SDK-owned queue to purge")
    }

    // MARK: - Helpers

    private func makeProjectA() -> InternalIterableAPI {
        let config = IterableConfig()
        // Keep logout's own device disable out of the way; the queued disable under test is
        // scheduled explicitly below.
        config.autoPushRegistration = false
        config.dataRegion = endpointA
        // `start()` is deliberately not called, so project A's task runner never runs and the
        // queue state under test stays deterministic.
        let projectA = InternalIterableAPI(apiKey: apiKeyA,
                                           launchOptions: nil,
                                           config: config,
                                           apiEndPointOverride: nil,
                                           dependencyContainer: container(networkSession: MockNetworkSession()))
        IterableAPI.implementation = projectA
        projectA.email = emailA
        // A task runner starts unpaused, so it would react to the scheduled-task notification
        // and drain the queue these tests are asserting on. Pausing it keeps the queue state
        // under the switch's control alone.
        projectA.requestHandler.stop()
        return projectA
    }

    /// Queues one task that the switch must purge and one that it must preserve. Both go
    /// through the real offline request processor, so each carries project A's API key and
    /// endpoint the way a real queued request does.
    ///
    /// - Returns: the names of the tasks sitting in the queue once both are persisted.
    private func queuePreSwitchTasks(on projectA: InternalIterableAPI) -> [String] {
        let queued = expectation(description: "two tasks queued for project A")
        queued.expectedFulfillmentCount = 2
        persistenceContextInput.saveCallback = { queued.fulfill() }

        projectA.register(token: "project-a-token")
        projectA.disableDeviceForCurrentUser()

        wait(for: [queued], timeout: testExpectationTimeout)
        persistenceContextInput.saveCallback = nil
        return (try? persistenceContext.findAllTasks())?.compactMap { $0.name } ?? []
    }

    /// Runs steps 3 to 6 of the switch, the part that owns the purge. The instance is not
    /// swapped, so the new project's task runner cannot race the queue assertions.
    private func awaitTeardown(of projectA: InternalIterableAPI) {
        let torndown = expectation(description: "teardown for project switch")
        projectA.tearDownForProjectSwitch { _ in torndown.fulfill() }
        wait(for: [torndown], timeout: testExpectationTimeout)
    }

    private func container(networkSession: NetworkSessionProtocol) -> MockDependencyContainer {
        MockDependencyContainer(dateProvider: SystemDateProvider(),
                                networkSession: networkSession,
                                notificationStateProvider: MockNotificationStateProvider(enabled: true),
                                localStorage: localStorage,
                                inAppFetcher: MockInAppFetcher(),
                                inAppDisplayer: MockInAppDisplayer(),
                                inAppPersister: MockInAppPersister(),
                                urlOpener: MockUrlOpener(),
                                applicationStateProvider: MockApplicationStateProvider(applicationState: .active),
                                notificationCenter: NotificationCenter.default,
                                maxTasks: 1000,
                                apnsTypeChecker: MockAPNSTypeChecker(apnsType: .sandbox),
                                persistenceContextProvider: persistenceContextProvider)
    }

    private func makeOnlineProcessor(networkSession: NetworkSessionProtocol) -> OnlineRequestProcessor {
        OnlineRequestProcessor(apiKey: apiKeyA,
                               authProvider: nil,
                               authManager: nil,
                               endpoint: endpointA,
                               networkSession: networkSession,
                               deviceMetadata: DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                              platform: JsonValue.iOS,
                                                              appPackageName: Bundle.main.appPackageName ?? ""),
                               dateProvider: SystemDateProvider())
    }

    private func task(named name: String) -> IterableTask {
        IterableTask(id: IterableUtil.generateUUID(),
                     name: name,
                     type: .apiCall,
                     scheduledAt: Date(),
                     data: nil,
                     requestedAt: Date())
    }
}
