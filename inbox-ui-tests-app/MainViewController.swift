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
}
