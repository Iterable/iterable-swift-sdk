//
//  BCITDataRegion.swift
//  IterableSDK-Integration-Tester
//
//  Maps the `dataRegion` of a project block in test-config.json to the
//  server-side API base URL, so a project in another region needs config only.
//
//  Used by both the app target and the UI-test target.
//

import Foundation

enum BCITDataRegion {
    static let us = "US"
    static let eu = "EU"

    static let defaultServerBaseURL = "https://api.iterable.com"

    static func serverBaseURL(for region: String) -> String {
        region.uppercased() == eu ? "https://api.eu.iterable.com" : defaultServerBaseURL
    }
}
