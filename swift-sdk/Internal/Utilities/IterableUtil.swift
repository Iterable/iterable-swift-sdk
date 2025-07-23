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
        guard let application = AppExtensionHelper.application else { return nil }
        
        // Find active scenes (foreground active takes priority)
        let activeScenes = application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        
        // Look for key window in active scenes first
        for scene in activeScenes {
            if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }),
               let rootVC = keyWindow.rootViewController {
                return rootVC
            }
        }
        
        // Fallback to first window in first active scene
        if let firstActiveScene = activeScenes.first,
           let rootVC = firstActiveScene.windows.first?.rootViewController {
            return rootVC
        }
        
        // Final fallback: any foreground inactive scene with key window
        let inactiveScenes = application.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundInactive }
        
        for scene in inactiveScenes {
            if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }),
               let rootVC = keyWindow.rootViewController {
                return rootVC
            }
        }
        
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

    @available(iOS 13.0, *)
    private static func getActiveWindowRootViewController() -> UIViewController? {
        guard let application = AppExtensionHelper.application else { return nil }
        
        // Prioritize foregroundActive scenes for Stage Manager and multi-window scenarios
        for scene in application.connectedScenes {
            guard let windowScene = scene as? UIWindowScene,
                  windowScene.activationState == .foregroundActive else { continue }
            
            // Filter for visible, normal-level windows with valid rootViewControllers
            let visibleWindows = windowScene.windows.filter { 
                $0.isHidden == false && 
                $0.windowLevel == .normal &&
                $0.rootViewController != nil
            }
            
            // Try keyWindow first if available (iOS 15+) and in our visible set
            if #available(iOS 15.0, *) {
                if let keyWindow = windowScene.keyWindow,
                   visibleWindows.contains(keyWindow) {
                    return keyWindow.rootViewController
                }
            }
            
            // For iOS 13-14, find keyWindow manually in visible windows
            for window in visibleWindows {
                if window.isKeyWindow {
                    return window.rootViewController
                }
            }
            
            // Fallback to first visible, normal window
            if let firstVisibleWindow = visibleWindows.first {
                return firstVisibleWindow.rootViewController
            }
        }
        
        // Secondary fallback: any foregroundInactive scene (Stage Manager background)
        for scene in application.connectedScenes {
            guard let windowScene = scene as? UIWindowScene,
                  windowScene.activationState == .foregroundInactive else { continue }
            
            let visibleWindows = windowScene.windows.filter { 
                $0.isHidden == false && 
                $0.windowLevel == .normal &&
                $0.rootViewController != nil
            }
            
            if #available(iOS 15.0, *) {
                if let keyWindow = windowScene.keyWindow,
                   visibleWindows.contains(keyWindow) {
                    return keyWindow.rootViewController
                }
            }
            
            for window in visibleWindows {
                if window.isKeyWindow {
                    return window.rootViewController
                }
            }
            
            if let firstVisibleWindow = visibleWindows.first {
                return firstVisibleWindow.rootViewController
            }
        }
        
        return nil
    }
}
