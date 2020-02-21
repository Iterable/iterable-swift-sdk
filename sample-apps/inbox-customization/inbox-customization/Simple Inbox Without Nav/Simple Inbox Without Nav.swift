//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation
import UIKit

import IterableSDK

/// If for some reason you can't use the  provided `IterableInboxNavigationViewController` and you want to
/// use your own navigation controller instead, set `IterableInboxViewController` as the root view controller of the navigation controller.
/// You have to make sure there is a button to dismiss the inbox.
extension MainViewController {
    @IBAction private func onSimpleInbox2Tapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "simple-inbox-without-nav-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxViewController()
        let navController = UINavigationController(rootViewController: viewController)
        let barButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onDoneTapped))
        viewController.navigationItem.rightBarButtonItem = barButtonItem
        present(navController, animated: true)
    }
    
    // MARK: private funcations
    
    @objc private func onDoneTapped() {
        dismiss(animated: true)
    }
}
