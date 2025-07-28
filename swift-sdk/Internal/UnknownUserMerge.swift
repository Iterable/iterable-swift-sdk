//
//  UnknownUserMerge.swift
//  Iterable-iOS-SDK
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

protocol UnknownUserMergeProtocol {
    func tryMergeUser(destinationUser: String?, isEmail: Bool, merge: Bool, onMergeResult: @escaping MergeActionHandler)
}

class UnknownUserMerge: UnknownUserMergeProtocol {
    
    var unknownUserManager: UnknownUserManagerProtocol
    var apiClient: ApiClient
    private var localStorage: LocalStorageProtocol
    
    init(apiClient: ApiClient, unknownUserManager: UnknownUserManagerProtocol, localStorage: LocalStorageProtocol) {
        self.apiClient = apiClient
        self.unknownUserManager = unknownUserManager
        self.localStorage = localStorage
    }
    
    func tryMergeUser(destinationUser: String?, isEmail: Bool, merge: Bool, onMergeResult: @escaping MergeActionHandler) {
        let unknownUserId = localStorage.userIdUnknownUser
        
        if (unknownUserId != nil && destinationUser != nil && merge) {
            let destinationEmail = isEmail ? destinationUser : nil
            let destinationUserId = isEmail ? nil : destinationUser
            
            apiClient.mergeUser(sourceEmail: nil, sourceUserId: unknownUserId,  destinationEmail: destinationEmail, destinationUserId: destinationUserId).onSuccess {_ in
                onMergeResult(MergeResult.mergesuccessful, nil)
            }.onError {error in
                print("Merge failed error: \(error)")
                onMergeResult(MergeResult.mergefailed, error.reason)
            }
        } else {
            // this will return mergeResult true in case of unknown userId doesn't exist or destinationUserIdOrEmail is nil because merge is not required
            onMergeResult(MergeResult.mergenotrequired, nil)
        }
    }
}
