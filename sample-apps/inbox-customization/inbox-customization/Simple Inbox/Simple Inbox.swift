//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// The simplest of inbox.
/// Inbox looks best when embedded in a navigation controller. It has a `Done` button.
extension MainViewController {
    @IBAction private func onSimpleInboxTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "simple-inbox-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        present(viewController, animated: true)
    }
}
