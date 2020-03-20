//
//  Created by Jay Kim on 5/29/19.
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
}
