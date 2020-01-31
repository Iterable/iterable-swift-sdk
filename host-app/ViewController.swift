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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .handleIterableUrl, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .handleIterableCustomAction, object: nil)
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
        InAppHelper.showIterableNotificationHTML(html) { (url) in
            guard let url = url else {
                ITBError("Could not find url")
                return
            }
            ITBInfo("callback: \(url)")
            self.statusLbl.text = url.absoluteString
        }
    }
    
    // Full screen inApp
    @IBAction func showInApp2Tap(_ sender: UIButton) {
        ITBInfo()
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        let payload = ["inAppMessages" : [[
            "content" : ["html" : "<a href='https://www.google.com/q=something'>Click Here</a>"],
            "messageId" : "messageId",
            "campaignId" : "campaignId"]]
        ]
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         inAppSynchronizer: mockInAppSynchronizer,
                                         inAppDisplayer: InAppDisplayer())

        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        let message = IterableAPI.inAppManager.getMessages()[0]

        IterableAPI.inAppManager.show(message: message, consume: true) { (url) in
            self.statusLbl.text = url!.absoluteString
        }
    }

    // Center
    @IBAction func showInApp3Tap(_ sender: UIButton) {
        ITBInfo()

        let mockInAppSynchronizer = MockInAppSynchronizer()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        let payload = ["inAppMessages" : [[
            "content" : [
                "html" : "<body style='height:100px'><a href='https://www.google.com/q=something'>Click Here</a></body><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>",
                "inAppDisplaySettings" : ["backgroundAlpha" : 0.5, "left" : ["percentage" : 60], "right" : ["percentage" : 60], "bottom" : ["displayOption" : "AutoExpand"], "top" : ["displayOption" : "AutoExpand"]]
            ],
            "messageId" : "messageId",
            "campaignId" : "campaignId",
            ]]
        ]
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         inAppSynchronizer: mockInAppSynchronizer,
                                         inAppDisplayer: InAppDisplayer())
        
        mockInAppSynchronizer.mockInAppPayloadFromServer(payload)
        let message = IterableAPI.inAppManager.getMessages()[0]
        
        IterableAPI.inAppManager.show(message: message, consume: true) { (url) in
            self.statusLbl.text = url!.absoluteString
        }
    }

    // FullScreen, corresponds to UITests.testShowInApp4
    // Here UrlDelegate returns true, so url should not be opened
    @IBAction func showInApp4Tap(_ sender: UIButton) {
        ITBInfo()
       
        let messageId = "zeeMessageId"
        let html = """
            <a href="http://website/resource#something">Click Me</a>
        """
        let content = IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: html)
        let message = IterableInAppMessage(messageId: messageId, campaignId: "zeeCampaignId", content: content)
        
        let config = IterableConfig()
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = {(url, context) in
            if context.source == .inApp {
                self.statusLbl.text = url.absoluteString
            }
        }
        config.urlDelegate = mockUrlDelegate
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                               config: config,
                               inAppSynchronizer: mockInAppSynchronizer,
                               inAppDisplayer: InAppDisplayer()
                               )
        
        mockInAppSynchronizer.mockMessagesAvailableFromServer(messages: [message])
    }

    // Center and Open url, corresponds to UITests.testShowInApp5
    // Here UrlDelegate return false, so url should be opened.
    @IBAction func showInApp5Tap(_ sender: UIButton) {
        ITBInfo()
        
        let messageId = "zeeMessageId"
        let html = """
            <body style='height:100px'>
            <a href="http://website/resource#something">Click Me</a>
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
            </body>
        """
        let content = IterableHtmlInAppContent(edgeInsets: UIEdgeInsets(top: -1, left: 10, bottom: -1, right: 10), backgroundAlpha: 0.5, html: html)
        let message = IterableInAppMessage(messageId: messageId, campaignId: "zeeCampaignId", content: content)
        
        let config = IterableConfig()
        let mockUrlDelegate = MockUrlDelegate(returnValue: false) // we don't handle, so the url will be opened
        config.urlDelegate = mockUrlDelegate
        
        let mockUrlOpener = MockUrlOpener() { (url) in
            self.statusLbl.text = url.absoluteString
        }
        
        let mockInAppSynchronizer = MockInAppSynchronizer()
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                               config: config,
                               networkSession: MockNetworkSession(),
                               inAppSynchronizer: mockInAppSynchronizer,
                               inAppDisplayer: InAppDisplayer(),
                               urlOpener: mockUrlOpener)
        
        mockInAppSynchronizer.mockMessagesAvailableFromServer(messages: [message])
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
        let uniqueUrl = "https://www.myuniqueurl.com"
        let customActionName = "MyUniqueCustomAction"
        
        let userInfo = [
            "itbl": [
                "campaignId" : 1234,
                "templateId" : 4321,
                "isGhostPush" : false,
                "messageId" : messageId,
                "actionButtons" : [
                    [
                        "identifier" : "Open Safari",
                        "buttonType" : "default",
                        "action" : [
                            "type" : "openUrl",
                            "data" : "https://www.google.com"
                        ],
                    ],
                    [
                        "identifier" : "Open Deeplink",
                        "buttonType" : "default",
                        "action" : [
                            "type" : "openUrl",
                            "data" : uniqueUrl,
                        ],
                    ],
                    [
                        "identifier" : "Custom Action",
                        "buttonType" : "default",
                        "action" : [
                            "type" : customActionName,
                        ],
                    ],
                ]
            ]
        ]
        content.userInfo = userInfo

        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    @available(iOS 10.0, *)
    private func registerCategories() {
        ITBInfo()
        let tapButton1Action = UNNotificationAction(identifier: "Open Safari", title: "Open Safari", options: .foreground)
        let tapButton2Action = UNNotificationAction(identifier: "Open Deeplink", title: "Open Deeplink", options: .foreground)
        let tapButton3Action = UNNotificationAction(identifier: "Custom Action", title: "Custom Action", options: .foreground)

        let category = UNNotificationCategory(identifier: "addButtonsCategory", actions: [tapButton1Action, tapButton2Action, tapButton3Action], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    @objc private func handleNotification(_ notification: NSNotification) {
        ITBInfo()
        switch notification.name {
        case .handleIterableUrl:
            if let userInfo = notification.userInfo {
                if let url = userInfo["url"] as? String {
                    statusLbl.text = url
                }
            }
            break
        case .handleIterableCustomAction:
            if let userInfo = notification.userInfo {
                if let customActionName = userInfo["name"] as? String {
                    statusLbl.text = customActionName
                }
            }
            break
        default:
            break
        }
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

