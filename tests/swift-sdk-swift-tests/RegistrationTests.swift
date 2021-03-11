//
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class RegistrationTests: XCTestCase {
    private let apiKey = "zeeApiKey"
    
    override func setUp() {
        super.setUp()
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
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey,
                                                                   config: config,
                                                                   networkSession: networkSession,
                                                                   notificationStateProvider: MockNotificationStateProvider(enabled: true))
        internalAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        internalAPI.register(token: token, onSuccess: { _ in
            let request = networkSession.getRequest(withEndPoint: Const.Path.registerDeviceToken)!
            let body = request.httpBody!.json() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.email), value: "user@example.com", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.applicationName), value: "my-push-integration", inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.platform), value: JsonValue.apnsProduction.jsonValue as! String, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.token), value: token.hexString(), inDictionary: body)
            
            // device dictionary
            let appPackageName = TestUtils.appPackageName
            let appVersion = TestUtils.appVersion
            let appBuild = TestUtils.appBuild
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.identifierForVendor), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.deviceId), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.localizedModel), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.userInterfaceIdiom), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.systemName), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.systemVersion), type: String.self, inDictionary: body)
            TestUtils.validateExists(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.model), type: String.self, inDictionary: body)
            
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.iterableSdkVersion), value: IterableAPI.sdkVersion, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.appPackageName), value: appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.appVersion), value: appVersion, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.appBuild), value: appBuild, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.dataFields, JsonKey.notificationsEnabled), value: true, inDictionary: body)
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
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession)
        internalAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        internalAPI.register(token: token, onSuccess: { _ in
            let request = networkSession.getRequest(withEndPoint: Const.Path.registerDeviceToken)!
            let body = request.httpBody!.json() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.applicationName), value: config.sandboxPushIntegrationName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.platform), value: JsonValue.apnsSandbox.jsonValue as! String, inDictionary: body)
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
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession, apnsTypeChecker: MockAPNSTypeChecker(apnsType: .sandbox))
        internalAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        internalAPI.register(token: token, onSuccess: { _ in
            let request = networkSession.getRequest(withEndPoint: Const.Path.registerDeviceToken)!
            let body = request.httpBody!.json() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.applicationName), value: config.sandboxPushIntegrationName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.platform), value: JsonValue.apnsSandbox.jsonValue as! String, inDictionary: body)
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
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession, apnsTypeChecker: MockAPNSTypeChecker(apnsType: .production))
        internalAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        internalAPI.register(token: token, onSuccess: { _ in
            let request = networkSession.getRequest(withEndPoint: Const.Path.registerDeviceToken)!
            let body = request.httpBody!.json() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.applicationName), value: config.pushIntegrationName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.platform), value: JsonValue.apnsProduction.jsonValue as! String, inDictionary: body)
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
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession)
        internalAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        internalAPI.register(token: token, onSuccess: { _ in
            let request = networkSession.getRequest(withEndPoint: Const.Path.registerDeviceToken)!
            let body = request.httpBody!.json() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.applicationName), value: TestUtils.appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.platform), value: JsonValue.apnsSandbox.jsonValue as! String, inDictionary: body)
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
        let internalAPI = InternalIterableAPI.initializeForTesting(apiKey: apiKey, config: config, networkSession: networkSession, apnsTypeChecker: MockAPNSTypeChecker(apnsType: .production))
        internalAPI.email = "user@example.com"
        let token = "zeeToken".data(using: .utf8)!
        internalAPI.register(token: token, onSuccess: { _ in
            let request = networkSession.getRequest(withEndPoint: Const.Path.registerDeviceToken)!
            let body = request.httpBody!.json() as! [String: Any]
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.applicationName), value: TestUtils.appPackageName, inDictionary: body)
            TestUtils.validateMatch(keyPath: KeyPath(keys: JsonKey.device, JsonKey.platform), value: JsonValue.apnsProduction.jsonValue as! String, inDictionary: body)
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
