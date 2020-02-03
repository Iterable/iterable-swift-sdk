//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To filter by messages which, set the `filter` property of view delegate.
/// In this example, we show how to show only messages that have "messageType" set to "promotional" or messageType set to "transactional".
extension MainViewController {
    @IBAction private func onFilterByMessageTypeTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "filter-by-message-type-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FilterByMessageTypeInboxViewDelegate()
        present(viewController, animated: true)
    }
}

public class FilterByMessageTypeInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let filter = IterableInboxViewController.DefaultFilter.usingCustomPayloadMessageType(in: "promotional", "transactional")
}
