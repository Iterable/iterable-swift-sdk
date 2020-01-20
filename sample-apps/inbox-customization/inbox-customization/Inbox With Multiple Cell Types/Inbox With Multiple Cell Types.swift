//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

extension MainViewController {
    /// To render addtional fields in your table view cell, create a new table view cell with the addtional fields.
    /// Also create a view delegate with `renderAddtionalFields` metthod of `IterableInboxViewControllerViewDelegate`.
    /// IMP: Make sure that in the `file inspector` for the table view cell file, `target membership` is checked.
    /// This is needed so that the xib file is copied to the project.
    @IBAction private func onInboxWithMultipleCellTypesTapped() {
        // <ignore -- data loading>
        loadDataset(number: 2)
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = MultipleCellTypesInboxViewDelegate()
        present(viewController, animated: true)
    }

}

public class MultipleCellTypesInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }

    public let customNibNames = ["CustomInboxCell1", "CustomInboxCell2", "AdvancedInboxCell", "CustomInboxCell"]
    
    public let customNibNameMapper = IterableInboxViewController.DefaultNibNameMapper.usingCustomPayloadNibName
}
