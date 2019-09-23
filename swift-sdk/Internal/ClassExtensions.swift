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
    func getStringValue(for key: JsonKey, withDefault default: String? = nil) -> String? {
        return self[key.jsonKey] as? String ?? `default`
    }
    
    func getIntValue(for key: JsonKey) -> Int? {
        return self[key.jsonKey] as? Int
    }
    
    func getBoolValue(for key: JsonKey) -> Bool? {
        return self[key.jsonKey] as? Bool
    }
    
    mutating func setValue(for key: JsonKey, value: JsonValueRepresentable) {
        self[key.jsonKey] = value.jsonValue
    }
    
    mutating func setValue(for key: JsonKey, value: Any?) {
        self[key.jsonKey] = value
    }
}

public extension Bundle {
    var appPackageName: String? {
        return bundleIdentifier
    }
    
    var appVersion: String? {
        guard let infoDictionary = self.infoDictionary else {
            return nil
        }
        
        return infoDictionary["CFBundleShortVersionString"] as? String
    }
    
    var appBuild: String? {
        guard let infoDictionary = self.infoDictionary else {
            return nil
        }
        
        return infoDictionary["CFBundleVersion"] as? String
    }
}

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
    }
}

public extension UIColor {
    convenience init?(hex: String) {
        guard let int = Int(hex, radix: 16) else {
            return nil
        }
        
        let r = Float((int & 0xFF0000) >> 16) / 255.0
        let g = Float((int & 0x00FF00) >> 8) / 255.0
        let b = Float((int & 0x0000FF) >> 0) / 255.0
        
        self.init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
    }
}

public extension Data {
    // from: https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
    func hexString() -> String {
        return map { String(format: "%02.2hhx", $0) }.joined()
    }
}
