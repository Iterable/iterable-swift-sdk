//
//  Created by Tapash Majumder on 1/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        // Do any additional setup after loading the view.
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_: UITabBarController, didSelect _: UIViewController) {
        if selectedIndex == 1 {
            DataManager.shared.loadMessages(from: "simple-inbox-tab-messages", withExtension: "json")
        } else if selectedIndex == 2 {
            DataManager.shared.loadMessages(from: "custom-inbox-tab-messages", withExtension: "json")
        } else if selectedIndex == 3 {
            DataManager.shared.loadMessages(from: "advanced-inbox-tab-messages", withExtension: "json")
        } else {
            DataManager.shared.loadMessages(from: "inbox-messages", withExtension: "json")
        }
    }
}
