//
//  Copyright © 2026 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

/// Covers the JWT 401 retry paths added to `OfflineRequestProcessor.sendIterableRequest`
/// by SDK-392, including the `onRetryExhausted` branch that resolves the pending
/// callback chain when auth retries can no longer obtain a valid token.
class OfflineRequestProcessorJWTRetryTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
        try! persistenceContextProvider.mainQueueContext().deleteAllTasks()
        try! persistenceContextProvider.mainQueueContext().save()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testJWT401_invokesFailureHandler_whenAuthRetryExhausted() throws {
        // Expect at least two failure invocations: one from RequestProcessorUtil.apply's
        // generic onError, and one from the new onRetryExhausted callback in
        // OfflineRequestProcessor.sendIterableRequest (SDK-392).
        let failureHandlerCalled = expectation(description: "onFailure invoked via apply + onRetryExhausted")
        failureHandlerCalled.expectedFulfillmentCount = 2
        failureHandlerCalled.assertForOverFulfill = false

        let jwtErrorBody: [AnyHashable: Any] = [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload]
        let jwtErrorData = jwtErrorBody.toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let authManager = MockAuthManager()
        authManager.shouldRetry = false

        let notificationCenter = MockNotificationCenter()
        let processor = createOfflineProcessor(networkSession: networkSession,
                                               authManager: authManager,
                                               notificationCenter: notificationCenter)
        processor.start()

        let pending = processor.track(event: "exhaustion-event", dataFields: nil,
                                       onSuccess: { _ in
                                           XCTFail("Should not succeed when JWT 401 retries are exhausted")
                                       },
                                       onFailure: { reason, _ in
                                           XCTAssertNotNil(reason)
                                           failureHandlerCalled.fulfill()
                                       })

        wait(for: [failureHandlerCalled], timeout: testExpectationTimeout)
        XCTAssertTrue(pending.isResolved())
        XCTAssertTrue(authManager.handleAuthFailureCalled)

        processor.stop()
    }

    func testJWT401_reschedulesRequest_viaSuccessCallback() throws {
        // When the auth manager successfully refreshes the token, the new successCallback
        // body in OfflineRequestProcessor must re-invoke sendIterableRequest, scheduling
        // a second task.
        let retryScheduled = expectation(description: "sendIterableRequest re-scheduled after token refresh")

        let jwtErrorBody: [AnyHashable: Any] = [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload]
        let jwtErrorData = jwtErrorBody.toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)

        let authManager = MockAuthManager()
        authManager.shouldRetry = true

        let notificationCenter = MockNotificationCenter()
        let processor = createOfflineProcessor(networkSession: networkSession,
                                               authManager: authManager,
                                               notificationCenter: notificationCenter)
        processor.start()

        var scheduledTaskCount = 0
        let reference = notificationCenter.addCallback(forNotification: .iterableTaskScheduled) { _ in
            scheduledTaskCount += 1
            if scheduledTaskCount >= 2 {
                retryScheduled.fulfill()
            }
        }
        XCTAssertNotNil(reference)

        _ = processor.track(event: "retry-event", dataFields: nil,
                            onSuccess: { _ in },
                            onFailure: { _, _ in })

        wait(for: [retryScheduled], timeout: testExpectationTimeout)
        XCTAssertTrue(authManager.retryWasRequested, "successCallback branch must request a new token")

        processor.stop()
    }

    // MARK: - Helpers

    private func createOfflineProcessor(networkSession: NetworkSessionProtocol,
                                        authManager: IterableAuthManagerProtocol,
                                        notificationCenter: NotificationCenterProtocol) -> OfflineRequestProcessor {
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let taskScheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                                  notificationCenter: notificationCenter,
                                                  healthMonitor: healthMonitor,
                                                  dateProvider: dateProvider)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            dateProvider: dateProvider)
        return OfflineRequestProcessor(apiKey: "zee-api-key",
                                       authProvider: self,
                                       authManager: authManager,
                                       endpoint: Endpoint.api,
                                       deviceMetadata: Self.deviceMetadata,
                                       taskScheduler: taskScheduler,
                                       taskRunner: taskRunner,
                                       notificationCenter: notificationCenter)
    }

    private static let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                       platform: JsonValue.iOS,
                                                       appPackageName: Bundle.main.appPackageName ?? "")

    private let dateProvider = MockDateProvider()

    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)!
        return provider
    }()
}

extension OfflineRequestProcessorJWTRetryTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: "zee-auth-token", userIdUnknownUser: nil)
    }
}
