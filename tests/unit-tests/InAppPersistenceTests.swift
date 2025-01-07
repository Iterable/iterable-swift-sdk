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
        let customPayload: [AnyHashable: Any] = [
            "key1": "value1",
            "key2": 42,
            "key3": ["nested": true]
        ]
        
        let message = IterableInAppMessage(
            messageId: "test-json-1",
            campaignId: 123,
            trigger: .neverTrigger,
            createdAt: nil,
            expiresAt: nil,
            content: IterableJsonInAppContent(json: [:]),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: customPayload,
            read: false,
            priorityLevel: 0.0
        )
        
        guard let encodedMessage = try? JSONEncoder().encode(message) else {
            XCTFail("Failed to encode JSON-only message")
            return
        }
        
        guard let decodedMessage = try? JSONDecoder().decode(IterableInAppMessage.self, from: encodedMessage) else {
            XCTFail("Failed to decode JSON-only message")
            return
        }
        
        XCTAssertEqual(message.messageId, decodedMessage.messageId)
        XCTAssertEqual(message.campaignId?.intValue, decodedMessage.campaignId?.intValue)
        XCTAssertFalse(decodedMessage.saveToInbox)
        XCTAssertEqual(message.read, decodedMessage.read)
        
        guard let decodedContent = decodedMessage.content as? IterableJsonInAppContent else {
            XCTFail("Content type mismatch")
            return
        }
        
        XCTAssertEqual(decodedContent.json["key1"] as? String, "value1")
        XCTAssertEqual(decodedContent.json["key2"] as? Int, 42)
        XCTAssertEqual((decodedContent.json["key3"] as? [String: Any])?["nested"] as? Bool, true)
    }
    
    func testJsonOnlyMessagePersistenceWithFilePersister() {
        let customPayload: [AnyHashable: Any] = [
            "id": 1,
            "score": 42.5,
            "active": true,
            "name": "Jane Doe"
        ]
        
        let message = IterableInAppMessage(
            messageId: "test-json-2",
            campaignId: 456,
            trigger: .neverTrigger,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400),
            content: IterableJsonInAppContent(json: [:]),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: customPayload,
            read: false,
            priorityLevel: 0.0
        )
        
        let filename = "test_json_persistence"
        let persister = InAppFilePersister(filename: filename)
        
        // Clear any existing data
        persister.clear()
        
        // Save message
        persister.persist([message])
        
        // Read back message
        let retrievedMessages = persister.getMessages()
        XCTAssertEqual(retrievedMessages.count, 1)
        
        guard let retrievedMessage = retrievedMessages.first else {
            XCTFail("No message retrieved")
            return
        }
        
        XCTAssertEqual(message.messageId, retrievedMessage.messageId)
        XCTAssertEqual(message.campaignId?.intValue, retrievedMessage.campaignId?.intValue)
        XCTAssertFalse(retrievedMessage.saveToInbox)
        
        guard let retrievedContent = retrievedMessage.content as? IterableJsonInAppContent else {
            XCTFail("Content type mismatch")
            return
        }
        
        XCTAssertEqual(retrievedContent.json["id"] as? Int, 1)
        XCTAssertEqual(retrievedContent.json["score"] as? Double, 42.5)
        XCTAssertEqual(retrievedContent.json["active"] as? Bool, true)
        XCTAssertEqual(retrievedContent.json["name"] as? String, "Jane Doe")
        
        // Cleanup
        persister.clear()
    }
    
    func testJsonOnlyMessageArrayPersistence() {
        let messages = [
            createJsonOnlyMessage(
                id: "json-1",
                payload: ["type": "notification", "priority": 1]
            ),
            createJsonOnlyMessage(
                id: "json-2",
                payload: ["type": "alert", "priority": 2]
            ),
            createJsonOnlyMessage(
                id: "json-3",
                payload: ["type": "message", "priority": 3]
            )
        ]
        
        let filename = "test_json_array"
        let persister = InAppFilePersister(filename: filename)
        
        // Clear any existing data
        persister.clear()
        
        // Save messages
        persister.persist(messages)
        
        // Read back messages
        let retrievedMessages = persister.getMessages()
        XCTAssertEqual(retrievedMessages.count, messages.count)
        
        // Verify each message
        for (original, retrieved) in zip(messages, retrievedMessages) {
            XCTAssertEqual(original.messageId, retrieved.messageId)
            
            guard let originalContent = original.content as? IterableJsonInAppContent,
                  let retrievedContent = retrieved.content as? IterableJsonInAppContent else {
                XCTFail("Content type mismatch")
                continue
            }
            
            XCTAssertEqual(originalContent.json["type"] as? String, retrievedContent.json["type"] as? String)
            XCTAssertEqual(originalContent.json["priority"] as? Int, retrievedContent.json["priority"] as? Int)
        }
        
        // Cleanup
        persister.clear()
    }
    
    private func createJsonOnlyMessage(id: String, payload: [AnyHashable: Any]) -> IterableInAppMessage {
        IterableInAppMessage(
            messageId: id,
			campaignId: Int.random(in: 1...1000) as NSNumber,
            trigger: .neverTrigger,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400),
            content: IterableJsonInAppContent(json: payload),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: nil,
            read: false,
            priorityLevel: 0.0
        )
    }
    
    func testJsonOnlyMessageCustomPayloadPriority() {
        let customPayload: [AnyHashable: Any] = [
            "key1": "customValue",
            "key2": 42
        ]
        
        let contentPayload: [AnyHashable: Any] = [
            "key1": "contentValue",
            "key2": 100
        ]
        
        let message = IterableInAppMessage(
            messageId: "test-json-priority",
            campaignId: 789,
            trigger: .neverTrigger,
            createdAt: nil,
            expiresAt: nil,
            content: IterableJsonInAppContent(json: contentPayload),
            saveToInbox: false,
            inboxMetadata: nil,
            customPayload: customPayload,
            read: false,
            priorityLevel: 0.0
        )
        
        guard let encodedMessage = try? JSONEncoder().encode(message) else {
            XCTFail("Failed to encode JSON-only message")
            return
        }
        
        guard let decodedMessage = try? JSONDecoder().decode(IterableInAppMessage.self, from: encodedMessage) else {
            XCTFail("Failed to decode JSON-only message")
            return
        }
        
        guard let decodedContent = decodedMessage.content as? IterableJsonInAppContent else {
            XCTFail("Content type mismatch")
            return
        }
        
        // Verify that customPayload values are used instead of content.payload
        XCTAssertEqual(decodedContent.json["key1"] as? String, "customValue")
        XCTAssertEqual(decodedContent.json["key2"] as? Int, 42)
    }
}
