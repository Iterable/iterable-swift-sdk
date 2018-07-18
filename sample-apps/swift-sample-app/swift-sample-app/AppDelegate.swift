//
//  AppDelegate.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 6/13/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit
import UserNotifications

import IterableSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        //ITBL: Setup Notification
        setupNotifications()

        //ITBL: Initialize API
        // NOTE: In your application you should hard-code your Iterable API Key. No need to
        // save in UserDefaults
        if let iterableApiKey = UserDefaults.standard.string(forKey: "iterableApiKey") {
            // You code sould always come here in your actual application
            let config = IterableConfig()
            config.customActionDelegate = self
            config.urlDelegate = self
            config.pushIntegrationName = "swift-sample-app"
            config.sandboxPushIntegrationName = "swift-sample-app"
            // Replace with your api key and email here.
            IterableAPI.initialize(apiKey: iterableApiKey,
                                   launchOptions:launchOptions,
                                   config: config)
        } else {
            // Your code should never come here in your actual application
            // For this sample app we don't know the Iterable API Key that's why we have it here.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let apiKeyVC = storyboard.instantiateViewController(withIdentifier: "APIKeyViewController")
            window?.rootViewController = apiKeyVC
        }

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: Deep link
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let url = userActivity.webpageURL else {
            return false
        }

        //ITBL:
        return IterableAPI.handle(universalLink: url)
    }
    
    //MARK: Notification
    //ITBL:
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        IterableAPI.register(token: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    //ITBL:
    // Ask for permission for notifications etc.
    // setup self as delegate to listen to push notifications.
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // not authorized, ask for permission
                UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .badge, .sound]) { (success, error) in
                    if success == true {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                    //TODO: Handle error etc.
                }
            } else {
                // already authorized
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

//MARK: UNUserNotificationCenterDelegate
extension AppDelegate : UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        //ITBL:
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}

//MARK: IterableURLDelegate
extension AppDelegate : IterableURLDelegate {
    // return true if we handled the url
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        return DeeplinkHandler.handle(url: url)
    }
}

//Mark: IterableCustomActionDelegate
extension AppDelegate : IterableCustomActionDelegate {
    // handle the cutom action from push
    // return value true/false doesn't matter here, stored for future use
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        if action.type == "handleFindCoffee" {
            if let query = action.userInput {
                return DeeplinkHandler.handle(url: URL(string: "https://majumder.me/coffee?q=\(query)")!)
            }
        }
        return false
    }
}
