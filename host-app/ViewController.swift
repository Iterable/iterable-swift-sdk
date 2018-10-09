//
//  ViewController.swift
//  host-app
//
//  Created by Tapash Majumder on 6/27/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

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

    @IBAction func showSystemNotificationTap(_ sender: UIButton) {
        ITBInfo()
        
        IterableAPI.showSystemNotification(withTitle: "Zee Title", body: "Zee Body", buttonLeft: "Left Button", buttonRight: "Right Button") { (str) in
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
}

