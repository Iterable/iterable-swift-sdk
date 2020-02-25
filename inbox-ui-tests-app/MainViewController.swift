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
    }
    
    @IBAction func loadDataset1Tapped(_: Any) {
        ITBInfo()
        AppDelegate.sharedInstance.loadDataset(number: 1)
    }
    
    @IBAction func loadDataset2Tapped(_: Any) {
        ITBInfo()
        AppDelegate.sharedInstance.loadDataset(number: 2)
    }
    
    @IBAction func loadDataset3Tapped(_: Any) {
        ITBInfo()
        AppDelegate.sharedInstance.loadDataset(number: 3)
    }
    
    @IBAction func showInboxTap(_: UIButton) {
        ITBInfo()
        tabBarController?.selectedIndex = 0
        
        let inboxNavController = IterableInboxNavigationViewController()
        inboxNavController.isPopup = false
        inboxNavController.navTitle = "Inbox"
        
        present(inboxNavController, animated: true)
    }
    
    @IBAction func addInboxMessageTap(_: UIButton) {
        ITBInfo()
        AppDelegate.sharedInstance.addInboxMessage()
    }
    
    @IBAction func addMessageToServer(_: Any) {
        ITBInfo()
        AppDelegate.sharedInstance.addMessageToServer()
    }
    
    @IBAction func showCustomInbox1Tap(_: Any) {
        ITBInfo()
        tabBarController?.selectedIndex = 0
        
        let inboxNavController = IterableInboxNavigationViewController()
        inboxNavController.isPopup = false
        inboxNavController.navTitle = "Inbox"
        inboxNavController.viewDelegate = ViewDelegate1()
        
        present(inboxNavController, animated: true)
    }
}

public class ViewDelegate1: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let customNibNames: [String] = ["CustomInboxCell3"]
    public let customNibNameMapper: (IterableInAppMessage) -> String? = SampleInboxViewDelegateImplementations.NibNameMapper.usingCustomPayloadNibName
}
