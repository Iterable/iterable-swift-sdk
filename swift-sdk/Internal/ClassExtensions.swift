//
//
//  Created by Tapash Majumder on 9/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public extension Array {
    func take(_ size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

public extension Dictionary where Key == AnyHashable, Value == Any {
    func getStringValue(key: JsonKey, withDefault `default`: String? = nil) -> String? {
        return self[key.rawValue] as? String ?? `default`
    }
}

public extension Bundle {
    public var appPackageName : String? {
        return bundleIdentifier
    }
    
    public var appVersion : String? {
        guard let infoDictionary = self.infoDictionary else {
            return nil
        }
        return infoDictionary["CFBundleShortVersionString"] as? String
    }

    public var appBuild : String? {
        guard let infoDictionary = self.infoDictionary else {
            return nil
        }
        return infoDictionary["CFBundleVersion"] as? String
    }
}
