//
//  Created by Tapash Majumder on 1/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

/// To filter by messages which, set the `filter` property of view delegate.
/// In this example, we show how to show only messages that have "messageType" set to "promotional" or messageType set to "transactional".
extension MainViewController {
    @IBAction private func onFilterByMessageTypeTapped() {
        // <ignore -- data loading>
        DataManager.shared.loadMessages(from: "filter-by-message-type-messages", withExtension: "json")
        // </ignore -- data loading>
        
        let viewController = IterableInboxNavigationViewController()
        viewController.viewDelegate = FilterByMessageTypeInboxViewDelegate()
        present(viewController, animated: true)
    }
}

public class FilterByMessageTypeInboxViewDelegate: IterableInboxViewControllerViewDelegate {
    public required init() {}
    
    public let filter: (IterableInAppMessage) -> Bool = FilterByMessageTypeInboxViewDelegate.createFilterUsingCustomPayloadMessageType(in: "promotional", "transactional")
    
    /// This filter looks at `customPayload` of inbox message and assumes that the JSON key `messageType` holds the type of message
    /// and it returns true for message of particular message type(s).
    /// e.g., if you set `filter = FilterByMessageTypeInboxViewDelegate.createFilterUsingCustomPayloadMessageType(in: "transactional", "promotional")`
    /// you will be able to see messages with custom payload {"messageType": "transactional"} or {"messageType": "promotional"}
    /// but you will not be able to see messages with custom payload {"messageType": "newsFeed"}
    /// - parameter in: The message type(s) that should be shown.
    public static func createFilterUsingCustomPayloadMessageType(in messageTypes: String...) -> ((IterableInAppMessage) -> Bool) {
        return {
            guard let payload = $0.customPayload as? [String: AnyHashable], let messageType = payload["messageType"] as? String else {
                return false
            }
            
            return messageTypes.first(where: { $0 == messageType }).map { _ in true } ?? false
        }
    }
}
