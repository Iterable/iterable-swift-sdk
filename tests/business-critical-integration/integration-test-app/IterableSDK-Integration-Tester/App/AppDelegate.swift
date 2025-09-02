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
    
    private func setupTestModeUI() {
        // Add visual indicator that we're always in integration test mode
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
                testLabel.accessibilityIdentifier = "app-ready-indicator"

                let networkButton = UIButton(type: .system)
                networkButton.setTitle("📡 Network", for: .normal)
                networkButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
                networkButton.backgroundColor = UIColor.systemBlue
                networkButton.setTitleColor(.white, for: .normal)
                networkButton.layer.cornerRadius = 8
                networkButton.translatesAutoresizingMaskIntoConstraints = false
                networkButton.accessibilityIdentifier = "network-monitor-button"
                networkButton.addTarget(self, action: #selector(self.showNetworkMonitor), for: .touchUpInside)

                let backendButton = UIButton(type: .system)
                backendButton.setTitle("⚙️ Backend", for: .normal)
                backendButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
                backendButton.backgroundColor = UIColor.systemPurple
                backendButton.setTitleColor(.white, for: .normal)
                backendButton.layer.cornerRadius = 8
                backendButton.translatesAutoresizingMaskIntoConstraints = false
                backendButton.accessibilityIdentifier = "backend-tab"
                backendButton.addTarget(self, action: #selector(self.showBackendStatus), for: .touchUpInside)

                testBanner.addSubview(testLabel)
                testBanner.addSubview(networkButton)
                testBanner.addSubview(backendButton)
                window.addSubview(testBanner)

                NSLayoutConstraint.activate([
                    testBanner.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                    testBanner.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                    testBanner.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                    testBanner.heightAnchor.constraint(equalToConstant: 40),

                    testLabel.centerXAnchor.constraint(equalTo: testBanner.centerXAnchor),
                    testLabel.centerYAnchor.constraint(equalTo: testBanner.centerYAnchor),

                    networkButton.trailingAnchor.constraint(equalTo: testBanner.trailingAnchor, constant: -20),
                    networkButton.centerYAnchor.constraint(equalTo: testBanner.centerYAnchor),
                    networkButton.widthAnchor.constraint(equalToConstant: 100),
                    networkButton.heightAnchor.constraint(equalToConstant: 28),
                    
                    backendButton.leadingAnchor.constraint(equalTo: testBanner.leadingAnchor, constant: 20),
                    backendButton.centerYAnchor.constraint(equalTo: testBanner.centerYAnchor),
                    backendButton.widthAnchor.constraint(equalToConstant: 100),
                    backendButton.heightAnchor.constraint(equalToConstant: 28)
                ])

                window.bringSubviewToFront(testBanner)
            }
        }
    }
    
    @objc private func showNetworkMonitor() {
        guard let rootViewController = window?.rootViewController else { return }
        
        let networkMonitorVC = NetworkMonitorViewController()
        let navController = UINavigationController(rootViewController: networkMonitorVC)
        navController.modalPresentationStyle = .fullScreen
        
        rootViewController.present(navController, animated: true)
    }
    
    @objc private func showBackendStatus() {
        guard let rootViewController = window?.rootViewController else { return }
        
        let backendStatusVC = BackendStatusViewController()
        let navController = UINavigationController(rootViewController: backendStatusVC)
        navController.modalPresentationStyle = .fullScreen
        
        rootViewController.present(navController, animated: true)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Create window and set root to HomeViewController programmatically for a clean test UI
        window = UIWindow(frame: UIScreen.main.bounds)
        let root = UINavigationController(rootViewController: HomeViewController())
        window?.rootViewController = root
        window?.makeKeyAndVisible()

        setupNotifications()
        setupTestModeUI()
        
        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
        
        // Reset device token session state on app launch for clean testing
        AppDelegate.resetDeviceTokenSessionState()

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
        print("🚀 BREAKPOINT HERE: App became active")
        // Set a breakpoint here to confirm app is opening
        
        // App is always in test mode - no validation needed
    }
    
    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: Silent Push for in-app
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔕 [APP] Silent push notification received")
        print("🔕 [APP] Silent push payload: \(userInfo)")
        
        // Log Iterable-specific data if present
        if let iterableData = userInfo["itbl"] as? [String: Any] {
            print("🔕 [APP] Iterable-specific data in silent push: \(iterableData)")
            
            if let isGhostPush = iterableData["isGhostPush"] as? Bool {
                print("👻 [APP] Ghost push flag: \(isGhostPush)")
            }
        }
        
        // Call completion handler
        completionHandler(.newData)
    }
    
    // MARK: Deep link
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return false // No deep link handling in this test app
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("🔗 App opened via direct deep link: \(url.absoluteString)")
        
        if url.scheme == "tester" {
            print("✅ Direct deep link opened - tester:// (will be handled by Iterable SDK)")
            return true
        }
        
        return false
    }
    
    private func showDeepLinkAlert(url: URL) {
        guard let rootViewController = window?.rootViewController else { return }
        
        let alert = UIAlertController(
            title: "Iterable Deep Link Opened", 
            message: "🔗 App was opened via Iterable SDK deep link:\n\(url.absoluteString)", 
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Find the topmost presented view controller
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        topViewController.present(alert, animated: true)
    }
    
    // MARK: Notification
    
    // ITBL:
    func application(_ applicatiTon: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Register the device token with Iterable SDK and save it
        print("Received device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        AppDelegate.registerDeviceToken(deviceToken)
    }
    
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}
    
    // ITBL:
    // Setup self as delegate to listen to push notifications.
    // Note: This only sets up the delegate, doesn't request permissions automatically
    private func setupNotifications() {
        print("🔔 Setting up notification delegate")
        UNUserNotificationCenter.current().delegate = self
        print("🔔 Notification delegate set to: \(String(describing: UNUserNotificationCenter.current().delegate))")
    }
}

