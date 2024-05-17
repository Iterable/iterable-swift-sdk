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
    func requestNewAuthToken(hasFailedPriorAuth: Bool, onSuccess: ((String?) -> Void)?, shouldIgnoreRetryPolicy: Bool) {
        
    }
    
    func scheduleAuthTokenRefreshTimer(interval: TimeInterval, isScheduledRefresh: Bool, successCallback: IterableSDK.AuthTokenRetrievalHandler?) {
        
    }
    
    func pauseAuthRetries(_ pauseAuthRetry: Bool) {
        
    }
    
    func setIsLastAuthTokenValid(_ isValid: Bool) {
        
    }
    
    func getNextRetryInterval() -> Double {
        return 2
    }
    
    var shouldRetry = true
    var retryWasRequested = false

    func getAuthToken() -> String? {
        return "AuthToken"
    }

    func resetFailedAuthCount() {

    }

    func requestNewAuthToken(hasFailedPriorAuth: Bool, onSuccess: ((String?) -> Void)?) {
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

    func setNewToken(_ newToken: String) {

    }

    func logoutUser() {

    }
}
