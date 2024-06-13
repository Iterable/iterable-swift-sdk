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

    public func tryMergeUser(sourceUserId: String?, destinationUserIdOrEmail: String?, isEmail: Bool, onMergeResult: @escaping MergeActionHandler) {
        if let sourceUserId = sourceUserId, let destinationUserIdOrEmail = destinationUserIdOrEmail {
            apiClient.mergeUser(sourceEmail: nil, sourceUserId: sourceUserId, destinationEmail: isEmail ? destinationUserIdOrEmail : nil, destinationUserId: isEmail ? nil : destinationUserIdOrEmail).onSuccess {_ in
                onMergeResult(true, nil)
            }.onError {error in
                print("Merge failed error: \(error)")
                onMergeResult(false, error.reason)
            }
        } else {
            onMergeResult(true, nil)
        }
    }
}
