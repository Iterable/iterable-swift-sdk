//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To change sort order of messages, set the `comparator` property of view delegate.
extension MainViewController {
    @IBAction private func onSortByDateAscendingTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "sort-by-date-ascending-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = SortByDateAscendingInboxViewDelegate()
        present(viewController, animated: true)
    }
}

public class SortByDateAscendingInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let comparator = IterableInboxViewController.DefaultComparator.ascending
}
