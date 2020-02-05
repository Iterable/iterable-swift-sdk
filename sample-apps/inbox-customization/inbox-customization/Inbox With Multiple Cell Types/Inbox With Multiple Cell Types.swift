//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To disolay different table view cells for different message types, set `customNibNamesMapper` property of view delegate.
/// This mapper is a closure which takes an `IterableInboxMessage` and returns an optional `String`.
/// Return  the nib name for an inbox message to use that table view cell nib file.
/// Return `nil` to use the default table view cell.
extension MainViewController {
    @IBAction private func onInboxWithMultipleCellTypesTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "inbox-with-multiple-cell-types-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = MultipleCellTypesInboxViewDelegate()
        present(viewController, animated: true)
    }
}

public class MultipleCellTypesInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let customNibNames = ["CustomInboxCell1", "CustomInboxCell2", "AdvancedInboxCell", "CustomInboxCell"]
    
    public let customNibNameMapper = IterableInboxViewController.DefaultNibNameMapper.usingCustomPayloadNibName
}
