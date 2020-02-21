//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To filter by messages which, set the `filter` property of view delegate.
/// In this example, we show how to show only messages that have "mocha" in their title.
extension MainViewController {
    @IBAction private func onFilterByMessageTitleTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "filter-by-message-title-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FilterByMessageTitleInboxViewDelegate()
        present(viewController, animated: true)
    }
}

public class FilterByMessageTitleInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let filter: (IterableInAppMessage) -> Bool = { message in
        guard let title = message.inboxMetadata?.title else {
            return false
        }
        return title.contains("mocha")
    }
}
