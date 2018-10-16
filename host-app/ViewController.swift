//
//  ViewController.swift
//  host-app
//
//  Created by Tapash Majumder on 6/27/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit
import UserNotifications

@testable import IterableSDK

class ViewController: UIViewController {
    @IBOutlet weak var statusLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func setupNotifications(_ sender: UIButton) {
        ITBInfo()
        if #available(iOS 10, *) {
            setupNotifications()
        }
    }

    @IBAction func sendNotification(_ sender: UIButton) {
        ITBInfo()
        if #available(iOS 10, *) {
            setupAndSendNotification()
        }
    }

    
    @IBAction func showSystemNotificationTap(_ sender: UIButton) {
        ITBInfo()
        
        IterableAPI.showSystemNotification(withTitle: "Zee Title", body: "Zee Body", buttonLeft: "Left Button", buttonRight: "Right Button") { (str) in
            self.statusLbl.text = str
        }
    }

    @IBAction func showSystemNotification2Tap(_ sender: UIButton) {
        ITBInfo()
        
        IterableAPI.showSystemNotification(withTitle: "Zee Title", body: "Zee Body", button: "Zee Button") { (str) in
            self.statusLbl.text = str
        }
    }

    @IBAction func showInAppTap(_ sender: UIButton) {
        ITBInfo()
        
        let html = """
            <a href="http://website/resource#something">Click Me</a>
        """
        IterableInAppManager.showIterableNotificationHTML(html) { (str) in
            ITBInfo("callback: \(str ?? "<nil>")")
            self.statusLbl.text = str
        }
        
        IterableInAppManager.showIterableNotificationHTML(html, callbackBlock: {str in print("callback: ", str ?? "nil")})
    }
    
    // Full screen inApp
    @IBAction func showInApp2Tap(_ sender: UIButton) {
        ITBInfo()
        
        let networkSession = MockNetworkSession(
            statusCode: 200,
            json: ["inAppMessages" : [[
                "content" : ["html" : "<a href='https://www.google.com/q=something'>Click Here</a>"],
                "messageId" : "messageId",
                "campaignId" : "campaignId"] ]])
        IterableAPI.initialize(apiKey: "apiKey",
                               networkSession: networkSession)
        
        networkSession.callback = {(_, _, _) in
            networkSession.data = [:].toData()
        }

        IterableAPI.spawnInAppNotification { (str) in
            ITBInfo("callback: \(str ?? "<nil>")")
            self.statusLbl.text = str
        }
    }

    
    @IBAction func showInApp3Tap(_ sender: UIButton) {
        ITBInfo()
        
        // In app with Center display
        // with left and right padding > 100
        let networkSession = MockNetworkSession(
            statusCode: 200,
            json: ["inAppMessages" : [[
                "content" : [
                    "html" : "<a href='https://www.google.com/q=something'>Click Here</a>",
                    "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]]
                ],
                "messageId" : "messageId",
                "campaignId" : "campaignId",
                ]
            ]])
        IterableAPI.initialize(apiKey: "apiKey",
                               networkSession: networkSession)
        
        networkSession.callback = {(_, _, _) in
            networkSession.data = [:].toData()
        }
        
        IterableAPI.spawnInAppNotification { (str) in
            ITBInfo("callback: \(str ?? "<nil>")")
            self.statusLbl.text = str
        }
    }

    @available(iOS 10.0, *)
    private func setupNotifications(onCompletion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                ITBError("Not authorized, asking for permission")
                // not authorized, ask for permission
                UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .badge, .sound]) { (success, error) in
                    if success {
                        ITBInfo("Permission Granted")
                        onCompletion?()
                    } else {
                        ITBError("Permission Denied")
                    }
                }
            } else {
                // already authorized
                ITBInfo("Already authorized")
                onCompletion?()
            }
        }
    }

    @available(iOS 10.0, *)
    private func setupAndSendNotification() {
        setupNotifications {
            self.registerCategories()
            self.sendNotification()
        }
    }
    
    @available(iOS 10.0, *)
    private func removeAllNotifications() {
        ITBInfo()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    @available(iOS 10.0, *)
    private func sendNotification() {
        ITBInfo()
        
        removeAllNotifications()
        
        // create a corresponding local notification
        let content = UNMutableNotificationContent()
        
        content.categoryIdentifier = "addButtonsCategory"
        content.title = "Select"
        content.body = "Select an action"
        content.badge = NSNumber(value: 1)

        let messageId = UUID().uuidString
        
        let userInfo = [
            "itbl": [
                "campaignId" : 1234,
                "templateId" : 4321,
                "isGhostPush" : false,
                "messageId" : messageId,
                "actionButtons" : [[
                    "identifier" : "Open Google",
                    "buttonType" : "default",
                    "action" : [
                        "type" : "openUrl",
                        "data" : "https://www.google.com"
                    ]]
                ]
            ]
        ]
        content.userInfo = userInfo

        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false) // 10 seconds from now
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    @available(iOS 10.0, *)
    private func registerCategories() {
        ITBInfo()
        let tapButton1Action = UNNotificationAction(identifier: "Open Google", title: "Open Google", options: .foreground)
        let tapButton2Action = UNNotificationAction(identifier: "Button2", title: "Tap Button 2", options: .destructive)

        let category = UNNotificationCategory(identifier: "addButtonsCategory", actions: [tapButton1Action, tapButton2Action], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
}

@available(iOS 10.0, *)
extension ViewController : UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}

