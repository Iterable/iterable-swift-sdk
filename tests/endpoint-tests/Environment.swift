//
//  Created by Tapash Majumder on 6/30/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

/// Read from ProcessInfo
/// These values come from Scheme arguments.
/// They will not be available when not launching from XCode.
struct Environment {
    enum Key: String {
        case apiKey = "api_key"
        case email
        case notificationDisabled
    }
    
    static func get(key: Key) -> String? {
        ProcessInfo.processInfo.environment[key.rawValue]
    }
    
    static func getBool(key: Key) -> Bool {
        guard let strValue = get(key: key) else {
            return false
        }
        return Bool(strValue) ?? false
    }
}
