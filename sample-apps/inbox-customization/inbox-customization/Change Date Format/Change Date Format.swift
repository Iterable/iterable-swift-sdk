//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To change the date format, you will have to set the `dateMapper`property of view delegate.
extension MainViewController {
    @IBAction private func onChangeDateFormatTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "change-date-format-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FormatDateInboxViewDelegate()
        present(viewController, animated: true)
    }
}

public class FormatDateInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let dateMapper: (IterableInAppMessage) -> String? = { message in
        guard let createdAt = message.createdAt else {
            return nil
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
