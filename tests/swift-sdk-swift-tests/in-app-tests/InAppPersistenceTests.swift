//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InAppPersistenceTests: XCTestCase {
    func testUIEdgeInsetsKeysDecodingEncoding() {
        let edgeInsets = UIEdgeInsets(top: 1.25, left: 2.50, bottom: 3.333, right: 4.5)
        
        guard let encodedInsets = try? JSONEncoder().encode(edgeInsets) else {
            XCTFail("ERROR FAIL: was not able to encode UIEdgeInsets")
            return
        }
        
        guard let decodedInsets = try? JSONDecoder().decode(UIEdgeInsets.self, from: encodedInsets) else {
            XCTFail("ERROR FAIL: was not able to decode encoded UIEdgeInsets")
            return
        }
        
        XCTAssertEqual(edgeInsets, decodedInsets)
    }
    
    func testInboxMetadataDecodingEncoding() {
        let title = "TITLE!!!"
        let subtitle = "subtitle :)"
        let icon = "picture.jpg"
        
        let inboxMetadata = IterableInboxMetadata(title: title, subtitle: subtitle, icon: icon)
        
        guard let encodedInboxMetadata = try? JSONEncoder().encode(inboxMetadata) else {
            XCTFail("ERROR FAIL: was not able to encode IterableInboxMetadata")
            return
        }
        
        guard let decodedInboxMetadata = try? JSONDecoder().decode(IterableInboxMetadata.self, from: encodedInboxMetadata) else {
            XCTFail("ERROR FAIL: was not able to decode encoded IterableInboxMetadata")
            return
        }
        
        XCTAssertEqual(inboxMetadata.title, decodedInboxMetadata.title)
        XCTAssertEqual(inboxMetadata.subtitle, decodedInboxMetadata.subtitle)
        XCTAssertEqual(inboxMetadata.icon, decodedInboxMetadata.icon)
    }
    
    func testDefaultTriggerDict() {
        let defaultTriggerDict = IterableInAppTrigger.createDefaultTriggerDict()
        
        let createdDict = IterableInAppTrigger.createTriggerDict(forTriggerType: .defaultTriggerType)
        
        if let defaultDictValue = defaultTriggerDict[JsonKey.InApp.type] as? String,
           let createdDictValue = createdDict[JsonKey.InApp.type] as? String {
            XCTAssertEqual(defaultDictValue, createdDictValue)
        } else {
            XCTFail("conversion to string failed")
        }
    }
    
    func testPersistentReadStateFromServerPayload() {
        let messages = [getInboxMessage("1", false)]
        
        let mockInAppFetcher = MockInAppFetcher()
        
        let internalAPI = IterableAPIInternal.initializeForTesting(inAppFetcher: mockInAppFetcher)
        
        let inboxVCModel = InboxViewControllerViewModel(internalAPIProvider: internalAPI)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages)
            .onSuccess { [weak internalAPI = internalAPI, weak inboxVCModel = inboxVCModel] count in
                guard let inboxMessage = inboxVCModel?.message(atIndexPath: IndexPath(row: 0, section: 0)) else {
                    XCTFail("")
                    return
                }
                
                inboxVCModel?.set(read: true, forMessage: inboxMessage)
                
                guard let firstMessage = internalAPI?.inAppManager.getMessages().first else {
                    XCTFail("could not get in-app message for test")
                    return
                }
                
                XCTAssertTrue(firstMessage.read)
        }
    }
    
    private static let email = "user@example.com"
    
    private static let emptyInAppContent = IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    
    private func getInboxMessage(_ id: String = "", _ read: Bool) -> IterableInAppMessage {
        return IterableInAppMessage(messageId: id,
                                    campaignId: nil,
                                    trigger: .defaultTrigger,
                                    createdAt: nil,
                                    expiresAt: nil,
                                    content: InAppPersistenceTests.emptyInAppContent,
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil,
                                    read: read,
                                    priorityLevel: Const.PriorityLevel.unassigned)
    }
}
