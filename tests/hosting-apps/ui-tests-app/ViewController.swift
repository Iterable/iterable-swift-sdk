//
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
    
    @IBAction func setupNotifications(_: UIButton) {
        ITBInfo()
        setupNotifications()
    }
    
    @IBAction func sendNotification(_: UIButton) {
        ITBInfo()
        setupAndSendNotification()
    }
    
    @IBAction func showInAppTap(_: UIButton) {
        ITBInfo()
        
        let html = """
            <a href="http://website/resource#something">Click Me</a>
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
        """
        InAppDisplayer.showIterableHtmlMessage(html) { url in
            ITBInfo("callback: \(url)")
            self.statusLbl.text = url.absoluteString
        }
    }
    
    // Full screen in-app
    @IBAction func showInApp2Tap(_: UIButton) {
        ITBInfo()
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        let payload = ["inAppMessages": [[
            "content": ["html": "<a href='https://www.google.com/q=something'>Click Here</a>"],
            "messageId": "messageId-1",
            "campaignId": 1,
        ] as [String : Any]]]
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         inAppFetcher: mockInAppFetcher,
                                         inAppDisplayer: InAppDisplayer())
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: IterableAPI.implementation, payload).onSuccess { _ in
            let message = IterableAPI.inAppManager.getMessages()[0]
            
            IterableAPI.inAppManager.show(message: message, consume: true) { url in
                self.statusLbl.text = url!.absoluteString
            }
        }
    }
    
    // Center
    @IBAction func showInApp3Tap(_: UIButton) {
        ITBInfo()
        
        let mockInAppFetcher = MockInAppFetcher()
        let mockInAppDelegate = MockInAppDelegate(showInApp: .skip)
        let config = IterableConfig()
        config.inAppDelegate = mockInAppDelegate
        let payload = ["inAppMessages": [[
            "content": [
                "html": "<body style='height:100px'><a href='https://www.google.com/q=something'>Click Here</a></body><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>",
                "inAppDisplaySettings": ["backgroundAlpha": 0.5, "left": ["percentage": 60], "right": ["percentage": 60], "bottom": ["displayOption": "AutoExpand"], "top": ["displayOption": "AutoExpand"]] as [String : Any],
            ] as [String : Any],
            "messageId": "messageId-1",
            "campaignId": 1,
        ] as [String : Any]]]
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         inAppFetcher: mockInAppFetcher,
                                         inAppDisplayer: InAppDisplayer())
        
        mockInAppFetcher.mockInAppPayloadFromServer(internalApi: IterableAPI.implementation, payload).onSuccess { _ in
            let message = IterableAPI.inAppManager.getMessages()[0]
            
            IterableAPI.inAppManager.show(message: message, consume: true) { url in
                self.statusLbl.text = url!.absoluteString
            }
        }
    }
    
    // FullScreen, corresponds to UITests.testShowInApp4
    // Here UrlDelegate returns true, so url should not be opened
    @IBAction func showInApp4Tap(_: UIButton) {
        ITBInfo()
        
        let messageId = "zeeMessageId"
        let html = """
            <a href="http://website/resource#something">Click Me</a>
        """
        let content = IterableHtmlInAppContent(edgeInsets: .zero, html: html)
        let message = IterableInAppMessage(messageId: messageId, campaignId: 1234, content: content)
        
        let config = IterableConfig()
        let mockUrlDelegate = MockUrlDelegate(returnValue: true)
        mockUrlDelegate.callback = { url, context in
            if context.source == .inApp {
                self.statusLbl.text = url.absoluteString
            }
        }
        config.urlDelegate = mockUrlDelegate
        
        let mockInAppFetcher = MockInAppFetcher()
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         inAppFetcher: mockInAppFetcher,
                                         inAppDisplayer: InAppDisplayer())
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: IterableAPI.implementation, messages: [message])
    }
    
    // Center and Open url, corresponds to UITests.testShowInApp5
    // Here UrlDelegate return false, so url should be opened.
    @IBAction func showInApp5Tap(_: UIButton) {
        ITBInfo()
        
        let messageId = "zeeMessageId"
        let html = """
            <body style='height:100px'>
            <a href="https://website/resource#something">Click Me</a>
            <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'>
            </body>
        """
        let padding = Padding(top: .autoExpand,
                              left: 10,
                              bottom: .autoExpand,
                              right: 10)
        let content = IterableHtmlInAppContent(edgeInsets: padding.toEdgeInsets(), html: html)
        let message = IterableInAppMessage(messageId: messageId, campaignId: 1234, content: content)
        
        let config = IterableConfig()
        let mockUrlDelegate = MockUrlDelegate(returnValue: false) // we don't handle, so the url will be opened
        config.urlDelegate = mockUrlDelegate
        
        let mockUrlOpener = MockUrlOpener { url in
            self.statusLbl.text = url.absoluteString
        }
        
        let mockInAppFetcher = MockInAppFetcher()
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         networkSession: MockNetworkSession(),
                                         inAppFetcher: mockInAppFetcher,
                                         inAppDisplayer: InAppDisplayer(),
                                         urlOpener: mockUrlOpener)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: IterableAPI.implementation, messages: [message])
    }
    
    @IBAction func showInboxTap(_: UIButton) {
        ITBInfo()
        
        let messageId = "zeeMessageId"
        let html = """
            <a href="http://website/resource#something">Click Me</a>
        """
        let padding = Padding(top: .autoExpand,
                              left: 10,
                              bottom: .autoExpand,
                              right: 10)
        let content = IterableHtmlInAppContent(edgeInsets: padding.toEdgeInsets(), html: html)
        let inboxMetadata = IterableInboxMetadata(title: "Title #1", subtitle: "Subtitle #1", icon: nil)
        let message = IterableInAppMessage(messageId: messageId, campaignId: 1234, trigger: IterableInAppTrigger(dict: ["type": "never"]), content: content, saveToInbox: true, inboxMetadata: inboxMetadata)
        
        let config = IterableConfig()
        let mockUrlDelegate = MockUrlDelegate(returnValue: false) // we don't handle, so the url will be opened
        config.urlDelegate = mockUrlDelegate
        
        let mockUrlOpener = MockUrlOpener { url in
            self.statusLbl.text = url.absoluteString
        }
        
        let mockInAppFetcher = MockInAppFetcher()
        IterableAPI.initializeForTesting(apiKey: "apiKey",
                                         config: config,
                                         inAppFetcher: mockInAppFetcher,
                                         inAppDisplayer: InAppDisplayer(),
                                         urlOpener: mockUrlOpener)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: IterableAPI.implementation, messages: [message]).onSuccess { _ in
            DispatchQueue.main.async {
                let viewController = IterableInboxViewController(style: .plain)
                self.present(viewController, animated: true) {
                    ITBInfo("Presented Inbox")
                }
            }
        }
    }
    
    private func setupNotifications(onCompletion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                ITBError("Not authorized, asking for permission")
                // not authorized, ask for permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
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
    
    private func setupAndSendNotification() {
        setupNotifications {
            self.registerCategories()
            self.sendNotification()
        }
    }
    
    private func removeAllNotifications() {
        ITBInfo()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
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
                "campaignId": 1234,
                "templateId": 4321,
                "isGhostPush": false,
                "messageId": messageId,
                "actionButtons": [
                    [
                        "identifier": "Open Safari",
                        "buttonType": "default",
                        "action": [
                            "type": "openUrl",
                            "data": "https://www.google.com",
                        ],
                    ],
                    [
                        "identifier": "Open Deeplink",
                        "buttonType": "default",
                        "action": [
                            "type": "openUrl",
                            "data": uniqueUrl,
                        ],
                    ],
                    [
                        "identifier": "Custom Action",
                        "buttonType": "default",
                        "action": [
                            "type": customActionName,
                        ],
                    ] as [String : Any],
                ],
            ] as [String : Any],
        ]
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
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
        case .handleIterableCustomAction:
            if let userInfo = notification.userInfo {
                if let customActionName = userInfo["name"] as? String {
                    statusLbl.text = customActionName
                }
            }
        default:
            break
        }
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}
