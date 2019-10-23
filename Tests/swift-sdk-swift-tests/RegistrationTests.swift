//
//  Created by Tapash Majumder on 10/9/19.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class RegistrationTests: XCTestCase {
    private let apiKey = "zeeApiKey"
    
    override func setUp() {
        super.setUp()
        
        TestUtils.clearTestUserDefaults()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRegisterTokenWithProductionPlatform() {
        let expectation = XCTestExpectation(description: "testRegisterToken")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.sandboxPushIntegrationName = "my-sandbox-push-integration"
        config.pushPlatform = .production
        IterableAPI.initializeForTesting(apiKey: apiKey,
                                         config: config,
                                         networkSession: networkSession,
                                         notificationStateProvider: MockNotificationStateProvider(enabled: true))
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.email), value: "user@example.com", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .applicationName), value: "my-push-integration", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .platform), value: JsonValue.apnsProduction.jsonValue as! String, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .token), value: token.hexString(), inDictionary: body)
            
            // device dictionary
            let appPackageName = TestUtils.appPackageName
            let appVersion = TestUtils.appVersion
            let appBuild = TestUtils.appBuild
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .identifierForVendor), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .deviceId), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .localizedModel), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .userInterfaceIdiom), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .systemName), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .systemVersion), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(.device, .dataFields, .model), type: String.self, inDictionary: body)
            
            TestUtils.validateMatch(keyPath: KeyPath(.device, .dataFields, .iterableSdkVersion), value: IterableAPI.sdkVersion, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .dataFields, .appPackageName), value: appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .dataFields, .appVersion), value: appVersion, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .dataFields, .appBuild), value: appBuild, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .dataFields, .notificationsEnabled), value: true, inDictionary: body)
            expectation.fulfill()
        }) { reason, _ in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testRegisterTokenWithSandboxPlatform() {
        let expectation = XCTestExpectation(description: "testRegisterToken")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.sandboxPushIntegrationName = "my-sandbox-push-integration"
        config.pushPlatform = .sandbox
        IterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.device, .applicationName), value: config.sandboxPushIntegrationName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .platform), value: JsonValue.apnsSandbox.jsonValue as! String, inDictionary: body)
            expectation.fulfill()
        }) { reason, _ in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testRegisterTokenWithAutoPlatformChooseSandbox() {
        let expectation = XCTestExpectation(description: "testRegisterTokenWithAutoPlatformChooseSandbox")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.sandboxPushIntegrationName = "my-sandbox-push-integration"
        config.pushPlatform = .auto
        IterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession, apnsTypeChecker: MockAPNSTypeChecker(apnsType: .sandbox))
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.device, .applicationName), value: config.sandboxPushIntegrationName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .platform), value: JsonValue.apnsSandbox.jsonValue as! String, inDictionary: body)
            expectation.fulfill()
        }) { reason, _ in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testRegisterTokenWithAutoPlatformChooseProduction() {
        let expectation = XCTestExpectation(description: "testRegisterTokenWithAutoPlatformChooseProduction")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushIntegrationName = "my-push-integration"
        config.sandboxPushIntegrationName = "my-sandbox-push-integration"
        config.pushPlatform = .auto
        IterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession, apnsTypeChecker: MockAPNSTypeChecker(apnsType: .production))
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.device, .applicationName), value: config.pushIntegrationName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .platform), value: JsonValue.apnsProduction.jsonValue as! String, inDictionary: body)
            expectation.fulfill()
        }) { reason, _ in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testRegisterTokenWithAutoPlatformAndNoIntegrationNameChooseSandbox() {
        let expectation = XCTestExpectation(description: "testRegisterTokenWithAutoPlatformAndNoIntegrationNameChooseSandbox")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushPlatform = .auto
        IterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession)
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.device, .applicationName), value: TestUtils.appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .platform), value: JsonValue.apnsSandbox.jsonValue as! String, inDictionary: body)
            expectation.fulfill()
        }) { reason, _ in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
    
    func testRegisterTokenWithAutoPlatformAndNoIntegrationNameChooseProduction() {
        let expectation = XCTestExpectation(description: "testRegisterTokenWithAutoPlatformAndNoIntegrationNameChooseProduction")
        
        let networkSession = MockNetworkSession(statusCode: 200)
        let config = IterableConfig()
        config.pushPlatform = .auto
        IterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession, apnsTypeChecker: MockAPNSTypeChecker(apnsType: .production))
        IterableAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        IterableAPI.register(token: token, onSuccess: { _ in
            let body = networkSession.getRequestBody() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(.device, .applicationName), value: TestUtils.appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(.device, .platform), value: JsonValue.apnsProduction.jsonValue as! String, inDictionary: body)
            expectation.fulfill()
        }) { reason, _ in
            // failure
            if let reason = reason {
                XCTFail("encountered error: \(reason)")
            } else {
                XCTFail("encountered error")
            }
        }
        
        // only wait for small time, supposed to error out
        wait(for: [expectation], timeout: testExpectationTimeout)
    }
}
