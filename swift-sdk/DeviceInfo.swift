//
//  DeviceInfo.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 7/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct DeviceInfo : Codable {
    let mobileDeviceType = MobileDeviceType.iOS
    let deviceFp: DeviceFp
    
    enum MobileDeviceType : String, Codable {
        case iOS
        case Android
    }
    
    struct DeviceFp : Codable {
        let iosDeviceType: String
        let screenWidth: String
        let screenHeight: String
        let screenScale: String
        let version: String // systemVersion iOS
        let timezoneOffsetMinutes: String
        let language: String // current locale
    }
    
    static func createDeviceInfo() -> DeviceInfo {
        return DeviceInfo(deviceFp: createDeviceFp())
    }
    
    private static func createDeviceFp() -> DeviceFp {
        let screen = UIScreen.main
        let device = UIDevice.current
        // iOS TimeZone stores secondsFromGMT which is the difference between the local time and GMT in seconds.
        // We are supposed to return 'timeZoneOffset', which is difference between GMT and local time in minutes.
        // Therefore, the conversion from secondsFomGMT to timezoneOffsetMinutes is as follows.
        let secondsFromGMT = TimeZone.current.secondsFromGMT()
        let timezoneOffsetMinutes = (-1.0 * Float(secondsFromGMT) / 60.0)
        return DeviceFp(iosDeviceType: getModelName(),
                          screenWidth: String(Float(screen.bounds.width)),
                          screenHeight: String(Float(screen.bounds.height)),
                          screenScale: String(Float(screen.scale)),
                          version: device.systemVersion,
                          timezoneOffsetMinutes: String(timezoneOffsetMinutes),
                          language: Locale.current.identifier)
    }

    private static func getModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8", "iPad7,1", "iPad7,2":return "iPad Pro 12.9 Inch"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                              return "Apple TV"
        case "AppleTV6,2":                              return "Apple TV 4K"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

