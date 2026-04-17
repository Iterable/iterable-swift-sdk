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

    func testScheduleRefreshTimer_queuesBothCallbacks_whenTimerAlreadyScheduled() {
        let firstSuccess = expectation(description: "first successCallback resolved")
        let secondSuccess = expectation(description: "queued successCallback resolved")

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
            interval: 0.05,
            isScheduledRefresh: false,
            successCallback: { _ in firstSuccess.fulfill() },
            onRetryExhausted: { XCTFail("exhaustion should not fire on success") }
        )

        // Second scheduling while the first timer is still pending — should queue
        // both successCallback and onRetryExhausted callbacks.
        authManager.scheduleAuthTokenRefreshTimer(
            interval: 10,
            isScheduledRefresh: false,
            successCallback: { _ in secondSuccess.fulfill() },
            onRetryExhausted: { XCTFail("exhaustion should not fire on success") }
        )

        wait(for: [firstSuccess, secondSuccess], timeout: testExpectationTimeout)
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
}
