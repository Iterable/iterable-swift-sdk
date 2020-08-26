//
//  Created by Tapash Majumder on 8/24/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class OfflineRequestProcessorTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        IterableLogUtil.sharedInstance = IterableLogUtil(dateProvider: SystemDateProvider(),
                                                         logDelegate: DefaultLogDelegate())
        try! persistenceContextProvider.mainQueueContext().deleteAllTasks()
        try! persistenceContextProvider.mainQueueContext().save()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func testRegister() throws {
        let registerTokenInfo = RegisterTokenInfo(hexToken: "zee-token",
                                                  appName: "zee-app-name",
                                                  pushServicePlatform: .auto,
                                                  apnsType: .sandbox,
                                                  deviceId: "deviceId",
                                                  deviceAttributes: [:],
                                                  sdkVersion: "6.x.x")
        
        let device = UIDevice.current
        let dataFields: [String: Any] = [
            "deviceId": registerTokenInfo.deviceId,
            "iterableSdkVersion": registerTokenInfo.sdkVersion!,
            "notificationsEnabled": true,
            "appPackageName": Bundle.main.appPackageName!,
            "appVersion": Bundle.main.appVersion!,
            "appBuild": Bundle.main.appBuild!,
            "localizedModel": device.localizedModel,
            "userInterfaceIdiom": "Phone",
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "model": device.model,
            "identifierForVendor": device.identifierForVendor!.uuidString
        ]
        let deviceDict: [String: Any] = [
            "token": registerTokenInfo.hexToken,
            "applicationName": registerTokenInfo.appName,
            "platform": "APNS_SANDBOX",
            "dataFields": dataFields
        ]
        let bodyDict: [String: Any] = [
            "device": deviceDict,
            "email": "user@example.com"
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.register(registerTokenInfo: registerTokenInfo,
                                      notificationStateProvider: MockNotificationStateProvider(enabled: true),
                                      onSuccess: nil,
                                      onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.registerDeviceToken,
                                                bodyDict: bodyDict)
    }

    func testDisableUserforCurrentUser() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
            "email": "user@example.com"
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.disableDeviceForCurrentUser(hexToken: hexToken,
                                                         withOnSuccess: nil,
                                                         onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.disableDevice,
                                                bodyDict: bodyDict)
    }

    func testDisableUserforAllUsers() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.disableDeviceForAllUsers(hexToken: hexToken,
                                                      withOnSuccess: nil,
                                                      onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.disableDevice,
                                                bodyDict: bodyDict)
    }

    func testTrackEvent() throws {
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]
        let bodyDict: [String: Any] = [
            "eventName": eventName,
            "dataFields": dataFields,
            "email": "user@example.com"
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.track(event: eventName,
                                   dataFields: dataFields,
                                   onSuccess: nil,
                                   onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackEvent,
                                                bodyDict: bodyDict)
    }

    func testUpdateUser() throws {
        let dataFields = ["var1": "val1", "var2": "val2"]
        let bodyDict: [String: Any] = [
            "dataFields": dataFields,
            "email": "user@example.com",
            "mergeNestedObjects": true
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.updateUser(dataFields,
                                        mergeNestedObjects: true,
                                        onSuccess: nil,
                                        onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateUser,
                                                bodyDict: bodyDict)
    }

    func testUpdateEmail() throws {
        let bodyDict: [String: Any] = [
            "currentEmail": "user@example.com",
            "newEmail": "new_user@example.com"
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.updateEmail("new_user@example.com",
                                         onSuccess: nil,
                                         onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateEmail,
                                                bodyDict: bodyDict)
    }

    private func processRequestWithSuccessAndFailure(requestGenerator: (RequestProcessorProtocol) -> Future<SendRequestValue, SendRequestError>,
                                                     path: String,
                                                     bodyDict: [AnyHashable: Any]) throws {
        let notificationCenter = MockNotificationCenter()
        let requestProcessor = createRequestProcessor(notificationCenter: notificationCenter)
        let request = { requestGenerator(requestProcessor) }
        processRequestWithSuccess(notificationCenter: notificationCenter,
                                  path: path,
                                  bodyDict: bodyDict,
                                  request: request)
        processRequestWithFailure(notificationCenter: notificationCenter,
                                  path: path,
                                  bodyDict: bodyDict,
                                  request: request)
    }
    
    private func createRequestProcessor(notificationCenter: NotificationCenterProtocol) -> RequestProcessorProtocol {
        OfflineRequestProcessor(apiKey: "zee-api-key",
                                authProvider: self,
                                endPoint: Endpoint.api,
                                deviceMetadata: deviceMetadata,
                                notificationCenter: notificationCenter)
    }
    
    private func processRequestWithSuccess(notificationCenter: NotificationCenterProtocol,
                                           path: String,
                                           bodyDict: [AnyHashable: Any],
                                           request: () -> Future<SendRequestValue, SendRequestError>) {
        let expectation1 = expectation(description: #function)
        
        request().onSuccess { json in
            expectation1.fulfill()
        }.onError { error in
            XCTFail()
        }
        
        validateRequest(networkSession: MockNetworkSession(),
                        path: path,
                        bodyDict: bodyDict,
                        notificationCenter: notificationCenter,
                        expectation: expectation1)
    }
    
    private func processRequestWithFailure(notificationCenter: NotificationCenterProtocol,
                                           path: String,
                                           bodyDict: [AnyHashable: Any],
                                           request: () -> Future<SendRequestValue, SendRequestError>) {
        let expectation1 = expectation(description: #function)
        
        request().onSuccess { json in
            XCTFail()
        }.onError { error in
            expectation1.fulfill()
        }
        
        validateRequest(networkSession: MockNetworkSession(statusCode: 400),
                        path: path,
                        bodyDict: bodyDict,
                        notificationCenter: notificationCenter,
                        expectation: expectation1)
    }
    
    private func validateRequest(networkSession: MockNetworkSession,
                                 path: String, bodyDict: [AnyHashable : Any],
                                 notificationCenter: NotificationCenterProtocol,
                                 expectation: XCTestExpectation) {
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5)
        taskRunner.start()
        wait(for: [expectation], timeout: 15.0)
        taskRunner.stop()
    }
    
    private let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                platform: JsonValue.iOS.jsonStringValue,
                                                appPackageName: Bundle.main.appPackageName ?? "")
    
    private let dateProvider = MockDateProvider()
    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)
        return provider
    }()
}

extension OfflineRequestProcessorTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil)
    }
}
