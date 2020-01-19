//
//  Created by Tapash Majumder on 1/19/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

extension MainViewController {
    /// To replace the table view cell with your own custom cell, set the `cellNibName` property.
    /// In this example, make sure that an xib with name `CustomInboxCell2.xib` is present.
    /// IMP: Also, make sure that in `file inspector` for the xib file `target membership` is checked. Otherwise the file will not be copied.
    @IBAction private func onInboxWithCustomCellTapped() {
        // <ignore -- data loading>
        loadDataset1()
        // </ignore -- data loading>

        let viewController = IterableInboxNavigationViewController()
        viewController.cellNibName = "DarkInboxCell"
        present(viewController, animated: true)
    }

}
