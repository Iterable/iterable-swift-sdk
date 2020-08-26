//
//  Created by Tapash Majumder on 8/24/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class RequestProcessorTests: XCTestCase {
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
    
    func testTrackPurchase() throws {
        let total = NSNumber(value: 15.32)
        let items = [CommerceItem(id: "id1", name: "myCommerceItem", price: 5.1, quantity: 2)]
        let dataFields = ["var1": "val1", "var2": "val2"]

        let bodyDict: [String: Any] = [
            "items": [[
                "id": items[0].id,
                "name": items[0].name,
                "price": items[0].price,
                "quantity": items[0].quantity,
            ]],
            "total": total,
            "dataFields": dataFields,
            "user": [
                "email": "user@example.com",
            ],
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackPurchase(total,
                                           items: items,
                                           dataFields: dataFields,
                                           onSuccess: nil,
                                           onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPurchase,
                                                bodyDict: bodyDict)
    }

    func testTrackPushOpen() throws {
        let campaignId = 1
        let templateId = 2
        let messageId = "message_id"
        let appAlreadyRunning = true
        let dataFields: [String: Any] = [
            "var1": "val1",
            "var2": "val2",
        ]
        var bodyDataFields = dataFields
        bodyDataFields["appAlreadyRunning"] = appAlreadyRunning
        let bodyDict: [String: Any] = [
            "dataFields": bodyDataFields,
            "campaignId": campaignId,
            "templateId": templateId,
            "messageId": messageId,
            "email": "user@example.com"
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackPushOpen(NSNumber(value: campaignId),
                                           templateId: NSNumber(value: templateId),
                                           messageId: messageId,
                                           appAlreadyRunning: appAlreadyRunning,
                                           dataFields: dataFields,
                                           onSuccess: nil,
                                           onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPushOpen,
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
    
    func testUpdateSubscriptions() throws {
        let info = UpdateSubscriptionsInfo(emailListIds: [123],
                                           unsubscribedChannelIds: [456],
                                           unsubscribedMessageTypeIds: [789],
                                           subscribedMessageTypeIds: [111],
                                           campaignId: 1,
                                           templateId: 2)
        let bodyDict: [String: Any] = [
            "emailListIds": info.emailListIds!,
            "unsubscribedChannelIds": info.unsubscribedChannelIds!,
            "unsubscribedMessageTypeIds": info.unsubscribedMessageTypeIds!,
            "subscribedMessageTypeIds": info.subscribedMessageTypeIds!,
            "campaignId": info.campaignId!,
            "templateId": info.templateId!,
            "email": "user@example.com"
        ]
        
        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.updateSubscriptions(info: info,
                                                 onSuccess: nil,
                                                 onFailure: nil)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateSubscriptions,
                                                bodyDict: bodyDict)
    }

    private func processRequestWithSuccessAndFailure(requestGenerator: (RequestProcessorProtocol) -> Future<SendRequestValue, SendRequestError>,
                                                     path: String,
                                                     bodyDict: [AnyHashable: Any]) throws {
        
        processOnlineRequestWithSuccess(requestGenerator: requestGenerator,
                                        path: path,
                                        bodyDict: bodyDict)
        processOnlineRequestWithFailure(requestGenerator: requestGenerator,
                                        path: path,
                                        bodyDict: bodyDict)
        processOfflineRequestWithSuccess(requestGenerator: requestGenerator,
                                         path: path,
                                         bodyDict: bodyDict)
        processOfflineRequestWithFailure(requestGenerator: requestGenerator,
                                         path: path,
                                         bodyDict: bodyDict)
    }
    
    private func processOnlineRequestWithSuccess(requestGenerator: (RequestProcessorProtocol) -> Future<SendRequestValue, SendRequestError>,
                                                 path: String,
                                                 bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestProcessor = createRequestProcessor(networkSession: networkSession,
                                                      notificationCenter: notificationCenter,
                                                      selectOffline: false)
        let request = { requestGenerator(requestProcessor) }
        let expectation1 = expectation(description: #function)
        processRequestWithSuccess(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        wait(for: [expectation1], timeout: 15.0)
    }
    
    private func processOnlineRequestWithFailure(requestGenerator: (RequestProcessorProtocol) -> Future<SendRequestValue, SendRequestError>,
                                                 path: String,
                                                 bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession(statusCode: 400)
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestProcessor = createRequestProcessor(networkSession: networkSession,
                                                      notificationCenter: notificationCenter,
                                                      selectOffline: false)
        let request = { requestGenerator(requestProcessor) }
        let expectation1 = expectation(description: #function)
        processRequestWithFailure(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        wait(for: [expectation1], timeout: 15.0)
    }
    
    private func processOfflineRequestWithSuccess(requestGenerator: (RequestProcessorProtocol) -> Future<SendRequestValue, SendRequestError>,
                                                  path: String,
                                                  bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestProcessor = createRequestProcessor(networkSession: networkSession,
                                                      notificationCenter: notificationCenter,
                                                      selectOffline: true)
        let request = { requestGenerator(requestProcessor) }
        let expectation1 = expectation(description: #function)
        processRequestWithSuccess(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        waitForTaskRunner(networkSession: networkSession,
                          notificationCenter: notificationCenter,
                          expectation: expectation1)
    }
    
    private func processOfflineRequestWithFailure(requestGenerator: (RequestProcessorProtocol) -> Future<SendRequestValue, SendRequestError>,
                                                  path: String,
                                                  bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession(statusCode: 400)
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestProcessor = createRequestProcessor(networkSession: networkSession,
                                                      notificationCenter: notificationCenter,
                                                      selectOffline: true)
        let request = { requestGenerator(requestProcessor) }
        let expectation1 = expectation(description: #function)
        processRequestWithFailure(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        waitForTaskRunner(networkSession: networkSession,
                          notificationCenter: notificationCenter,
                          expectation: expectation1)
    }
    
    private func createRequestProcessor(networkSession: NetworkSessionProtocol,
                                        notificationCenter: NotificationCenterProtocol,
                                        selectOffline: Bool) -> RequestProcessorProtocol {
        RequestProcessor(apiKey: "zee-api-key",
                         authProvider: self,
                         endPoint: Endpoint.api,
                         deviceMetadata: deviceMetadata,
                         networkSession: networkSession,
                         notificationCenter: notificationCenter,
                         strategy: DefaultRequestProcessorStrategy(selectOffline: selectOffline))
    }
    
    private func processRequestWithSuccess(request: () -> Future<SendRequestValue, SendRequestError>,
                                           networkSession: MockNetworkSession,
                                           path: String,
                                           bodyDict: [AnyHashable: Any],
                                           expectation: XCTestExpectation) {
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        
        request().onSuccess { json in
            expectation.fulfill()
        }.onError { error in
            XCTFail()
        }
    }
    
    private func processRequestWithFailure(request: () -> Future<SendRequestValue, SendRequestError>,
                                           networkSession: MockNetworkSession,
                                           path: String,
                                           bodyDict: [AnyHashable: Any],
                                           expectation: XCTestExpectation) {
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        request().onSuccess { json in
            XCTFail()
        }.onError { error in
            expectation.fulfill()
        }
    }
    
    private func waitForTaskRunner(networkSession: NetworkSessionProtocol,
                                   notificationCenter: NotificationCenterProtocol,
                                   expectation: XCTestExpectation) {
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

extension RequestProcessorTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil)
    }
}
