//
//
//  Created by Tapash Majumder on 8/27/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@testable import IterableSDK

class MainViewController: UIViewController {
    @IBOutlet weak var statusLbl: UILabel!
    
    override func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func showPopupInboxTabTap(_: UIButton) {
        ITBInfo()
        
        let inboxNavController = IterableInboxNavigationViewController()
        inboxNavController.isPopup = true
        inboxNavController.tabBarItem.title = "Inbox"
        tabBarController?.viewControllers?.append(inboxNavController)
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "html": "<body bgColor='#FFFFFF'><a href=\'https://www.site1.com\'>Click Here1</a></body>"},
                "trigger": {"type": "never"},
                "inboxMetadata": {
                    "title" : "Title #1",
                    "subtitle" : "Subtitle #1",
                },
                "messageId": "message1",
                "campaignId": "campaign1",
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "html": "<body bgColor='#FFFFFF'><a href=\'https://www.site2.com\'>Click Here2</a></body>"},
                "trigger": {"type": "never"},
                "inboxMetadata": {
                    "title" : "Title #2",
                    "subtitle" : "Subtitle #2",
                },
                "messageId": "message2",
                "campaignId": "campaign2",
            },
        ]
        }
        """.toJsonDict()
        
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
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload).onSuccess { _ in
            DispatchQueue.main.async {
                self.tabBarController?.selectedIndex = 2
            }
        }
    }
    
    @IBAction func showNavInboxTabTap(_: UIButton) {
        ITBInfo()
        
        let inboxNavController = IterableInboxNavigationViewController()
        inboxNavController.isPopup = false
        inboxNavController.tabBarItem.title = "Inbox"
        inboxNavController.navTitle = "Inbox"
        tabBarController?.viewControllers?.append(inboxNavController)
        
        let payload = """
        {"inAppMessages":
        [
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "html": "<body bgColor='#FFFFFF'><a href=\'https://www.site1.com\'>Click Here1</a></body>"},
                "trigger": {"type": "never"},
                "inboxMetadata": {
                    "title" : "Title #1",
                    "subtitle" : "Subtitle #1",
                },
                "messageId": "message1",
                "campaignId": "campaign1",
            },
            {
                "saveToInbox": true,
                "content": {"contentType": "html", "html": "<body bgColor='#FFFFFF'><a href=\'https://www.site2.com\'>Click Here2</a></body>"},
                "trigger": {"type": "never"},
                "inboxMetadata": {
                    "title" : "Title #2",
                    "subtitle" : "Subtitle #2",
                },
                "messageId": "message2",
                "campaignId": "campaign2",
            },
        ]
        }
        """.toJsonDict()
        
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
        
        mockInAppFetcher.mockInAppPayloadFromServer(payload).onSuccess { _ in
            DispatchQueue.main.async {
                self.tabBarController?.selectedIndex = 2
            }
        }
    }
}
