//
//  MockAuthManager.swift
//  swift-sdk
//
//  Created by HARDIK MASHRU on 08/11/23.
//  Copyright © 2023 Iterable. All rights reserved.
//
import Foundation
@testable import IterableSDK

class MockAuthManager: IterableAuthManagerProtocol {
    
    var token = "AuthToken"
    
    var shouldRetry = true
    var retryWasRequested = false
    var isLastAuthTokenValid = false
    var pauseAuthRetries = false
    var handleAuthFailureCalled = false
    var getNextRetryIntervalCalled = false
    var failedAuthCount = 0

    func handleAuthFailure(failedAuthToken: String?, reason: IterableSDK.AuthFailureReason) {
        failedAuthCount += 1
        handleAuthFailureCalled = true
        print("AuthManager handleAuthFailure with reason: \(reason.rawValue) and token: \(String(describing: failedAuthToken))")
    }

    func requestNewAuthToken(hasFailedPriorAuth: Bool, onSuccess: ((String?) -> Void)?, shouldIgnoreRetryPolicy: Bool) {
        if shouldRetry {
            // Simulate the authManager obtaining a new token
            retryWasRequested = true
            shouldRetry = false
            onSuccess?("newAuthToken")
        } else {
            // Simulate failing to obtain a new token
            retryWasRequested = false
            onSuccess?(nil)
        }
    }
    
    func scheduleAuthTokenRefreshTimer(interval: TimeInterval, isScheduledRefresh: Bool, successCallback: IterableSDK.AuthTokenRetrievalHandler?) {
        requestNewAuthToken(hasFailedPriorAuth: false, onSuccess: { newToken in
            guard let newToken else { return }
            self.setNewToken(newToken)
            successCallback?(newToken)
        }, shouldIgnoreRetryPolicy: true)
    }
    
    func pauseAuthRetries(_ pauseAuthRetry: Bool) {
        pauseAuthRetries = pauseAuthRetry
    }
    
    func setIsLastAuthTokenValid(_ isValid: Bool) {
        isLastAuthTokenValid = isValid
    }
    
    func getNextRetryInterval() -> Double {
        getNextRetryIntervalCalled = true
        return 0
    }
    

    func getAuthToken() -> String? {
        token
    }

    func resetFailedAuthCount() {
        failedAuthCount = 0
    }

    func setNewToken(_ newToken: String) {
        token = newToken
    }

    func logoutUser() {

    }
}
