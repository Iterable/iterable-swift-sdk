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

    /// If for some reason you can't use the  provided `IterableInboxNavigationViewController` and you want to
    /// use your own navigation controller instead, set `IterableInboxViewController` as the root view controller of the navigation controller.
    /// You have to make sure there is a button to dismiss the inbox.
    @IBAction private func simpleInbox2Tapped() {
        // <ignore -- data loading>
        loadDataset(number: 1)
        // </ignore -- data loading>

        let viewController = IterableInboxViewController()
        let navController = UINavigationController(rootViewController: viewController)
        let barButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onDoneTapped))
        viewController.navigationItem.rightBarButtonItem = barButtonItem
        present(navController, animated: true)
    }
    
    /// To change the date format, you will have to set the `dateMapper`property of view delegate.
    @IBAction private func changeDateFormatTapped() {
        // <ignore -- data loading>
        loadDataset(number: 1)
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FormatDateInboxViewDelegate()
        present(viewController, animated: true)
    }
    
    /// To change sort order of messages, set the `comparator` property of view delegate.
    @IBAction private func sortByDateAscendingTapped() {
        // <ignore -- data loading>
        loadDataset(number: 1)
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = SortByDateAscendingInboxViewDelegate()
        present(viewController, animated: true)
    }

    /// To change sort order of messages, set the `comparator` property of view delegate.
    @IBAction private func sortByTitleAscendingTapped() {
        // <ignore -- data loading>
        loadDataset(number: 1)
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = SortByTitleAscendingInboxViewDelegate()
        present(viewController, animated: true)
    }

    // MARK: private funcations
    @objc private func onDoneTapped() {
        dismiss(animated: true)
    }

    func loadDataset(number: Int) {
        DataManager.shared.loadMessages(from: "inbox-messages-\(number)", withExtension: "json")
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
