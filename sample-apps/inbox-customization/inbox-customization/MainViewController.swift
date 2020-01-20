//
//  Created by Tapash Majumder on 1/17/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

import IterableSDK

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    /// The simplest of inbox.
    /// Inbox looks best when embedded in a navigation controller. It has a `Done` button.
    @IBAction private func simpleInboxTapped() {
        // <ignore -- data loading>
        loadDataset(number: 1)
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        present(viewController, animated: true)
    }

    
    
    func loadDataset(number: Int) {
        DataManager.shared.loadMessages(from: "inbox-messages-\(number)", withExtension: "json")
    }
}


