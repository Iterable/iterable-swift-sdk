//
//  AnonymousUserMerge.swift
//  Iterable-iOS-SDK
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

class AnonymousUserMerge {
    
    var dependencyContainer: DependencyContainerProtocol
    
    lazy var anonymousUserManager: AnonymousUserManagerProtocol = {
        self.dependencyContainer.createAnonymousUserManager()
    }()
    
    init(dependencyContainer: DependencyContainerProtocol) {
        self.dependencyContainer = dependencyContainer
    }
    
    public func mergeUserUsingUserId(apiClient: ApiClient, destinationUserId: String, sourceUserId: String, destinationEmail: String) {
        
        if IterableUtil.isNullOrEmpty(string: sourceUserId) || sourceUserId == destinationUserId {
            return
        }
        apiClient.getUserByUserID(userId: sourceUserId).onSuccess { data in
            if data["user"] is [String: Any] {
                self.callMergeApi(apiClient: apiClient, sourceEmail: "", sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId)
            }
        }
    }

    public func mergeUserUsingEmail(apiClient: ApiClient, destinationUserId: String, destinationEmail: String, sourceEmail: String) {
        
        if IterableUtil.isNullOrEmpty(string: sourceEmail) || sourceEmail == destinationEmail {
            return
        }
        apiClient.getUserByEmail(email: sourceEmail).onSuccess { data in
            if data["user"] is [String: Any] {
                self.callMergeApi(apiClient: apiClient, sourceEmail: sourceEmail, sourceUserId: "", destinationEmail: destinationEmail, destinationUserId: destinationUserId)
            }
        }
    }

    private func callMergeApi(apiClient: ApiClient, sourceEmail: String, sourceUserId: String, destinationEmail: String, destinationUserId: String) {
        apiClient.mergeUser(sourceEmail: sourceEmail, sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId).onSuccess { response in
            if let data = response as? [String: Any] {
                // Check for the presence of the expected key or perform other operations
                if data["key"] is [String: Any] {
                    self.anonymousUserManager.syncNonSyncedEvents()
                } else {
                    // Handle the case when the expected key is not present
                    print("Error: 'key' not found in response")
                }
            } else {
                // Handle the case when the response is not a dictionary
                print("Error: Response is not a dictionary")
            }
        }
    }
}
