//
//  Created by Tapash Majumder on 1/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        // Do any additional setup after loading the view.
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        DataManager.shared.loadMessages(from: "inbox-messages-1", withExtension: "json")
    }
}

