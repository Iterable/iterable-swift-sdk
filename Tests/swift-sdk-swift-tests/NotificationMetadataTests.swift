//
//  Created by Jay Kim on 5/23/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class NotificationMetadataTests: XCTestCase {
    func testInvalidPayloads() {
        let invalidPayloads: [[AnyHashable: Any]] = [
            // no "itbl"
            [:],
            
            // no "isGhostPush"
            ["itbl": ["campaignId": 0,
                      "templateId": 0]],
            
            // no "templateId"
            ["itbl": ["campaignId": 0,
                      "isGhostPush": false]],
            
            // "campaignId" not a number
            ["itbl": ["campaignId": "hello campaignId :)",
                      "templateId": 0,
                      "isGhostPush": false]],
            
            // "templateId" not a number
            ["itbl": ["campaignId": 0,
                      "templateId": "hello templateId :)",
                      "isGhostPush": false]],
            
            // "isGhostPush" not a number
            ["itbl": ["campaignId": 0,
                      "templateId": 0,
                      "isGhostPush": "hahahhahhahaha"]],
        ]
        
        for payload in invalidPayloads {
            XCTAssertNil(IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload))
        }
    }
    
    func testValidGhostPayload() {
        let campaignId = NSNumber(value: 666)
        let templateId = NSNumber(value: 777)
        
        let payload = ["itbl": ["campaignId": campaignId,
                                "templateId": templateId,
                                "isGhostPush": true,
                                "messageId": "39580285"]]
        
        let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload)!
        
        XCTAssertEqual(metadata.campaignId, campaignId)
        XCTAssertEqual(metadata.templateId, templateId)
        
        XCTAssertTrue(metadata.isGhostPush)
        XCTAssertFalse(metadata.isProof())
        XCTAssertFalse(metadata.isTestPush())
        XCTAssertFalse(metadata.isRealCampaignNotification())
    }
    
    func testValidRealPayload() {
        let campaignId = NSNumber(value: 666)
        let templateId = NSNumber(value: 777)
        
        let payload = ["itbl": ["campaignId": campaignId,
                                "templateId": templateId,
                                "isGhostPush": false,
                                "messageId": "94589291"]]
        
        let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload)!
        
        XCTAssertEqual(metadata.campaignId, campaignId)
        XCTAssertEqual(metadata.templateId, templateId)
        
        XCTAssertFalse(metadata.isGhostPush)
        XCTAssertFalse(metadata.isProof())
        XCTAssertFalse(metadata.isTestPush())
        XCTAssertTrue(metadata.isRealCampaignNotification())
    }
    
    func testValidProofPayload() {
        let campaignId = NSNumber(value: 0)
        let templateId = NSNumber(value: 777)
        
        let payload = ["itbl": ["campaignId": campaignId,
                                "templateId": templateId,
                                "isGhostPush": false,
                                "messageId": "53082983"]]
        
        let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload)!
        
        XCTAssertEqual(metadata.campaignId, campaignId)
        XCTAssertEqual(metadata.templateId, templateId)
        
        XCTAssertFalse(metadata.isGhostPush)
        XCTAssertTrue(metadata.isProof())
        XCTAssertFalse(metadata.isTestPush())
        XCTAssertFalse(metadata.isRealCampaignNotification())
    }
    
    func testValidProofPayloadNoCampaignId() {
        let campaignId = NSNumber(value: 0)
        let templateId = NSNumber(value: 777)
        
        let payload = ["itbl": ["templateId": templateId,
                                "isGhostPush": false,
                                "messageId": "983479527"]]
        
        let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload)!
        
        XCTAssertEqual(metadata.campaignId, campaignId)
        XCTAssertEqual(metadata.templateId, templateId)
        
        XCTAssertFalse(metadata.isGhostPush)
        XCTAssertTrue(metadata.isProof())
        XCTAssertFalse(metadata.isTestPush())
        XCTAssertFalse(metadata.isRealCampaignNotification())
    }
    
    func testValidTestPayload() {
        let campaignId = 0
        let templateId = 0
        
        let payload = ["itbl": ["campaignId": campaignId,
                                "templateId": templateId,
                                "isGhostPush": false,
                                "messageId": "2938706098"]]
        
        let metadata = IterablePushNotificationMetadata.metadata(fromLaunchOptions: payload)!
        
        XCTAssertEqual(metadata.campaignId, NSNumber(value: campaignId))
        XCTAssertEqual(metadata.templateId ?? nil, NSNumber(value: templateId))
        
        XCTAssertFalse(metadata.isGhostPush)
        XCTAssertFalse(metadata.isProof())
        XCTAssertTrue(metadata.isTestPush())
        XCTAssertFalse(metadata.isRealCampaignNotification())
    }
    
    func testDeserializedFromIterableJson() {
        let ghostPush: NSDictionary = ["itbl": ["campaignId": 666,
                                                "templateId": 777,
                                                "isGhostPush": true,
                                                "messageId": "8794582"]]
        
        let jsonGhostPush = "{\"itbl\":{\"campaignId\":666,\"templateId\":777,\"isGhostPush\":true,\"messageId\":\"8794582\"}}"
        
        guard let dataGhostPush = jsonGhostPush.data(using: .utf8) else {
            XCTFail()
            return
        }
        
        do {
            let deserialized = try JSONSerialization.jsonObject(with: dataGhostPush) as! NSDictionary
            
            XCTAssertEqual(ghostPush, deserialized)
        } catch {
            XCTFail()
        }
        
        let realPush: NSDictionary = ["itbl": ["campaignId": 666,
                                               "templateId": 777,
                                               "isGhostPush": false,
                                               "messageId": "8794582"]]
        
        let jsonRealPush = "{\"itbl\":{\"campaignId\":666,\"templateId\":777,\"isGhostPush\":false,\"messageId\":\"8794582\"}}"
        
        guard let dataRealPush = jsonRealPush.data(using: .utf8) else {
            XCTFail()
            return
        }
        
        do {
            let deserialized = try JSONSerialization.jsonObject(with: dataRealPush) as! NSDictionary
            
            XCTAssertEqual(realPush, deserialized)
        } catch {
            XCTFail()
        }
    }
}
