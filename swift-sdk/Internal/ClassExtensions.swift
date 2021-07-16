//
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

extension Array where Element: Comparable {
    func isAscending() -> Bool {
        return zip(self, self.dropFirst()).allSatisfy(<=)
    }

    func isDescending() -> Bool {
        return zip(self, self.dropFirst()).allSatisfy(>=)
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func getStringValue(for key: AnyHashable, withDefault default: String? = nil) -> String? {
        self[key] as? String ?? `default`
    }

    func getIntValue(for key: AnyHashable) -> Int? {
        self[key] as? Int
    }

    func getDoubleValue(for key: AnyHashable) -> Double? {
        self[key] as? Double
    }

    func getBoolValue(for key: AnyHashable) -> Bool? {
        self[key].flatMap ( Self.parseBool(_:) )
    }

    mutating func setValue(for key: AnyHashable, value: JsonValueRepresentable?) {
        self[key] = value?.jsonValue
    }

    private static func parseBool(_ any: Any?) -> Bool? {
        guard let any = any else {
            return nil
        }
        
        if let bool = any as? Bool {
            return bool
        } else if let number = any as? NSNumber {
            return number.boolValue
        } else if let string = any as? String {
            return Int(string).map(NSNumber.init).map { $0.boolValue }
        } else {
            return nil
        }
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
        
        return try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
    }
}

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        guard let int = Int(hex, radix: 16) else {
            return nil
        }
        
        let r = Float((int & 0xFF0000) >> 16) / 255.0
        let g = Float((int & 0x00FF00) >> 8) / 255.0
        let b = Float((int & 0x0000FF) >> 0) / 255.0
        
        self.init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: alpha)
    }

    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
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
