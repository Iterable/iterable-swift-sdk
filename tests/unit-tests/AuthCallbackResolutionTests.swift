//
//  Copyright © 2026 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

/// Tests that AuthManager routes to the correct callback (success vs exhaustion)
/// when auth retries are exhausted, preventing Pending/Fulfill from hanging (SDK-392).
@available(iOS 13, *)
class AuthCallbackResolutionTests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let authToken = "testAuthToken"

    // MARK: - scheduleAuthTokenRefreshTimer exhaustion routing

    func testScheduleRefreshTimer_callsOnRetryExhausted_whenRetriesPaused() {
        let exhaustionCalled = expectation(description: "onRetryExhausted called when retries paused")
        let successNotCalled = expectation(description: "successCallback should not be called")
        successNotCalled.isInverted = true

        let authDelegate = SyncAuthDelegate { nil }

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 10, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: MockLocalStorage(),
            dateProvider: MockDateProvider()
        )

        authManager.pauseAuthRetries(true)

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.01,
            isScheduledRefresh: false,
            successCallback: { _ in successNotCalled.fulfill() },
            onRetryExhausted: { exhaustionCalled.fulfill() }
        )

        wait(for: [exhaustionCalled], timeout: testExpectationTimeout)
        wait(for: [successNotCalled], timeout: testExpectationTimeoutForInverted)
    }

    func testScheduleRefreshTimer_callsSuccess_whenTokenObtained() {
        let successCalled = expectation(description: "successCallback called with token")
        let exhaustionNotCalled = expectation(description: "onRetryExhausted should not be called")
        exhaustionNotCalled.isInverted = true

        let authDelegate = SyncAuthDelegate { Self.authToken }
        let localStorage = MockLocalStorage()
        localStorage.email = Self.email

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 10, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.01,
            isScheduledRefresh: false,
            successCallback: { token in
                XCTAssertEqual(token, Self.authToken)
                successCalled.fulfill()
            },
            onRetryExhausted: { exhaustionNotCalled.fulfill() }
        )

        wait(for: [successCalled], timeout: testExpectationTimeout)
        wait(for: [exhaustionNotCalled], timeout: testExpectationTimeoutForInverted)
    }

    func testScheduleRefreshTimer_callsExhaustion_whenMaxRetriesReached() {
        let exhaustionCalled = expectation(description: "onRetryExhausted called when max retries reached")

        let authDelegate = SyncAuthDelegate { nil }
        let localStorage = MockLocalStorage()
        localStorage.email = Self.email

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 0, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.01,
            isScheduledRefresh: false,
            successCallback: { _ in XCTFail("successCallback should not be called when retries exhausted") },
            onRetryExhausted: { exhaustionCalled.fulfill() }
        )

        wait(for: [exhaustionCalled], timeout: testExpectationTimeout)
    }

    func testScheduleRefreshTimer_queuesCallbacks_whenTimerAlreadyScheduled() {
        let firstSuccess = expectation(description: "first request's successCallback fires")
        let secondSuccess = expectation(description: "queued request's successCallback fires")

        let authDelegate = DelayedAuthDelegate(delay: 0.2) { Self.authToken }
        let localStorage = MockLocalStorage()
        localStorage.email = Self.email

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 10, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.05,
            isScheduledRefresh: false,
            successCallback: { token in
                XCTAssertEqual(token, Self.authToken)
                firstSuccess.fulfill()
            },
            onRetryExhausted: { XCTFail("first request should not exhaust") }
        )

        // Second call while timer is still scheduled — should hit the queueing branch
        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.05,
            isScheduledRefresh: false,
            successCallback: { token in
                XCTAssertEqual(token, Self.authToken)
                secondSuccess.fulfill()
            },
            onRetryExhausted: { XCTFail("queued request should not exhaust") }
        )

        wait(for: [firstSuccess, secondSuccess], timeout: testExpectationTimeout)
    }

    func testScheduleRefreshTimer_queuesExhaustionCallbacks_whenTimerAlreadyScheduled() {
        let firstExhausted = expectation(description: "first request's exhaustion fires")
        let secondExhausted = expectation(description: "queued request's exhaustion fires")

        let authDelegate = DelayedAuthDelegate(delay: 0.2) { nil }
        let localStorage = MockLocalStorage()
        localStorage.email = Self.email

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 0, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.05,
            isScheduledRefresh: false,
            successCallback: { _ in XCTFail("first should not succeed") },
            onRetryExhausted: { firstExhausted.fulfill() }
        )

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.05,
            isScheduledRefresh: false,
            successCallback: { _ in XCTFail("queued should not succeed") },
            onRetryExhausted: { secondExhausted.fulfill() }
        )

        wait(for: [firstExhausted, secondExhausted], timeout: testExpectationTimeout)
    }

    func testScheduleRefreshTimer_callsExhaustion_whenNoUserIdentity() {
        let exhaustionCalled = expectation(description: "onRetryExhausted called when no email/userId")

        let authDelegate = SyncAuthDelegate { Self.authToken }
        let localStorage = MockLocalStorage()
        // No email or userId set

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 10, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )

        authManager.scheduleAuthTokenRefreshTimer(
            interval: 0.01,
            isScheduledRefresh: false,
            successCallback: { _ in XCTFail("successCallback should not be called with no user identity") },
            onRetryExhausted: { exhaustionCalled.fulfill() }
        )

        wait(for: [exhaustionCalled], timeout: testExpectationTimeout)
    }

    // MARK: - RequestProcessorUtil end-to-end

    func testSendRequest_resolvesFulfillViaExhaustion_on401WhenRetriesExhausted() {
        let failureCalled = expectation(description: "failure handler called via exhaustion path")

        let invalidJwtError = SendRequestError(
            reason: "Invalid JWT",
            data: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload].toJsonData(),
            httpStatusCode: 401,
            iterableCode: JsonValue.Code.invalidJwtPayload
        )

        let authDelegate = SyncAuthDelegate { Self.authToken }
        let localStorage = MockLocalStorage()
        localStorage.email = Self.email

        let authManager = AuthManager(
            delegate: authDelegate,
            authRetryPolicy: RetryPolicy(maxRetry: 0, retryInterval: 0, retryBackoff: .linear),
            expirationRefreshPeriod: 60,
            localStorage: localStorage,
            dateProvider: MockDateProvider()
        )

        let result = RequestProcessorUtil.sendRequest(
            requestProvider: { Fulfill(error: invalidJwtError) },
            failureHandler: { _, _ in failureCalled.fulfill() },
            authManager: authManager,
            requestIdentifier: "test-exhausted-retries"
        )

        result.onSuccess { _ in
            XCTFail("Should not succeed when auth retries are exhausted")
        }

        wait(for: [failureCalled], timeout: testExpectationTimeout)
        XCTAssertTrue(result.isResolved())
    }

    // MARK: - Helpers

    private class SyncAuthDelegate: IterableAuthDelegate {
        private let tokenProvider: () -> String?

        init(_ tokenProvider: @escaping () -> String?) {
            self.tokenProvider = tokenProvider
        }

        func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
            completion(tokenProvider())
        }

        func onAuthFailure(_ authFailure: AuthFailure) {}
    }

    private class DelayedAuthDelegate: IterableAuthDelegate {
        private let delay: TimeInterval
        private let tokenProvider: () -> String?

        init(delay: TimeInterval, _ tokenProvider: @escaping () -> String?) {
            self.delay = delay
            self.tokenProvider = tokenProvider
        }

        func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [tokenProvider] in
                completion(tokenProvider())
            }
        }

        func onAuthFailure(_ authFailure: AuthFailure) {}
    }
}
