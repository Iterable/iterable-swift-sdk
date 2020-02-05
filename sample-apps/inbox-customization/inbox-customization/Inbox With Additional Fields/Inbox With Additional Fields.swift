//
//  Created by Tapash Majumder on 1/19/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To render addtional fields in your table view cell, create a new table view cell with the addtional fields.
/// Also create a view delegate with `renderAddtionalFields` metthod of `IterableInboxViewControllerViewDelegate`.
/// IMP: Make sure that in the `file inspector` for the table view cell file, `target membership` is checked.
/// This is needed so that the xib file is copied to the project.
extension MainViewController {
    @IBAction private func onInboxWithAdditionalFieldsTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "inbox-with-additional-fields-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.cellNibName = "AdditionalFieldsInboxCell"
        viewController.viewDelegate = InboxWithAdditionalFieldsViewDelegate()
        present(viewController, animated: true)
    }
}

public class InboxWithAdditionalFieldsViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public func renderAdditionalFields(forCell cell: IterableInboxCell, withMessage message: IterableInAppMessage) {
        guard
            let customCell = cell as? AdditionalFieldsInboxCell,
            let payload = message.customPayload as? [String: AnyHashable],
            let discount = payload["discount"] as? String else {
            return
        }
        
        customCell.discountLbl?.text = "\(discount)"
    }
}
