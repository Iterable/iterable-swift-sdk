//
//  AnonymousUserMerge.swift
//  Iterable-iOS-SDK
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

protocol AnonymousUserMergeProtocol {
    func tryMergeUser(anonymousUserId: String?, destinationUser: String?, isEmail: Bool, shouldMerge: Bool, onMergeResult: @escaping MergeActionHandler)
}

class AnonymousUserMerge: AnonymousUserMergeProtocol {
    
    var anonymousUserManager: AnonymousUserManagerProtocol
    var apiClient: ApiClient
    
    init(apiClient: ApiClient, anonymousUserManager: AnonymousUserManagerProtocol) {
        self.apiClient = apiClient
        self.anonymousUserManager = anonymousUserManager
    }
    
    func tryMergeUser(anonymousUserId: String?, destinationUser: String?, isEmail: Bool, shouldMerge: Bool, onMergeResult: @escaping MergeActionHandler) {
        if (anonymousUserId != nil && destinationUser != nil && shouldMerge) {
            let destinationEmail = isEmail ? destinationUser : nil
            let destinationUserId = isEmail ? nil : destinationUser
            
            apiClient.mergeUser(sourceEmail: nil, sourceUserId: anonymousUserId,  destinationEmail: destinationEmail, destinationUserId: destinationUserId).onSuccess {_ in
                onMergeResult(MergeResult.mergesuccessful, nil)
            }.onError {error in
                print("Merge failed error: \(error)")
                onMergeResult(MergeResult.mergefailed, error.reason)
            }
        } else {
            // this will return mergeResult true in case of anon userId doesn't exist or destinationUserIdOrEmail is nil because merge is not required
            onMergeResult(MergeResult.mergenotrequired, nil)
        }
    }
}
