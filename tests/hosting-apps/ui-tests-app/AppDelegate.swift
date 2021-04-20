//
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit
import UserNotifications

@testable import IterableSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let config = IterableConfig()
        config.customActionDelegate = self
        config.urlDelegate = self
        let localStorage = MockLocalStorage()
        localStorage.email = "user1@example.com"
        IterableAPI.initializeForTesting(config: config,
                                         networkSession: MockNetworkSession(),
                                         localStorage: localStorage,
                                         urlOpener: AppUrlOpener())
        
        return true
    }
    
    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate: IterableCustomActionDelegate {
    func handle(iterableCustomAction action: IterableAction, inContext _: IterableActionContext) -> Bool {
        ITBInfo("handleCustomAction: \(action)")
        NotificationCenter.default.post(name: .handleIterableCustomAction, object: nil, userInfo: ["name": action.type])
        return true
    }
}

extension AppDelegate: IterableURLDelegate {
    func handle(iterableURL url: URL, inContext _: IterableActionContext) -> Bool {
        ITBInfo("handleUrl: \(url)")
        if url.absoluteString == "https://www.google.com" {
            // I am not going to handle this, do default
            return false
        } else {
            // I am handling this
            NotificationCenter.default.post(name: .handleIterableUrl, object: nil, userInfo: ["url": url.absoluteString])
            return true
        }
    }
}

extension Notification.Name {
    static let handleIterableUrl = Notification.Name("handleIterableUrl")
    static let handleIterableCustomAction = Notification.Name("handleIterableCustomAction")
}
