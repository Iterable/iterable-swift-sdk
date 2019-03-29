//
//
//  Created by Tapash Majumder on 9/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

public extension Bundle {
    var appPackageName : String? {
        return bundleIdentifier
    }
    
    var appVersion : String? {
        guard let infoDictionary = self.infoDictionary else {
            return nil
        }
        return infoDictionary["CFBundleShortVersionString"] as? String
    }

    var appBuild : String? {
        guard let infoDictionary = self.infoDictionary else {
            return nil
        }
        return infoDictionary["CFBundleVersion"] as? String
    }
}
