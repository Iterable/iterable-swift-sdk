//
//  AnonymousUserMerge.swift
//
//
//  Created by Hani Vora on 19/12/23.
//

import Foundation

@objc public protocol AnonymousUserMergeProtocol {
    func mergeUserUsingUserId(apiClient: IterableApiClient, destinationUserId: String)
    func mergeUserUsingEmail(apiClient: IterableApiClient, destinationEmail: String)
}

class AnonymousUserMerge : AnonymousUserMergeProtocol {
    private static let anonymousUserManager = AnonymousUserManager()

    func mergeUserUsingUserId(apiClient: IterableApiClient, destinationUserId: String) {
        guard let sourceUserId = IterableApi.getInstance().getUserId(), !sourceUserId.isEmpty else {
            return
        }

        apiClient.getUserByUserID(sourceUserId) { data in
            if let data = data {
                do {
                    let dataObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let user = dataObj?["user"] as? [String: Any] {
                        self.callMergeApi(apiClient: apiClient, sourceEmail: "", sourceUserId: sourceUserId, destinationEmail: IterableApi.getInstance().getEmail(), destinationUserId: destinationUserId)
                    }
                } catch {
                    fatalError("Error parsing JSON: \(error)")
                }
            }
        }
    }

    func mergeUserUsingEmail(apiClient: IterableApiClient, destinationEmail: String) {
        guard let sourceEmail = IterableApi.getInstance().getUserId(), !sourceEmail.isEmpty else {
            return
        }

        apiClient.getUserByEmail(sourceEmail) { data in
            if let data = data {
                self.callMergeApi(apiClient: apiClient, sourceEmail: sourceEmail, sourceUserId: "", destinationEmail: destinationEmail, destinationUserId: IterableApi.getInstance().getUserId())
            }
        }
    }

    private func callMergeApi(apiClient: IterableApiClient, sourceEmail: String, sourceUserId: String, destinationEmail: String, destinationUserId: String) {
        apiClient.mergeUser(sourceEmail: sourceEmail, sourceUserId: sourceUserId, destinationEmail: destinationEmail, destinationUserId: destinationUserId) { data in
            if let data = data {
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let jsonData = jsonData {
                        print("Merge User Data: \(jsonData)")
                        self.anonymousUserManager.syncEvents()
                    }
                } catch {
                    fatalError("Error parsing JSON: \(error)")
                }
            }
        }
    }
}
