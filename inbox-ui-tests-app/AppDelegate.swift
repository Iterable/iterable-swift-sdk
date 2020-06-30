//
//  Created by Tapash Majumder on 8/27/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit
import UserNotifications

@testable import IterableSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var sharedInstance: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
    
    var window: UIWindow?
    var mockInAppFetcher: MockInAppFetcher!
    var mockNetworkSession: MockNetworkSession!
    var networkTableViewController: NetworkTableViewController {
        let tabBarController = window!.rootViewController! as! UITabBarController
        let nav = tabBarController.viewControllers![tabBarController.viewControllers!.count - 1] as! UINavigationController
        return nav.viewControllers[0] as! NetworkTableViewController
    }
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        mockInAppFetcher = MockInAppFetcher()
        mockNetworkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: createUrlToDataMapper())
        mockNetworkSession.callback = { _, _, _ in
            self.logRequest()
        }
        
        let config = IterableConfig()
        config.customActionDelegate = self
        config.urlDelegate = self
        TestHelper.getTestUserDefaults().set("user1@example.com", forKey: Const.UserDefaults.emailKey)
        
        IterableAPI.initializeForTesting(config: config,
                                         networkSession: mockNetworkSession,
                                         inAppFetcher: mockInAppFetcher,
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
    
    func loadDataset(number: Int) {
        let messages = loadMessages(from: "inbox-messages-\(number)", withExtension: "json")
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: IterableAPI.internalImplementation, messages: messages)
    }
    
    func addInboxMessage() {
        ITBInfo()
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: IterableAPI.internalImplementation, messages: mockInAppFetcher.messages + [createNewMessage()])
    }
    
    func addMessageToServer() {
        // mocks message added to server but not client since no sync has happened yet
        mockInAppFetcher.add(message: createNewMessage())
    }
    
    private func createNewMessage() -> IterableInAppMessage {
        let html = """
        <body bgColor="#FFF">
            <div style="width:100px;height:100px;position:absolute;margin:auto;top:0;bottom:0;left:0;right:0;"><a href="iterable://delete">Delete</a></div>
        </body>
        """
        let id = IterableUtil.generateUUID()
        return IterableInAppMessage(messageId: "message-\(id)",
                                    campaignId: TestHelper.generateIntGuid() as NSNumber,
                                    trigger: IterableInAppTrigger.neverTrigger,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 1.0, html: html),
                                    saveToInbox: true,
                                    inboxMetadata: IterableInboxMetadata(title: "title-\(id)", subtitle: "subTitle-\(id)"))
    }
    
    private func logRequest() {
        let request = mockNetworkSession.request!
        let serializableRequest = request.createSerializableRequest()
        networkTableViewController.requests.append(serializableRequest)
        networkTableViewController.tableView.reloadData()
    }
    
    private func loadMessages(from file: String, withExtension extension: String) -> [IterableInAppMessage] {
        let data = loadData(from: file, withExtension: `extension`)
        let payload = try! JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
        return InAppTestHelper.inAppMessages(fromPayload: payload)
    }
    
    private func loadData(from file: String, withExtension extension: String) -> Data {
        let path = Bundle(for: type(of: self)).path(forResource: file, ofType: `extension`)!
        return FileManager.default.contents(atPath: path)!
    }
    
    private func createUrlToDataMapper() -> [String: Data?] {
        var mapper = [String: Data?]()
        mapper[#"mocha.png"#] = loadData(from: "mocha", withExtension: "png")
        mapper[".*"] = nil
        return mapper
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
