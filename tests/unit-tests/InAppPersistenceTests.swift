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
        let title = "TITLE"
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
        let expectation1 = expectation(description: #function)
        let mockInAppFetcher = MockInAppFetcher()
        
        let internalAPI = InternalIterableAPI.initializeForTesting(inAppFetcher: mockInAppFetcher)
        
        mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: [Self.getInboxMessage(id: "1", read: false)])
            .flatMap { _ in
                return mockInAppFetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: [Self.getInboxMessage(id: "1", read: true)])
            }
            .onSuccess { [weak internalAPI = internalAPI] count in
                guard let firstMessage = internalAPI?.inAppManager.getMessages().first else {
                    XCTFail("could not get in-app message for test")
                    return
                }
                XCTAssertTrue(firstMessage.read)
                expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    private static func getInboxMessage(id: String = "", read: Bool) -> IterableInAppMessage {
        return IterableInAppMessage(messageId: id,
                                    campaignId: nil,
                                    trigger: .neverTrigger,
                                    createdAt: nil,
                                    expiresAt: nil,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil,
                                    read: read,
                                    priorityLevel: Const.PriorityLevel.unassigned)
    }
    
    func testJsonOnlyMessagePersistence() {
        let expectation1 = expectation(description: "testJsonOnlyMessagePersistence")
        
        // Test 1: Basic JSON-only message with customPayload
        let customPayload: [AnyHashable: Any] = [
            "key1": "value1",
            "key2": 42,
            "nested": ["active": true]
        ]
        
        let message = IterableInAppMessage(
            messageId: "test-json-1",
            campaignId: 123,
            trigger: .neverTrigger,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400),
            content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
            saveToInbox: true, // Should be forced to false for JSON-only
            inboxMetadata: nil,
            customPayload: customPayload,
            read: false,
            priorityLevel: 0.0,
            jsonOnly: true
        )
        
        // Test persistence to file
        let filename = "test_json_persistence"
        let persister = InAppFilePersister(filename: filename)
        persister.clear()
        
        // Save and retrieve message
        persister.persist([message])
        let retrievedMessages = persister.getMessages()
        XCTAssertEqual(retrievedMessages.count, 1)
        
        guard let retrievedMessage = retrievedMessages.first else {
            XCTFail("No message retrieved")
            return
        }
        
        // Verify basic properties
        XCTAssertEqual(message.messageId, retrievedMessage.messageId)
        XCTAssertEqual(message.campaignId?.intValue, retrievedMessage.campaignId?.intValue)
        XCTAssertFalse(retrievedMessage.saveToInbox, "JSON-only messages should never be saved to inbox")
        
        // Verify customPayload is preserved correctly
        XCTAssertEqual(retrievedMessage.customPayload?["key1"] as? String, "value1")
        XCTAssertEqual(retrievedMessage.customPayload?["key2"] as? Int, 42)
        XCTAssertEqual((retrievedMessage.customPayload?["nested"] as? [String: Any])?["active"] as? Bool, true)
        
        // Test 2: Direct encoding/decoding
        guard let encodedMessage = try? JSONEncoder().encode(message) else {
            XCTFail("Failed to encode JSON-only message")
            return
        }
        
        // Verify encoded data structure
        if let jsonData = try? JSONSerialization.jsonObject(with: encodedMessage) as? [String: Any] {
            XCTAssertEqual(jsonData["jsonOnly"] as? Int, 1)
            XCTAssertFalse(jsonData["saveToInbox"] as? Bool ?? true)
            XCTAssertNotNil(jsonData["customPayload"])
            // Content should be minimal for JSON-only messages
            XCTAssertTrue(jsonData["content"] == nil || (jsonData["content"] as? [String: Any])?.isEmpty == true)
        }
        
        // Test 3: Message without customPayload should not be persisted for JSON-only messages
        let messageWithoutPayload = IterableInAppMessage(
            messageId: "test-json-2",
            campaignId: 456,
            trigger: .neverTrigger,
            createdAt: nil,
            expiresAt: nil,
            content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: nil,
            read: false,
            priorityLevel: 0.0,
            jsonOnly: true
        )
        
        persister.clear()
        persister.persist([messageWithoutPayload])
        let retrievedEmptyMessages = persister.getMessages()
        XCTAssertEqual(retrievedEmptyMessages.count, 1, "JSON-only message without customPayload should be persisted")
        
        // Test 4: Array of JSON-only messages
        let messagesArray = [
            createJsonOnlyMessage(id: "json-1", payload: ["type": "notification", "priority": 1]),
            createJsonOnlyMessage(id: "json-2", payload: ["type": "alert", "priority": 2]),
            createJsonOnlyMessage(id: "json-3", payload: ["type": "message", "priority": 3])
        ]
        
        persister.clear()
        persister.persist(messagesArray)
        let retrievedArray = persister.getMessages()
        
        XCTAssertEqual(retrievedArray.count, messagesArray.count)
        
        // Verify each message in array
        for (original, retrieved) in zip(messagesArray, retrievedArray) {
            XCTAssertEqual(original.messageId, retrieved.messageId)
            XCTAssertEqual(original.customPayload?["type"] as? String, retrieved.customPayload?["type"] as? String)
            XCTAssertEqual(original.customPayload?["priority"] as? Int, retrieved.customPayload?["priority"] as? Int)
        }
        
        expectation1.fulfill()
        
        // Cleanup
        persister.clear()
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func createJsonOnlyMessage(id: String, payload: [AnyHashable: Any]) -> IterableInAppMessage {
        IterableInAppMessage(
            messageId: id,
            campaignId: Int.random(in: 1...1000) as NSNumber,
            trigger: .neverTrigger,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400),
            content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: payload,
            read: false,
            priorityLevel: 0.0,
            jsonOnly: true
        )
    }
    
    func testJsonOnlyMessageCustomPayloadPriority() {
        let customPayload: [AnyHashable: Any] = [
            "key1": "customValue",
            "key2": 42
        ]
        
        let message = IterableInAppMessage(
            messageId: "test-json-priority",
            campaignId: 789,
            trigger: .neverTrigger,
            createdAt: nil,
            expiresAt: nil,
            content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: customPayload,
            read: false,
            priorityLevel: 0.0,
            jsonOnly: true
        )
        
        guard let encodedMessage = try? JSONEncoder().encode(message) else {
            XCTFail("Failed to encode JSON-only message")
            return
        }
        
        guard let decodedMessage = try? JSONDecoder().decode(IterableInAppMessage.self, from: encodedMessage) else {
            XCTFail("Failed to decode JSON-only message")
            return
        }
        
        // Verify that customPayload values are preserved
        XCTAssertEqual(decodedMessage.customPayload?["key1"] as? String, "customValue")
        XCTAssertEqual(decodedMessage.customPayload?["key2"] as? Int, 42)
        
        // Verify that content is ignored for JSON-only messages
        XCTAssertTrue(decodedMessage.content is IterableHtmlInAppContent)
        XCTAssertTrue(decodedMessage.jsonOnly)
        XCTAssertFalse(decodedMessage.saveToInbox)
    }
}
