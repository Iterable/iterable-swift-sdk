//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct ResourceHelper {
    /// Checks for resource inside bundle and sub bundles of the bundle.
    /// SubResource could exist inside *another* bundle inside this bundle.
    /// The sub bundle could be from Swift Package Manager or Cocoapods.
    static func url(forResource name: String, withExtension ext: String, fromBundle bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        
        return findSubBundle(forBundle: bundle).flatMap { $0.url(forResource: name, withExtension: ext) }
    }
    
    private static let spmPackageName = "IterableSDK"
    private static let spmLibraryName = "IterableSDK"
    private static let cocoaPodsResourceBundleName = "Resources"

    private static let possibleSubBundleNames = [
        "\(spmPackageName)_\(spmLibraryName)",
        "\(cocoaPodsResourceBundleName)"
    ]

    private static func findSubBundle(forBundle bundle: Bundle) -> Bundle? {
        possibleSubBundleNames
            .compactMap { subBundle(withName: $0, andExtension: "bundle", fromBundle: bundle) }
            .first
    }
    
    private static func subBundle(withName name: String, andExtension ext: String, fromBundle bundle: Bundle) -> Bundle? {
        bundle.url(forResource: name, withExtension: ext).flatMap(Bundle.init)
    }
}
