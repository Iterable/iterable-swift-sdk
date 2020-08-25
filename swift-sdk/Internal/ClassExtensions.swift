//
//  Created by Tapash Majumder on 9/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

extension Array {
    func take(_ size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func getValue(for key: JsonKey) -> Any? {
        self[key.jsonKey]
    }
    
    func getStringValue(for key: JsonKey, withDefault default: String? = nil) -> String? {
        getValue(for: key) as? String ?? `default`
    }
    
    func getIntValue(for key: JsonKey) -> Int? {
        getValue(for: key) as? Int
    }
    
    func getBoolValue(for key: JsonKey) -> Bool? {
        getValue(for: key) as? Bool
    }
    
    mutating func setValue(for key: JsonKey, value: JsonValueRepresentable?) {
        self[key.jsonKey] = value?.jsonValue
    }
    
    mutating func setValue(for key: JsonKeyRepresentable, value: JsonValueRepresentable?) {
        self[key.jsonKey] = value?.jsonValue
    }
}

extension Bundle {
    var appPackageName: String? {
        bundleIdentifier
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
        
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any] else {
            return nil
        }
        return dictionary
    }
}

extension UIColor {
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

extension Data {
    func hexString() -> String {
        map { String(format: "%02.2hhx", $0) }.joined()
    }
}

extension Int {
    func times(_ f: () -> Void) {
        if self > 0 {
            for _ in 0 ..< self {
                f()
            }
        }
    }
}
