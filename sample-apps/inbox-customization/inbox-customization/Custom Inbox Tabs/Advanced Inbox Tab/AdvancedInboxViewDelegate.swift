//
//  Created by Tapash Majumder on 1/16/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

public class AdvancedInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    /// This mapper looks at `customPayload` of inbox message and assumes that json key `messageSection` holds the section number.
    /// e.g., An inbox message with custom payload  `{"messageSection": 2}` will return 2 as section.
    public let messageToSectionMapper: (IterableInAppMessage) -> Int = {
        guard let payload = $0.customPayload as? [String: AnyHashable], let section = payload["messageSection"] as? Int else {
            return 0
        }
        return section
    }
    
    public let customNibNames: [String] = ["CustomInboxCell", "AdvancedInboxCell", "CustomInboxCell1", "CustomInboxCell2"]
    
    /// This mapper looks at `customPayload` of inbox message and assumes that json key `customCellName` holds the custom nib name for the message.
    /// e.g., An inbox message with custom payload `{"customCellName": "CustomInboxCell3"}` will return `CustomInboxCell3` as the custom nib name.
    public let customNibNameMapper: (IterableInAppMessage) -> String? = {
        guard
            let payload = $0.customPayload as? [String: AnyHashable],
            let customNibName = payload["customCellName"] as? String else {
            return nil
        }
        return customNibName
    }
    
    public func renderAdditionalFields(forCell cell: IterableInboxCell, withMessage message: IterableInAppMessage) {
        guard
            let customCell = cell as? AdvancedInboxCell,
            let payload = message.customPayload as? [String: AnyHashable],
            let discount = payload["discount"] as? String else {
            return
        }
        
        customCell.discountLbl?.text = "\(discount)"
    }
}
