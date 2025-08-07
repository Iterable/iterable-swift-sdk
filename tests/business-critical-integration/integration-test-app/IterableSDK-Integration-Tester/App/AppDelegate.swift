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
    
    // ITBL: Load API key from test config file
    let iterableApiKey: String = {
        guard let configApiKey = loadApiKeyFromConfig() else {
            fatalError("❌ Required test-config.json file not found or missing mobileApiKey")
        }
        return configApiKey
    }()
    
    private static func loadApiKeyFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiKey = json["mobileApiKey"] as? String,
              !apiKey.isEmpty else {
            print("❌ Could not load API key from test-config.json")
            return nil
        }
        print("✅ Loaded API key from test-config.json")
        return apiKey
    }
    
    private static func loadTestUserEmailFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["testUserEmail"] as? String,
              !email.isEmpty else {
            print("❌ Could not load test user email from test-config.json")
            return nil
        }
        print("✅ Loaded test user email from test-config.json")
        return email
    }
    
    private func setupTestModeUI() {
        // Add visual indicator that we're always in test mode
        DispatchQueue.main.async {
            if let window = self.window {
                let testBanner = UIView()
                testBanner.backgroundColor = UIColor.systemYellow
                testBanner.translatesAutoresizingMaskIntoConstraints = false

                let testLabel = UILabel()
                testLabel.text = "🧪 INTEGRATION TEST APP 🧪"
                testLabel.textAlignment = .center
                testLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                testLabel.translatesAutoresizingMaskIntoConstraints = false

                testBanner.addSubview(testLabel)
                window.addSubview(testBanner)

                NSLayoutConstraint.activate([
                    testBanner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    testBanner.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    testBanner.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                    testBanner.heightAnchor.constraint(equalToConstant: 30),

                    testLabel.centerXAnchor.constraint(equalTo: testBanner.centerXAnchor),
                    testLabel.centerYAnchor.constraint(equalTo: testBanner.centerYAnchor)
                ])

                window.bringSubviewToFront(testBanner)
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // ITBL: Setup Notification
        setupNotifications()
        
        // ITBL: Initialize API
        let config = IterableConfig()
        config.customActionDelegate = self
        config.urlDelegate = self
        config.inAppDisplayInterval = 1
        
        IterableAPI.initialize(apiKey: iterableApiKey,
                               launchOptions: launchOptions,
                               config: config)
        
        // Set user email from test config
        guard let email = AppDelegate.loadTestUserEmailFromConfig() else {
            fatalError("❌ Required test-config.json file not found or missing testUserEmail")
        }
        IterableAPI.email = email
        print("✅ Configured test user email: \(email)")
        
        // Setup test mode indicators
        setupTestModeUI()
        
        enhancedApplicationDidFinishLaunching(application, launchOptions: launchOptions)
        
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
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // App is always in test mode - no validation needed
        enhancedApplicationDidBecomeActive(application)
    }
    
    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: Silent Push for in-app
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        enhancedDidReceiveRemoteNotification(application, userInfo: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    // MARK: Deep link
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return enhancedContinueUserActivity(application, userActivity: userActivity, restorationHandler: restorationHandler)
    }
    
    // MARK: Notification
    
    // ITBL:
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        enhancedDidRegisterForRemoteNotifications(application, deviceToken: deviceToken)
    }
    
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}
    
    // ITBL:
    // Ask for permission for notifications etc.
    // setup self as delegate to listen to push notifications.
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                // not authorized, ask for permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
                    if success {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                    // TODO: Handle error etc.
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

// MARK: UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // ITBL:
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}

// MARK: IterableURLDelegate

extension AppDelegate: IterableURLDelegate {
    // return true if we handled the url
    func handle(iterableURL url: URL, inContext _: IterableActionContext) -> Bool {
        DeepLinkHandler.handle(url: url)
    }
}

// MARK: IterableCustomActionDelegate

extension AppDelegate: IterableCustomActionDelegate {
    // handle the cutom action from push
    // return value true/false doesn't matter here, stored for future use
    func handle(iterableCustomAction action: IterableAction, inContext _: IterableActionContext) -> Bool {
        if action.type == "handleFindCoffee" {
            if let query = action.userInput {
                return DeepLinkHandler.handle(url: URL(string: "https://example.com/coffee?q=\(query)")!)
            }
        }
        return false
    }
}
