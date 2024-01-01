//
//  AnonymousUserMerge.swift
//  Iterable-iOS-SDK
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

class AnonymousUserMerge: AnonymousUserMergeProtocol {
    
    var anonymousUserManager: AnonymousUserManagerProtocol
    var apiClient: ApiClient
    
    init(apiClient: ApiClient, anonymousUserManager: AnonymousUserManagerProtocol) {
        self.apiClient = apiClient
        self.anonymousUserManager = anonymousUserManager
    }
    
    public func mergeUserUsingUserId(destinationUserId: String, sourceUserId: String, destinationEmail: String) {
        
        if IterableUtil.isNullOrEmpty(string: sourceUserId) || sourceUserId == destinationUserId {
            return
        }
        apiClient.getUserByUserID(userId: sourceUserId).onSuccess { data in
            if data["user"] is [String: Any] {
                self.callMergeApi(sourceEmail: "", sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId)
            }
        }
    }

    public func mergeUserUsingEmail(destinationUserId: String, destinationEmail: String, sourceEmail: String) {
        
        if IterableUtil.isNullOrEmpty(string: sourceEmail) || sourceEmail == destinationEmail {
            return
        }
        apiClient.getUserByEmail(email: sourceEmail).onSuccess { data in
            if data["user"] is [String: Any] {
                self.callMergeApi(sourceEmail: sourceEmail, sourceUserId: "", destinationEmail: destinationEmail, destinationUserId: destinationUserId)
            }
        }
    }

    private func callMergeApi(sourceEmail: String, sourceUserId: String, destinationEmail: String, destinationUserId: String) {
        apiClient.mergeUser(sourceEmail: sourceEmail, sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId).onSuccess {_ in 
            self.anonymousUserManager.syncNonSyncedEvents()
        }
    }
}
