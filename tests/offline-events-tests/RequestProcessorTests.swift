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
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.register(registerTokenInfo: registerTokenInfo,
                                      notificationStateProvider: MockNotificationStateProvider(enabled: true),
                                      onSuccess: expectations.onSuccess,
                                      onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.registerDeviceToken,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }
    
    func testDisableUserforCurrentUser() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
            "email": "user@example.com"
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.disableDeviceForCurrentUser(hexToken: hexToken,
                                                         withOnSuccess: expectations.onSuccess,
                                                         onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.disableDevice,
                                                bodyDict: bodyDict)

        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }
    
    func testDisableUserforAllUsers() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.disableDeviceForAllUsers(hexToken: hexToken,
                                                      withOnSuccess: expectations.onSuccess,
                                                      onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.disableDevice,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }
    
    func testUpdateUser() throws {
        let dataFields = ["var1": "val1", "var2": "val2"]
        let bodyDict: [String: Any] = [
            "dataFields": dataFields,
            "email": "user@example.com",
            "mergeNestedObjects": true
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.updateUser(dataFields,
                                        mergeNestedObjects: true,
                                        onSuccess: expectations.onSuccess,
                                        onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateUser,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }
    
    func testUpdateEmail() throws {
        let bodyDict: [String: Any] = [
            "currentEmail": "user@example.com",
            "newEmail": "new_user@example.com"
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.updateEmail("new_user@example.com",
                                         onSuccess: expectations.onSuccess,
                                         onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateEmail,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
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
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackPurchase(total,
                                           items: items,
                                           dataFields: dataFields,
                                           onSuccess: expectations.onSuccess,
                                           onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPurchase,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
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
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackPushOpen(NSNumber(value: campaignId),
                                           templateId: NSNumber(value: templateId),
                                           messageId: messageId,
                                           appAlreadyRunning: appAlreadyRunning,
                                           dataFields: dataFields,
                                           onSuccess: expectations.onSuccess,
                                           onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPushOpen,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackEvent() throws {
        let eventName = "CustomEvent1"
        let dataFields = ["var1": "val1", "var2": "val2"]
        let bodyDict: [String: Any] = [
            "eventName": eventName,
            "dataFields": dataFields,
            "email": "user@example.com"
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.track(event: eventName,
                                   dataFields: dataFields,
                                   onSuccess: expectations.onSuccess,
                                   onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackEvent,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
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
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.updateSubscriptions(info: info,
                                                 onSuccess: expectations.onSuccess,
                                                 onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateSubscriptions,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInAppOpen() throws {
        let messageId = "message_id"
        let message = InAppTestHelper.emptyInAppMessage(messageId: messageId)
        let inboxSessionId = "ibx1"
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "inboxSessionId": inboxSessionId,
            "deviceInfo": deviceMetadata.asDictionary()!,
            "messageContext": [
                "location": "in-app",
                "saveToInbox": false,
                "silentInbox": false,
            ],
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackInAppOpen(message,
                                            location: .inApp,
                                            inboxSessionId: inboxSessionId,
                                            onSuccess: expectations.onSuccess,
                                            onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppOpen,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInAppClick() throws {
        let messageId = "message_id"
        let message = InAppTestHelper.emptyInAppMessage(messageId: messageId)
        let inboxSessionId = "ibx1"
        let clickedUrl = "https://somewhere.com"
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "inboxSessionId": inboxSessionId,
            "deviceInfo": deviceMetadata.asDictionary()!,
            "clickedUrl": clickedUrl,
            "messageContext": [
                "location": "inbox",
                "saveToInbox": false,
                "silentInbox": false,
            ],
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackInAppClick(message,
                                             location: .inbox,
                                             inboxSessionId: inboxSessionId,
                                             clickedUrl: clickedUrl,
                                             onSuccess: expectations.onSuccess,
                                             onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppClick,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInAppClose() throws {
        let messageId = "message_id"
        let message = InAppTestHelper.emptyInAppMessage(messageId: messageId)
        let inboxSessionId = "ibx1"
        let clickedUrl = "https://closeme.com"
        let closeSource = InAppCloseSource.link
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "inboxSessionId": inboxSessionId,
            "deviceInfo": deviceMetadata.asDictionary()!,
            "clickedUrl": clickedUrl,
            "messageContext": [
                "location": "inbox",
                "saveToInbox": false,
                "silentInbox": false,
            ],
            "closeAction": "link",
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackInAppClose(message, location: .inbox,
                                             inboxSessionId: inboxSessionId,
                                             source: closeSource,
                                             clickedUrl: clickedUrl,
                                             onSuccess: expectations.onSuccess,
                                             onFailure: expectations.onFailure)
            
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppClose,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInboxSession() throws {
        let inboxSessionId = IterableUtil.generateUUID()
        let startDate = dateProvider.currentDate
        let endDate = startDate.addingTimeInterval(60 * 5)
        let impressions = [
            IterableInboxImpression(messageId: "message1", silentInbox: true, displayCount: 2, displayDuration: 1.23),
            IterableInboxImpression(messageId: "message2", silentInbox: false, displayCount: 3, displayDuration: 2.34),
        ]
        let inboxSession = IterableInboxSession(id: inboxSessionId,
                                                sessionStartTime: startDate,
                                                sessionEndTime: endDate,
                                                startTotalMessageCount: 15,
                                                startUnreadMessageCount: 5,
                                                endTotalMessageCount: 10,
                                                endUnreadMessageCount: 3,
                                                impressions: impressions)
        
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "inboxSessionId": inboxSessionId,
            "inboxSessionStart": IterableUtil.int(fromDate: startDate),
            "inboxSessionEnd": IterableUtil.int(fromDate: endDate),
            "startTotalMessageCount": inboxSession.startTotalMessageCount,
            "startUnreadMessageCount": inboxSession.startUnreadMessageCount,
            "endTotalMessageCount": inboxSession.endTotalMessageCount,
            "endUnreadMessageCount": inboxSession.endUnreadMessageCount,
            "impressions": impressions.compactMap { $0.asDictionary() },
            "deviceInfo": deviceMetadata.asDictionary()!,
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.track(inboxSession: inboxSession,
                                   onSuccess: expectations.onSuccess,
                                   onFailure: expectations.onFailure)
            
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInboxSession,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInAppDelivery() throws {
        let messageId = "message_id"
        let message = InAppTestHelper.emptyInAppMessage(messageId: messageId)

        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "messageContext": [
                "saveToInbox": false,
                "silentInbox": false,
            ],
            "deviceInfo": deviceMetadata.asDictionary()!,
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.track(inAppDelivery: message,
                                   onSuccess: expectations.onSuccess,
                                   onFailure: expectations.onFailure)
            
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppDelivery,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }
    
    func testTrackInAppConsume() throws {
        let messageId = "message_id"

        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.inAppConsume(messageId,
                                          onSuccess: expectations.onSuccess,
                                          onFailure: expectations.onFailure)
            
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.inAppConsume,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInAppConsume2() throws {
        let messageId = "message_id"
        let message = InAppTestHelper.emptyInAppMessage(messageId: messageId)
        let location = InAppLocation.inbox
        let source = InAppDeleteSource.deleteButton
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "messageContext": [
                "location": "inbox",
                "saveToInbox": false,
                "silentInbox": false,
            ],
            "deleteAction": "delete-button",
            "deviceInfo": deviceMetadata.asDictionary()!,
        ]

        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.inAppConsume(message: message,
                                          location: location,
                                          source: source,
                                          onSuccess: expectations.onSuccess,
                                          onFailure: expectations.onFailure)
            
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.inAppConsume,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }
    
    func testTrackInAppOpen2() throws {
        let messageId = "message_id"
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "deviceInfo": deviceMetadata.asDictionary()!,
            "messageContext": [
                "location": "in-app",
                "saveToInbox": false,
                "silentInbox": false,
            ],
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackInAppOpen(messageId,
                                            onSuccess: expectations.onSuccess,
                                            onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppOpen,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
    }

    func testTrackInAppClick2() throws {
        let messageId = "message_id"
        let clickedUrl = "https://somewhere.com"
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "deviceInfo": deviceMetadata.asDictionary()!,
            "clickedUrl": clickedUrl,
            "messageContext": [
                "location": "in-app",
                "saveToInbox": false,
                "silentInbox": false,
            ],
        ]
        
        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestProcessor: RequestProcessorProtocol) in
            requestProcessor.trackInAppClick(messageId,
                                             clickedUrl: clickedUrl,
                                             onSuccess: expectations.onSuccess,
                                             onFailure: expectations.onFailure)
        }
        
        try processRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppClick,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: 15.0)
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
                         authManager: nil,
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
    
    struct Exp {
        let successExpectation: XCTestExpectation
        let onSuccess: OnSuccessHandler
        let failureExpectation: XCTestExpectation
        let onFailure: OnFailureHandler
    }
    
    private func createExpectations(description: String) -> Exp {
        let (successExpectation, onSuccess) = createSuccessExpectation(description: "success: \(description)")
        let (failureExpectation, onFailure) = createFailureExpectation(description: "failure: \(description)")
        return Exp(successExpectation: successExpectation,
                   onSuccess: onSuccess,
                   failureExpectation: failureExpectation,
                   onFailure: onFailure)
    }
    
    private func createSuccessExpectation(description: String) -> (XCTestExpectation, OnSuccessHandler) {
        let expectation1 = expectation(description: description)
        expectation1.expectedFulfillmentCount = 2
        let onSuccess: OnSuccessHandler = { _ in
            expectation1.fulfill()
        }
        return (expectation: expectation1, onSuccess: onSuccess)
    }
    
    private func createFailureExpectation(description: String) -> (XCTestExpectation, OnFailureHandler) {
        let expectation1 = expectation(description: description)
        expectation1.expectedFulfillmentCount = 2
        let onFailure: OnFailureHandler = { _, _ in
            expectation1.fulfill()
        }
        return (expectation: expectation1, onFailure: onFailure)
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
