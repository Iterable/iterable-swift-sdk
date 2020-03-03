//
//  Created by Tapash Majumder on 2/23/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

public enum SampleInboxViewDelegateImplementations {
    /// By default, all messages are shown
    /// This enumeration shows how to write a sample filter which can be used by `IterableInboxViewControllerViewDelegate`.
    /// You can create your own filters which can be functions or closures.
    public enum Filter {
        /// This filter looks at `customPayload` of inbox message and assumes that the JSON key `messageType` holds the type of message
        /// and it returns true for message of particular message type(s).
        /// e.g., if you set `filter = IterableInboxViewController.DefaultFilter.usingCustomPayloadMessageType(in: "transactional", "promotional")`
        /// you will be able to see messages with custom payload {"messageType": "transactional"} or {"messageType": "promotional"}
        /// but you will not be able to see messages with custom payload {"messageType": "newsFeed"}
        /// - parameter in: The message type(s) that should be shown.
        public static func usingCustomPayloadMessageType(in messageTypes: String...) -> ((IterableInAppMessage) -> Bool) {
            return {
                guard let payload = $0.customPayload as? [String: AnyHashable], let messageType = payload["messageType"] as? String else {
                    return false
                }
                
                return messageTypes.first(where: { $0 == messageType }).map { _ in true } ?? false
            }
        }
    }
    
    /// By default, all messages are in one section.
    /// This enumeration has sample mappers which map inbox messages to section number. This can be used by `IterableInboxViewControllerViewDelegate`.
    public enum SectionMapper {
        /// This mapper looks at `customPayload` of inbox message and assumes that json key `messageSection` holds the section number.
        /// e.g., An inbox message with custom payload  `{"messageSection": 2}` will return 2 as section.
        public static var usingCustomPayloadMessageSection: ((IterableInAppMessage) -> Int) = { message in
            guard let payload = message.customPayload as? [String: AnyHashable], let section = payload["messageSection"] as? Int else {
                return 0
            }
            return section
        }
    }
    
    /// Use nib name maper only when you have multiple types of messages.
    public enum NibNameMapper {
        /// This mapper looks at `customPayload` of inbox message and assumes that json key `customCellName` holds the custom nib name for the message.
        /// e.g., An inbox message with custom payload `{"customCellName": "CustomInboxCell3"}` will return `CustomInboxCell3` as the custom nib name.
        public static var usingCustomPayloadNibName: ((IterableInAppMessage) -> String?) = {
            guard
                let payload = $0.customPayload as? [String: AnyHashable],
                let customNibName = payload["customCellName"] as? String else {
                return nil
            }
            return customNibName
        }
    }
}
