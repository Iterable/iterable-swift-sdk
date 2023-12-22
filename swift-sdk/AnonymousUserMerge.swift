//
//  AnonymousUserMerge.swift
//  Iterable-iOS-SDK
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

class AnonymousUserMerge {

    public func mergeUserUsingUserId(apiClient: ApiClientProtocol, destinationUserId: String, sourceUserId: String, destinationEmail: String) {
        
        if IterableUtil.isNullOrEmpty(string: sourceUserId) || sourceUserId == destinationUserId {
            return
        }
        
        let data = apiClient.getUserByUserID(userId: sourceUserId, onSuccess: {data in
            if let data = data {
                do {
                    let dataObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let user = dataObj?["user"] as? [String: Any] {
                        self.callMergeApi(apiClient: apiClient, sourceEmail: "", sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationEmail: destinationUserId)
                    }
                } catch {
                    fatalError("Error parsing JSON: \(error)")
                }
            }
        })
    }

    public func mergeUserUsingEmail(apiClient: ApiClientProtocol, destinationEmail: String, sourceEmail: String) {
        
        if IterableUtil.isNullOrEmpty(string: sourceEmail) || sourceEmail == destinationEmail {
            return
        }


        apiClient.getUserByEmail(sourceEmail) { data in
            if let data = data {
                self.callMergeApi(apiClient: apiClient, sourceEmail: sourceEmail, sourceUserId: "", destinationEmail: destinationEmail, destinationUserId: IterableApi.getInstance().getUserId())
            }
        }
    }

    private func callMergeApi(apiClient: ApiClient, sourceEmail: String, sourceUserId: String, destinationEmail: String, destinationUserId: String) {
        apiClient.mergeUser(sourceEmail: sourceEmail, sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId) {
            data in
            if let data = data {
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let jsonData = jsonData {
                        self.anonymousUserManager.syncEvents()
                    }
                } catch {
                    fatalError("Error parsing JSON: \(error)")
                }
            }
        }
    }
}
