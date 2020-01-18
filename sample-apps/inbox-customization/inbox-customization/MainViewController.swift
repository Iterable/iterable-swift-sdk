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
        let viewController = IterableInboxNavigationViewController()
        present(viewController, animated: true)
    }

    /// If for some reason you can't use the  provided `IterableInboxNavigationViewController` and you want to
    /// use your own navigation controller instead, set `IterableInboxViewController` as the root view controller of the navigation controller.
    /// You have to make sure there is a button to dismiss the inbox.
    @IBAction private func simpleInbox2Tapped() {
        let viewController = IterableInboxViewController()
        let navController = UINavigationController(rootViewController: viewController)
        let barButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onDoneTapped))
        viewController.navigationItem.rightBarButtonItem = barButtonItem
        present(navController, animated: true)
    }
    
    /// To replace the table view cell with your own custom cell, set the `cellNibName` property
    @IBAction private func inboxWithCustomCellTapped() {
        let viewController = IterableInboxNavigationViewController()
        viewController.cellNibName = "CustomInboxCell"
        present(viewController, animated: true)
    }

    /// To change the date format, you will have to set the `dateMapper`property of view delegate.
    @IBAction private func changeDateFormatTapped() {
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FormatDateInboxViewDelegate()
        present(viewController, animated: true)
    }
    
    /// To change sort order of messages, set the `comparator` property of view delegate.
    @IBAction private func sortByDateAscendingTapped() {
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = SortByDateAscendingInboxViewDelegate()
        present(viewController, animated: true)
    }

    /// To change sort order of messages, set the `comparator` property of view delegate.
    @IBAction private func sortByTitleAscendingTapped() {
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = SortByTitleAscendingInboxViewDelegate()
        present(viewController, animated: true)
    }

    /// To filter by messages which, set the `filter` property of view delegate.
    /// In this example, we show how to show only messages that have "messageType" set to "promotional" or messageType set to "transactional".
    @IBAction private func filterByMessageTypeTapped() {
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FilterByMessageTypeInboxViewDelegate()
        present(viewController, animated: true)
    }

    /// To filter by messages which, set the `filter` property of view delegate.
    /// In this example, we show how to show only messages that have "mocha" in their title.
    @IBAction private func filterByMessageTitleTapped() {
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FilterByMessageTitleInboxViewDelegate()
        present(viewController, animated: true)
    }

    @objc private func onDoneTapped() {
        dismiss(animated: true)
    }
}

public class FormatDateInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }
    
    public let dateMapper: (IterableInAppMessage) -> String? = { message in
        guard let createdAt = message.createdAt else {
            return nil
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

public class SortByDateAscendingInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }
    
    public let comparator = IterableInboxViewController.DefaultComparator.ascending
}

public class SortByTitleAscendingInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }
    
    public let comparator: (IterableInAppMessage, IterableInAppMessage) -> Bool = { message1, message2 in
        guard let title1 = message1.inboxMetadata?.title else {
            return true
        }
        guard let title2 = message2.inboxMetadata?.title else {
            return false
        }

        return title1.caseInsensitiveCompare(title2) == .orderedAscending
    }
}

public class FilterByMessageTypeInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }

    public let filter = IterableInboxViewController.DefaultFilter.usingCustomPayloadMessageType(in: "promotional", "transactional")
}

public class FilterByMessageTitleInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }

    public let filter: (IterableInAppMessage) -> Bool = { message in
        guard let title = message.inboxMetadata?.title else {
            return false
        }
        return title.contains("mocha")
    }
}
