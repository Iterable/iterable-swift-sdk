//
//  File.swift
//  
//
//  Created by evan.greer@iterable.com on 4/5/23.
//

import XCTest

final class IterableConfigTests: XCTestCase {
    func testDefaultConfig() {
        let config = IterableConfig()
        
        XCTAssertEqual(config.pushIntegrationName, undefined)
        XCTAssertEqual(config.sandboxPushIntegrationName, undefined)
        XCTAssertEqual(config.pushPlatform, PushServicePlatform.auto)
        XCTAssertEqual(config.urlDelegate, undefined)
        XCTAssertEqual(config.customActionDelegate, undefined)
        XCTAssertEqual(config.authDelegate, undefined)
        XCTAssertEqual(config.autoPushRegistration, true)
        XCTAssertEqual(config.checkForDeferredDeeplink, false)
        XCTAssertEqual(config.logDelegate, DefaultLogDelegate())
        XCTAssertEqual(config.inAppDelegate, DefaultInAppDelegate())
        XCTAssertEqual(config.inAppDisplayInterval, 30.0)
        XCTAssertEqual(config.expiringAuthTokenRefreshPeriod, 60.0)
        XCTAssertEqual(config.allowedProtocols, [])
        XCTAssertEqual(config.useInMemoryStorageForInApps, false)
        XCTAssertEqual(config.dataRegion, IterableDataRegion.US)
    }
}
