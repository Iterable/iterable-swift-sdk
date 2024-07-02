//
//  AnonymousUserMerge.swift
//  Iterable-iOS-SDK
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

protocol AnonymousUserMergeProtocol {
    func tryMergeUser(sourceUserId: String?, sourceEmail: String?, destinationUserId: String?,  destinationEmail: String?, merge: Bool, onMergeResult: @escaping MergeActionHandler)
}

class AnonymousUserMerge: AnonymousUserMergeProtocol {
    
    var anonymousUserManager: AnonymousUserManagerProtocol
    var apiClient: ApiClient
    
    init(apiClient: ApiClient, anonymousUserManager: AnonymousUserManagerProtocol) {
        self.apiClient = apiClient
        self.anonymousUserManager = anonymousUserManager
    }

    public func tryMergeUser(sourceUserId: String?, sourceEmail: String?, destinationUserId: String?,  destinationEmail: String?, merge: Bool, onMergeResult: @escaping MergeActionHandler) {
        if let sourceUserId = sourceUserId, let sourceEmail = sourceEmail, let destinationUserId = destinationUserId, let destinationEmail = destinationEmail {
            if (merge) {
                apiClient.mergeUser(sourceEmail: sourceEmail, sourceUserId: sourceUserId,  destinationEmail : destinationEmail, destinationUserId: destinationUserId).onSuccess {_ in
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
