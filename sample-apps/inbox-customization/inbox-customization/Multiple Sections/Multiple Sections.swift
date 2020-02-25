//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation
import UIKit

import IterableSDK

/// To display an inbox message in a section use `messageToSectionMaper` property of the view delegate.
/// This mapper is a closure which takes an `IterableInboxMessage` and returns an `Int`.
extension MainViewController {
    @IBAction private func onMultipleSectionsTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "multiple-sections-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = MultipleSectionsViewDelegate()
        viewController.groupSections = true
        present(viewController, animated: true)
    }
    
    // MARK: private funcations
    
    @objc private func onDoneTapped() {
        dismiss(animated: true)
    }
}

public class MultipleSectionsViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    /// This mapper looks at `customPayload` of inbox message and assumes that json key `messageSection` holds the section number.
    /// e.g., An inbox message with custom payload  `{"messageSection": 2}` will return 2 as section.
    public let messageToSectionMapper: (IterableInAppMessage) -> Int = {
        guard let payload = $0.customPayload as? [String: AnyHashable], let section = payload["messageSection"] as? Int else {
            return 0
        }
        return section
    }
}