// MARK: UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 [APP] Push notification received while app is in foreground")
        print("🔔 [APP] Notification payload: \(notification.request.content.userInfo)")
        print("🔔 [APP] Notification title: \(notification.request.content.title)")
        print("🔔 [APP] Notification body: \(notification.request.content.body)")
        
        if let iterableData = notification.request.content.userInfo["itbl"] as? [String: Any] {
            print("🔔 [APP] Iterable-specific data: \(iterableData)")
        }
        
        completionHandler([.alert, .badge, .sound])
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 [APP] Push notification tapped - processing with Iterable SDK")
        print("🔔 [APP] Full notification payload: \(response.notification.request.content.userInfo)")
        print("🔔 [APP] Notification title: \(response.notification.request.content.title)")
        print("🔔 [APP] Notification body: \(response.notification.request.content.body)")
        
        // Set a breakpoint on the next line to see when push notifications are tapped
        let actionIdentifier = response.actionIdentifier
        print("🔔 [APP] Action identifier: \(actionIdentifier)")
        
        // Log Iterable-specific data if present
        if let iterableData = response.notification.request.content.userInfo["itbl"] as? [String: Any] {
            print("🔔 [APP] Iterable-specific data: \(iterableData)")
            
            if let deepLinkURL = iterableData["deepLinkURL"] as? String {
                print("🔗 [APP] Deep link URL found in payload: \(deepLinkURL)")
            }
            
            if let campaignId = iterableData["campaignId"] {
                print("📊 [APP] Campaign ID: \(campaignId)")
            }
        }
        
        // Log APS data
        if let apsData = response.notification.request.content.userInfo["aps"] as? [String: Any] {
            print("🍎 [APP] APS data: \(apsData)")
        }
        
        // ITBL: This should process the notification and trigger deep link handling
        print("🔔 About to call IterableAppIntegration.userNotificationCenter")
        print("🔔 IterableAPI.email: \(IterableAPI.email ?? "nil")")
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        print("🔔 IterableAppIntegration.userNotificationCenter completed")
    }
}

// MARK: IterableURLDelegate

extension AppDelegate: IterableURLDelegate {
    // return true if we handled the url
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        print("🔗 BREAKPOINT HERE: IterableURLDelegate.handle called!")
        print("🔗 URL: \(url.absoluteString)")
        print("🔗 Context: \(context)")
        
        // Set a breakpoint on the next line to see if this method gets called
        let urlScheme = url.scheme ?? "no-scheme"
        print("🔗 URL scheme: \(urlScheme)")
        
        if url.scheme == "tester" {
            print("✅ App is opened via Iterable deep link - tester://")
            
            // Show alert that app was opened via deep link
            DispatchQueue.main.async {
                self.showDeepLinkAlert(url: url)
            }
            
            // Post notification that the app was opened via deep link
            NotificationCenter.default.post(name: NSNotification.Name("AppOpenedViaDeepLink"), object: url)
            
            return true // We handled this URL
        }
        
        print("🔗 URL scheme '\(url.scheme ?? "nil")' not handled by our app")
        return false // We didn't handle this URL
    }
}

// MARK: IterableCustomActionDelegate

extension AppDelegate: IterableCustomActionDelegate {
    // handle the cutom action from push
    // return value true/false doesn't matter here, stored for future use
    func handle(iterableCustomAction action: IterableAction, inContext _: IterableActionContext) -> Bool {
        if action.type == "handleFindCoffee" {
            if let query = action.userInput {
                return false
                //return //DeepLinkHandler.handle(url: URL(string: "https://example.com/coffee?q=\(query)")!)
            }
        }
        return false
    }
    
    // MARK: - Test Network Monitoring
}
