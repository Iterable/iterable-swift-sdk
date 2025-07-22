//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import os
import UIKit

@objc final class IterableUtil: NSObject {
    static var rootViewController: UIViewController? {
        // Try modern approach first for iOS 13+ multi-window support
        if #available(iOS 13.0, *) {
            if let activeViewController = getActiveWindowRootViewController() {
                return activeViewController
            }
        }
        
        // Existing fallback chain - unchanged for backward compatibility
        if let rootViewController = AppExtensionHelper.application?.delegate?.window??.rootViewController {
            return rootViewController
        } else {
            return AppExtensionHelper.application?.windows.first?.rootViewController
        }
    }
    
    @available(iOS 13.0, *)
    private static func getActiveWindowRootViewController() -> UIViewController? {
        guard let application = AppExtensionHelper.application else { 
            ITBDebug("No application found in AppExtensionHelper")
            return nil 
        }
        
        ITBDebug("Application has \(application.connectedScenes.count) connected scenes")
        
        // Find active scenes (foreground active takes priority)
        let activeScenes = application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        
        ITBDebug("Found \(activeScenes.count) foreground active scenes")
        
        // iOS 15+: Use scene's keyWindow property (preferred approach)
        if #available(iOS 15.0, *) {
            for (index, scene) in activeScenes.enumerated() {
                ITBDebug("Checking scene \(index): keyWindow exists = \(scene.keyWindow != nil)")
                if let keyWindow = scene.keyWindow,
                   let rootVC = keyWindow.rootViewController {
                    ITBDebug("Found root view controller in keyWindow: \(String(describing: rootVC))")
                    return rootVC
                } else {
                    ITBDebug("Scene \(index): keyWindow or rootVC is nil")
                }
            }
        } else {
            // iOS 13-14: Fall back to isKeyWindow check
            for (index, scene) in activeScenes.enumerated() {
                let keyWindows = scene.windows.filter { $0.isKeyWindow }
                ITBDebug("Scene \(index): found \(keyWindows.count) key windows")
                if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = keyWindow.rootViewController {
                    ITBDebug("Found root view controller in keyWindow (iOS 13-14): \(String(describing: rootVC))")
                    return rootVC
                } else {
                    ITBDebug("Scene \(index): no keyWindow with rootVC found")
                }
            }
        }
        
        // Fallback to first window in first active scene
        if let firstActiveScene = activeScenes.first,
           let rootVC = firstActiveScene.windows.first?.rootViewController {
            ITBDebug("Fallback: Found root view controller in first window of first active scene: \(String(describing: rootVC))")
            return rootVC
        } else {
            ITBDebug("Fallback: No root view controller found in first window of first active scene")
        }
        
        // Final fallback: any foreground inactive scene
        let inactiveScenes = application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundInactive }
        
        ITBDebug("Checking \(inactiveScenes.count) foreground inactive scenes as final fallback")
        
        if #available(iOS 15.0, *) {
            for (index, scene) in inactiveScenes.enumerated() {
                ITBDebug("Inactive scene \(index): keyWindow exists = \(scene.keyWindow != nil)")
                if let keyWindow = scene.keyWindow,
                   let rootVC = keyWindow.rootViewController {
                    ITBDebug("Final fallback: Found root view controller in inactive scene keyWindow: \(String(describing: rootVC))")
                    return rootVC
                }
            }
        } else {
            for (index, scene) in inactiveScenes.enumerated() {
                let keyWindows = scene.windows.filter { $0.isKeyWindow }
                ITBDebug("Inactive scene \(index): found \(keyWindows.count) key windows")
                if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = keyWindow.rootViewController {
                    ITBDebug("Final fallback: Found root view controller in inactive scene keyWindow (iOS 13-14): \(String(describing: rootVC))")
                    return rootVC
                }
            }
        }
        
        ITBDebug("No root view controller found in any scene")
        return nil
    }
    
    static func trim(string: String) -> String {
        string.trimmingCharacters(in: .whitespaces)
    }
    
    static func isNullOrEmpty(string: String?) -> Bool {
        guard let string = string else {
            return true
        }
        
        return trim(string: string).isEmpty
    }
    
    static func isNotNullOrEmpty(string: String?) -> Bool {
        !isNullOrEmpty(string: string)
    }
    
    static func generateUUID() -> String {
        UUID().uuidString
    }
    
    /// int is milliseconds since epoch.
    static func date(fromInt int: Int) -> Date {
        let seconds = Double(int) / 1000.0 // ms -> seconds
        
        return Date(timeIntervalSince1970: seconds)
    }
    
    /// milliseconds since epoch.
    static func int(fromDate date: Date) -> Int {
        Int(date.timeIntervalSince1970 * 1000)
    }

    /// seconds since epoch.
    static func secondsFromEpoch(for date: Date) -> Int {
        Int(date.timeIntervalSince1970)
    }
    
    static func getEmailOrUserId() -> String? {
        let email = IterableAPI.email
        let userId = IterableAPI.userId
        if email != nil {
            return email
        } else if userId != nil {
            return userId
        }
        return nil
    }

    // given "var1", "val1", "var2", "val2" as input
    // this will return "var1: val1, var2: val2"
    // this is useful for description of an object or struct
    static func describe(_ values: Any..., pairSeparator: String = ": ", separator: String = ", ") -> String {
        values.take(2).map { pair in
            if pair.count == 0 {
                return ""
            } else if pair.count == 1 {
                return "\(pair[0])\(pairSeparator)nil"
            } else {
                return "\(pair[0])\(pairSeparator)\(pair[1])"
            }
        }.joined(separator: separator)
    }
    
    // MARK: Helper Utility Functions
    
    // converts from IterableURLDelegate to UrlHandler
    static func urlHandler(fromUrlDelegate urlDelegate: IterableURLDelegate?, inContext context: IterableActionContext) -> UrlHandler {
        { url in
            urlDelegate?.handle(iterableURL: url, inContext: context) == true
        }
    }
    
    // converts from IterableCustomActionDelegate to CustomActionHandler
    static func customActionHandler(fromCustomActionDelegate customActionDelegate: IterableCustomActionDelegate?, inContext context: IterableActionContext) -> CustomActionHandler {
        { _ in
            guard let customActionDelegate = customActionDelegate else {
                return false
            }
            
            _ = customActionDelegate.handle(iterableCustomAction: context.action, inContext: context)
            
            return true
        }
    }
}
