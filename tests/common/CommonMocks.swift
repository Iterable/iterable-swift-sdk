//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

extension IterableHtmlMessageViewController.Parameters {
    static func createForTesting(messageId: String = UUID().uuidString,
                                 campaignId: NSNumber? = TestHelper.generateIntGuid() as NSNumber) -> IterableHtmlMessageViewController.Parameters {
        let metadata = IterableInAppMessageMetadata.createForTesting(messageId: messageId, campaignId: campaignId)
        return IterableHtmlMessageViewController.Parameters(html: "",
                                                            messageMetadata: metadata,
                                                            isModal: false)
    }
}

extension IterableInAppMessageMetadata {
    static func createForTesting(messageId: String = UUID().uuidString,
                                 campaignId: NSNumber? = TestHelper.generateIntGuid() as NSNumber) -> IterableInAppMessageMetadata {
        IterableInAppMessageMetadata(message: IterableInAppMessage.createForTesting(messageId: messageId, campaignId: campaignId), location: .inApp)
    }
}

extension IterableInAppMessage {
    static func createForTesting(messageId: String = UUID().uuidString,
                                 campaignId: NSNumber? = TestHelper.generateIntGuid() as NSNumber) -> IterableInAppMessage {
        IterableInAppMessage(messageId: messageId,
                             campaignId: campaignId,
                             content: IterableHtmlInAppContent.createForTesting())
    }
}

extension IterableHtmlInAppContent {
    static func createForTesting() -> IterableHtmlInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    }
}
