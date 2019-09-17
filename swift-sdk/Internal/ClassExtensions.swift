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

public extension Data {
    //from: https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
    func hexString() -> String {
        let digits = Array("01234567890abcdef".utf16)
        
        var chars: [UniChar] = []
        chars.reserveCapacity(count * 2)
        
        for byte in self {
            chars.append(digits[Int(byte / 16)])
            chars.append(digits[Int(byte % 16)])
        }
        
        return String(utf16CodeUnits: chars, count: chars.count)
    }
}
