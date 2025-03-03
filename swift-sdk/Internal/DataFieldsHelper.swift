//
//  Copyright © 2020 Iterable. All rights reserved.
//

/// This file contains static pure helper functions for creating
/// the dataFields dictionary.

import Foundation
import UIKit

struct DataFieldsHelper {
    static func createDataFields(sdkVersion: String?,
                                 deviceId: String,
                                 device: UIDevice,
                                 bundle: Bundle,
                                 notificationsEnabled: Bool,
                                 deviceAttributes: [String: String],
                                 mobileFrameworkInfo: IterableAPIMobileFrameworkInfo) -> [String: Any] {
        var dataFields = [String: Any]()
        
        deviceAttributes.forEach { deviceAttribute in
            dataFields[deviceAttribute.key] = deviceAttribute.value
        }
        
        dataFields[JsonKey.deviceId] = deviceId
        
        if let sdkVersion = sdkVersion {
            dataFields[JsonKey.iterableSdkVersion] = sdkVersion
        }
        
        dataFields[JsonKey.notificationsEnabled] = notificationsEnabled
        
        dataFields.addAll(other: createBundleFields(bundle: bundle))
        
        dataFields.addAll(other: createUIDeviceFields(device: device))
        
        dataFields[JsonKey.mobileFrameworkInfo] = [
            JsonKey.frameworkType: mobileFrameworkInfo.frameworkType.rawValue,
            JsonKey.iterableSdkVersion: mobileFrameworkInfo.iterableSdkVersion ?? "unknown"
        ]
        
        return dataFields
    }
    
    private static func createBundleFields(bundle: Bundle) -> [String: Any] {
        var fields = [String: Any]()
        
        if let appPackageName = bundle.appPackageName {
            fields[JsonKey.appPackageName] = appPackageName
        }
        if let appVersion = bundle.appVersion {
            fields[JsonKey.appVersion] = appVersion
        }
        if let appBuild = bundle.appBuild {
            fields[JsonKey.appBuild] = appBuild
        }
        
        return fields
    }
    
    private static func createUIDeviceFields(device: UIDevice) -> [String: Any] {
        var fields = [String: Any]()
        
        fields[JsonKey.Device.localizedModel] = device.localizedModel
        fields[JsonKey.Device.userInterfaceIdiom] = userInterfaceIdiomEnumToString(device.userInterfaceIdiom)
        fields[JsonKey.Device.systemName] = device.systemName
        fields[JsonKey.Device.systemVersion] = device.systemVersion
        fields[JsonKey.Device.model] = device.model

        if let identifierForVendor = device.identifierForVendor?.uuidString {
            fields[JsonKey.Device.vendorId] = identifierForVendor
        }
        
        return fields
    }
    
    private static func userInterfaceIdiomEnumToString(_ idiom: UIUserInterfaceIdiom) -> String {
        switch idiom {
        case .phone:
            return JsonValue.DeviceIdiom.phone
        case .pad:
            return JsonValue.DeviceIdiom.pad
        case .tv:
            return JsonValue.DeviceIdiom.tv
        case .carPlay:
            return JsonValue.DeviceIdiom.carPlay
        default:
            return JsonValue.DeviceIdiom.unspecified
        }
    }
}

extension Dictionary {
    mutating func addAll(other: [Key: Value]) {
        for (k, v) in other {
            self[k] = v
        }
    }
}
