//
//  DeviceInfo.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 7/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct DeviceInfo {
    enum JsKeys : String {
        case iosDeviceType
        case isIPhone
        case isIPad
        case version
        case screenWidth
        case screenHeight
        case screenScale
        case timezoneOffsetMinutes
        case language
    }
    
    static func createJsDeviceInfo() -> [String : String] {
        return createDeviceInfo().toJsDeviceInfo()
    }
    
    func toJsDeviceInfo() -> [String : String] {
        var dict = [String: String]()
        dict[JsKeys.iosDeviceType.rawValue] = iosDeviceType.rawValue
        dict[JsKeys.isIPhone.rawValue] = "" + String(isIPhone)
        dict[JsKeys.isIPad.rawValue] = "" + String(isIPad)
        dict[JsKeys.version.rawValue] = version
        dict[JsKeys.screenWidth.rawValue] = String(screenInfo.width)
        dict[JsKeys.screenHeight.rawValue] = String(screenInfo.height)
        dict[JsKeys.screenScale.rawValue] = String(screenInfo.scale)
        // secondsFromGMT = time - GMT, timeZoneOffset = GMT - time
        dict[JsKeys.timezoneOffsetMinutes.rawValue] = String(-1.0 * Float(secondsFromGMT) / 60.0)
        dict[JsKeys.language.rawValue] = language

        return dict
    }
    
    enum IOSDeviceType : String, Codable {
        case iPodTouch5
        case iPodTouch6
        case iPhone4
        case iPhone4S
        case iPhone5
        case iPhone5C
        case iPhone5S
        case iPhone6
        case iPhone6Plus
        case iPhone6S
        case iPhone6SPlus
        case iPhone7
        case iPhone7Plus
        case iPhoneSE
        case iPad2
        case iPad3
        case iPad4
        case iPadAir
        case iPadAir2
        case iPadMini
        case iPadMini2
        case iPadMini3
        case iPadMini4
        case iPadPro
        case simulator
        case unknown
    }
    
    struct ScreenInfo {
        let width: Float
        let height: Float
        let scale: Float
    }
    
    let iosDeviceType: IOSDeviceType
    let screenInfo: ScreenInfo
    let version: String
    let userInterfaceIdiom: UIUserInterfaceIdiom
    let secondsFromGMT: Int
    let language: String

    static func createDeviceInfo() -> DeviceInfo {
        let screen = UIScreen.main
        let device = UIDevice.current
        let screenInfo = ScreenInfo(width: Float(screen.bounds.width), height: Float(screen.bounds.height), scale: Float(screen.scale))
        return DeviceInfo(iosDeviceType: getIOSDeviceType(),
                          screenInfo: screenInfo,
                          version: device.systemVersion,
                          userInterfaceIdiom: device.userInterfaceIdiom,
                          secondsFromGMT: TimeZone.current.secondsFromGMT(),
                          language: Locale.current.identifier)
    }

    var isIPhone: Bool {
        return userInterfaceIdiom == .phone
    }
    
    var isIPad: Bool {
        return userInterfaceIdiom == .pad
    }
    
    private static func getIOSDeviceType() -> IOSDeviceType {
        return iosDeviceType(fromModelName: getModelName())
    }
    
    private static func iosDeviceType(fromModelName modelName: String) -> IOSDeviceType {
        switch (modelName) {
        case "iPod Touch 5" : return .iPodTouch5
        case "iPod Touch 6" : return .iPodTouch6
        case "iPhone 4" : return .iPhone4
        case "iPhone 4s" : return .iPhone4S
        case "iPhone 5" : return .iPhone5
        case "iPhone 5c" : return .iPhone5C
        case "iPhone 5s" : return .iPhone5S
        case "iPhone 6" : return .iPhone6
        case "iPhone 6 Plus" : return .iPhone6Plus
        case "iPhone 6s" : return .iPhone6S
        case "iPhone 6s Plus" : return .iPhone6SPlus
        case "iPhone 7" : return .iPhone7
        case "iPhone 7 Plus" : return .iPhone7Plus
        case "iPhone SE" : return .iPhoneSE
        case "iPad 2" : return .iPad2
        case "iPad 3" : return .iPad3
        case "iPad 4" : return .iPad4
        case "iPad Air" : return .iPadAir
        case "iPad Air 2" : return .iPadAir2
        case "iPad Mini" : return .iPadMini
        case "iPad Mini 2" : return .iPadMini2
        case "iPad Mini 3" : return .iPadMini3
        case "iPad Mini 4" : return .iPadMini4
        case "iPad Pro" : return .iPadPro
        case "Simulator" : return .simulator
        default: return .unknown
        }
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
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}

