//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation
import UIKit

import IterableSDK

extension MainViewController {
    /// The simplest of inbox.
    /// Inbox looks best when embedded in a navigation controller. It has a `Done` button.
    @IBAction private func onMultipleSectionsTapped() {
        // <ignore -- data loading>
        loadDataset(number: 4)
        // </ignore -- data loading>

        let viewController = IterableInboxViewController(style: .grouped)
        viewController.viewDelegate = MultipleSectionsViewDelegate()
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

public class MultipleSectionsViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }
    
    /// This mapper looks at `customPayload` of inbox message and assumes that json key `messageSection` holds the section number.
    /// e.g., An inbox message with custom payload  `{"messageSection": 2}` will return 2 as section.
    /// Feel free to write your own messageToSectionMapper
    public let messageToSectionMapper: ((IterableInAppMessage) -> Int) = IterableInboxViewController.DefaultSectionMapper.usingCustomPayloadMessageSection
}
