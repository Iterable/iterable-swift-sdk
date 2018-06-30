//
//  APNSUtil.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 6/28/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

struct IterableAPNSUtil {
    static func isSandboxAPNS() -> Bool {
        if mobileProvision.count == 0 {
            // mobileprovision file not found; default to production on devices and sandbox on simulator
            #if TARGET_IPHONE_SIMULATOR
                return true
            #else
                return false
            #endif
        } else {
            if
                let entitlements = mobileProvision["Entitlements"] as? [AnyHashable : Any],
                let apsEnv = entitlements["aps-environment"] as? String {
                return apsEnv == "development"
            }
        }
        
        return false
    }

    private static var mobileProvision: [AnyHashable : Any] = {
        createMobileProvision()
    }()

    private static func createMobileProvision() -> [AnyHashable : Any] {
        guard let provisioningPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            print("resource not found")
            return [:]
        }
        
        guard let binaryString = try? String(contentsOfFile: provisioningPath, encoding: .ascii) else {
            print("couldn't read from file")
            return [:]
        }
        
        guard let propertyListString = scan(string: binaryString, begin: "<plist", end: "</plist>") else {
            return [:]
        }
        
        guard let propertyListData = propertyListString.data(using: .utf8) else {
            return [:]
        }
        
        guard let deserialized = try? PropertyListSerialization.propertyList(from: propertyListData, options: [], format: nil) else {
            return [:]
        }
        
        if let propertyList = deserialized as? [AnyHashable : Any] {
            return propertyList
        } else {
            return [:]
        }
    }
    
    private static func scan(string: String, begin:String, end: String) -> String? {
        let scanner = Scanner(string: string)
        var buffer: NSString?
        guard
            scanner.scanUpTo(begin, into: nil)
            ,scanner.scanUpTo(end, into: &buffer)
            ,let plistString = buffer
            
            else {
                return nil
        }
        
        return plistString.appending(end)
    }
}
