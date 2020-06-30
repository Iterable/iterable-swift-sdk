//
//  Created by Tapash Majumder on 7/26/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

struct DeviceInfo: Codable {
    let mobileDeviceType = MobileDeviceType.iOS
    let deviceFp: DeviceFp
    
    struct DeviceFp: Codable {
        let userInterfaceIdiom: String
        let screenWidth: String
        let screenHeight: String
        let screenScale: String
        let version: String // systemVersion iOS
        let timezoneOffsetMinutes: String
        let language: String // current locale
    }
    
    static func createDeviceInfo() -> DeviceInfo {
        DeviceInfo(deviceFp: createDeviceFp())
    }
    
    private static func createDeviceFp() -> DeviceFp {
        let screen = UIScreen.main
        let device = UIDevice.current
        
        // iOS TimeZone stores secondsFromGMT which is the difference between the local time and GMT in seconds.
        // We are supposed to return 'timeZoneOffset', which is difference between GMT and local time in minutes.
        // Therefore, the conversion from secondsFomGMT to timezoneOffsetMinutes is as follows.
        let secondsFromGMT = TimeZone.current.secondsFromGMT()
        let timezoneOffsetMinutes = (-1.0 * Float(secondsFromGMT) / 60.0)
        
        return DeviceFp(userInterfaceIdiom: getUserInterfaceIdiom(),
                        screenWidth: String(Float(screen.bounds.width)),
                        screenHeight: String(Float(screen.bounds.height)),
                        screenScale: String(Float(screen.scale)),
                        version: device.systemVersion,
                        timezoneOffsetMinutes: String(timezoneOffsetMinutes),
                        language: Locale.current.identifier)
    }
    
    /// Returns UserInterfaceIdiom as String to be passed to server
    private static func getUserInterfaceIdiom() -> String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "iPhone"
        case .pad:
            return "iPad"
        case .tv:
            return "AppleTV"
        case .carPlay:
            return "CarPlay"
        case .mac:
            return "Mac"
        case .unspecified:
            return "Other"
        @unknown default:
            return "Other"
        }
    }
}
