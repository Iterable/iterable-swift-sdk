//
//  Created by Tapash Majumder on 1/16/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

public class AdvancedInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {
    }
    
    public let messageToSectionMapper: ((IterableInAppMessage) -> Int) = IterableInboxViewController.DefaultSectionMapper.usingCustomPayloadMessageSection

    public let customNibNames: [String] = ["CustomInboxCell", "AdvancedInboxCell", "CustomInboxCell1", "CustomInboxCell2"]

    public let customNibNameMapper: ((IterableInAppMessage) -> String?) = IterableInboxViewController.DefaultNibNameMapper.usingCustomPayloadNibName

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
