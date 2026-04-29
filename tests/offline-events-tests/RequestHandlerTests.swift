//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

let testExpectationTimeout = 15.0 // How long to wait when we expect to succeed
let testExpectationTimeoutForInverted = 1.0 // How long to wait when we expect to fail

class RequestHandlerTests: XCTestCase {
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
                                                  sdkVersion: "6.x.x",
                                                  mobileFrameworkInfo: IterableAPIMobileFrameworkInfo(frameworkType: .native, iterableSdkVersion: "6.x.x"))
        
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
            "identifierForVendor": device.identifierForVendor!.uuidString,
            "mobileFrameworkInfo": [
                "frameworkType": "native",
                "iterableSdkVersion": "6.x.x"
            ]
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

        let expectation1 = expectation(description: #function)
        let networkSession = MockNetworkSession()
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: MockNotificationCenter(),
                                                  selectOffline: false)
        requestHandler.register(registerTokenInfo: registerTokenInfo,
                                notificationStateProvider: MockNotificationStateProvider(enabled: true),
                                onSuccess: nil,
                                onFailure: nil)

        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: Const.Path.registerDeviceToken)
            var requestBody = request.bodyDict
            requestBody.removeValue(forKey: "createdAt")
            
            // Compare each field individually for better error messages
            let requestDevice = requestBody["device"] as! [String: Any]
            let requestDataFields = requestDevice["dataFields"] as! [String: Any]
            let expectedDevice = deviceDict
            let expectedDataFields = dataFields
            
            XCTAssertEqual(requestDevice["token"] as? String, expectedDevice["token"] as? String, "token mismatch")
            XCTAssertEqual(requestDevice["applicationName"] as? String, expectedDevice["applicationName"] as? String, "applicationName mismatch")
            XCTAssertEqual(requestDevice["platform"] as? String, expectedDevice["platform"] as? String, "platform mismatch")
            
            for (key, value) in expectedDataFields {
                XCTAssertEqual(requestDataFields[key] as? String, value as? String, "\(key) mismatch")
            }
            
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testDisableUserforCurrentUser() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
            "email": "user@example.com"
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.disableDeviceForCurrentUser(hexToken: hexToken,
                                                       withOnSuccess: expectations.onSuccess,
                                                       onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.disableDevice,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testDisableUserforAllUsers() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
        ]

        let expectations = createExpectations(description: #function)

        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.disableDeviceForAllUsers(hexToken: hexToken,
                                                    withOnSuccess: expectations.onSuccess,
                                                    onFailure: expectations.onFailure)
        }

        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.disableDevice,
                                                bodyDict: bodyDict)

        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }

    // Dedicated visibility test for the offline path on the all-users variant.
    // `testDisableUserforAllUsers` above already exercises offline-success and
    // offline-failure via `handleRequestWithSuccessAndFailure`, but the coverage
    // isn't obvious from the test name. This one calls out the offline path
    // explicitly so the regression is locked in.
    func testOfflineDisableDeviceForAllUsersReplaysWithExpectedBody() throws {
        let hexToken = "zee-token"
        let bodyDict: [String: Any] = [
            "token": hexToken,
        ]

        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.disableDeviceForAllUsers(hexToken: hexToken,
                                                    withOnSuccess: nil,
                                                    onFailure: nil)
        }

        handleOfflineRequestWithSuccess(requestGenerator: requestGenerator,
                                        path: Const.Path.disableDevice,
                                        bodyDict: bodyDict)
    }

    // Regression for SDK-297 P1: the offline queue must bake in the identity that was
    // current at call time. `logoutPreviousUser()` (and `setEmail`/`setUserId`) clear
    // `_email`/`_userId` synchronously after invoking `disableDeviceForCurrentUser`, so
    // the replayed request would otherwise target the wrong user (or no user, collapsing
    // into the all-users payload).
    func testDisableDeviceForCurrentUserCapturesIdentityAtCallTime() throws {
        let originalEmail = "original@example.com"
        let mutatedEmail = "mutated@example.com"
        let hexToken = "zee-token"
        let expectedBody: [String: Any] = [
            "token": hexToken,
            "email": originalEmail,
        ]

        let mutableAuth = MutableAuthProvider(
            initial: Auth(userId: nil, email: originalEmail, authToken: nil, userIdUnknownUser: nil)
        )

        let bodyValidated = expectation(description: #function)
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: Const.Path.disableDevice)
            var requestBody = request.bodyDict
            requestBody.removeValue(forKey: "createdAt")
            XCTAssertTrue(TestUtils.areEqual(dict1: expectedBody, dict2: requestBody),
                          "replayed body should carry the identity captured at call time, got \(requestBody)")
            bodyValidated.fulfill()
        }

        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: MockNotificationCenter(),
                                                  selectOffline: true,
                                                  authProvider: mutableAuth)

        requestHandler.disableDeviceForCurrentUser(hexToken: hexToken,
                                                   withOnSuccess: nil,
                                                   onFailure: nil)
        // Simulate `logoutPreviousUser()` nulling identity immediately after the call.
        mutableAuth.currentAuth = Auth(userId: nil, email: mutatedEmail, authToken: nil, userIdUnknownUser: nil)

        waitForTaskRunner(requestHandler: requestHandler, expectation: bodyValidated)
    }

    // Regression for the fail-loud guard added in review: when no current user is
    // set (auth is `.none`), `RequestHandler.disableDeviceForCurrentUser` must
    // surface the error via `onFailure` instead of letting the request fall through
    // to `setCurrentUser(inDict:)` and reading live auth at request-build time.
    func testDisableDeviceForCurrentUserWithNoIdentityFailsLoudly() throws {
        let emptyAuth = MutableAuthProvider(
            initial: Auth(userId: nil, email: nil, authToken: nil, userIdUnknownUser: nil)
        )

        let onFailureCalled = expectation(description: "onFailure invoked")
        var capturedReason: String?

        let requestHandler = createRequestHandler(networkSession: MockNetworkSession(),
                                                  notificationCenter: MockNotificationCenter(),
                                                  selectOffline: true,
                                                  authProvider: emptyAuth)

        requestHandler.disableDeviceForCurrentUser(
            hexToken: "zee-token",
            withOnSuccess: { _ in
                XCTFail("onSuccess must not fire when no current user is set")
            },
            onFailure: { reason, _ in
                capturedReason = reason
                onFailureCalled.fulfill()
            }
        )

        wait(for: [onFailureCalled], timeout: testExpectationTimeout)
        XCTAssertEqual(capturedReason,
                       "disableDeviceForCurrentUser called without a current user identity")
    }

    // Regression for SDK-297 P2 round 2: when offline mode is enabled but
    // `HealthMonitor.canSchedule()` returns false, `RequestHandler` falls back to the
    // online processor. The caller-captured identity snapshot must still be honored by
    // that fallback path so the request doesn't race live `auth` mutations.
    func testOnlineDisableDeviceForCurrentUserHonorsIdentitySnapshot() throws {
        let snapshotEmail = "captured@example.com"
        let hexToken = "zee-token"
        let expectedBody: [String: Any] = [
            "token": hexToken,
            "email": snapshotEmail,
        ]

        let bodyValidated = expectation(description: #function)
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: Const.Path.disableDevice)
            var requestBody = request.bodyDict
            requestBody.removeValue(forKey: "createdAt")
            XCTAssertTrue(TestUtils.areEqual(dict1: expectedBody, dict2: requestBody),
                          "online fallback body should use the snapshot, got \(requestBody)")
            bodyValidated.fulfill()
        }

        // `self` (the test class) conforms to AuthProvider with email="user@example.com",
        // so passing a *different* snapshot email proves the online path used the
        // snapshot rather than live `auth`.
        let onlineProcessor = OnlineRequestProcessor(apiKey: "zee-api-key",
                                                     authProvider: self,
                                                     authManager: nil,
                                                     endpoint: Endpoint.api,
                                                     networkSession: networkSession,
                                                     deviceMetadata: Self.deviceMetadata,
                                                     dateProvider: dateProvider)

        onlineProcessor.disableDeviceForCurrentUser(hexToken: hexToken,
                                                    identitySnapshot: .email(snapshotEmail),
                                                    withOnSuccess: nil,
                                                    onFailure: nil)

        wait(for: [bodyValidated], timeout: testExpectationTimeout)
    }

    // Regression for SDK-297 P2: the offline disable-device task must carry the literal
    // "disableDevice" request identifier so `RequestProcessorUtil.resetAuthRetries` skips
    // this request class on success. If the identifier drifts (e.g. `#function`), a
    // queued JWT 401 followed by a successful disable would incorrectly flip auth state
    // back to "valid" and resume auth-paused tasks.
    func testDisableDeviceForCurrentUserSuccessDoesNotResetAuthRetries() throws {
        let hexToken = "zee-token"

        let authManager = MockAuthManager()
        // Simulate the state an offline queue is in after a prior JWT 401.
        authManager.pauseAuthRetries = true
        authManager.isLastAuthTokenValid = false
        authManager.failedAuthCount = 3

        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession() // 200 OK
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let taskScheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                                  notificationCenter: notificationCenter,
                                                  healthMonitor: healthMonitor,
                                                  dateProvider: dateProvider)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            dateProvider: dateProvider)
        let offlineProcessor = OfflineRequestProcessor(apiKey: "zee-api-key",
                                                       authProvider: self,
                                                       authManager: authManager,
                                                       endpoint: Endpoint.api,
                                                       deviceMetadata: Self.deviceMetadata,
                                                       taskScheduler: taskScheduler,
                                                       taskRunner: taskRunner,
                                                       notificationCenter: notificationCenter)

        offlineProcessor.start()
        let onSuccessCalled = expectation(description: "disableDevice onSuccess")
        offlineProcessor.disableDeviceForCurrentUser(hexToken: hexToken,
                                                     identitySnapshot: .email("user@example.com"),
                                                     withOnSuccess: { _ in onSuccessCalled.fulfill() },
                                                     onFailure: nil)

        wait(for: [onSuccessCalled], timeout: testExpectationTimeout)
        offlineProcessor.stop()

        // Auth-pause state must be preserved — the "disableDevice" identifier opts
        // out of the `resetAuthRetries` branch in RequestProcessorUtil.
        XCTAssertTrue(authManager.pauseAuthRetries, "pauseAuthRetries must stay true after a disable-device success")
        XCTAssertFalse(authManager.isLastAuthTokenValid, "isLastAuthTokenValid must stay false after a disable-device success")
        XCTAssertEqual(authManager.failedAuthCount, 3, "failedAuthCount must not be reset by a disable-device success")
    }
    
    func testUpdateUser() throws {
        let dataFields = ["var1": "val1", "var2": "val2"]
        let bodyDict: [String: Any] = [
            "dataFields": dataFields,
            "email": "user@example.com",
            "mergeNestedObjects": true
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.updateUser(dataFields,
                                      mergeNestedObjects: true,
                                      onSuccess: expectations.onSuccess,
                                      onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateUser,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testUpdateEmail() throws {
        let bodyDict: [String: Any] = [
            "currentEmail": "user@example.com",
            "newEmail": "new_user@example.com"
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.updateEmail("new_user@example.com",
                                       onSuccess: expectations.onSuccess,
                                       onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateEmail,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
            ] as [String : Any]],
            "total": total,
            "dataFields": dataFields,
            "user": [
                "email": "user@example.com",
            ],
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.trackPurchase(total,
                                         items: items,
                                         dataFields: dataFields,
                                         campaignId: nil,
                                         templateId: nil,
                                         onSuccess: expectations.onSuccess,
                                         onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPurchase,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }

    func testTrackPurchase2() throws {
        let total = NSNumber(value: 15.32)
        let items = [CommerceItem(id: "id1", name: "myCommerceItem", price: 5.1, quantity: 2)]
        let dataFields = ["var1": "val1", "var2": "val2"]
        let campaignId: NSNumber = 33
        let templateId: NSNumber = 55
        
        let bodyDict: [String: Any] = [
            "items": [[
                "id": items[0].id,
                "name": items[0].name,
                "price": items[0].price,
                "quantity": items[0].quantity,
            ] as [String : Any]],
            "total": total,
            "dataFields": dataFields,
            "campaignId": campaignId,
            "templateId": templateId,
            "user": [
                "email": "user@example.com",
            ],
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.trackPurchase(total,
                                         items: items,
                                         dataFields: dataFields,
                                         campaignId: campaignId,
                                         templateId: templateId,
                                         onSuccess: expectations.onSuccess,
                                         onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPurchase,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.trackPushOpen(NSNumber(value: campaignId),
                                         templateId: NSNumber(value: templateId),
                                         messageId: messageId,
                                         appAlreadyRunning: appAlreadyRunning,
                                         dataFields: dataFields,
                                         onSuccess: expectations.onSuccess,
                                         onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackPushOpen,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.track(event: eventName,
                                 dataFields: dataFields,
                                 onSuccess: expectations.onSuccess,
                                 onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackEvent,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.updateSubscriptions(info: info,
                                               onSuccess: expectations.onSuccess,
                                               onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.updateSubscriptions,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppOpen() throws {
        let messageId = "message_id"
        let message = InAppTestHelper.emptyInAppMessage(messageId: messageId)
        let inboxSessionId = "ibx1"
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "inboxSessionId": inboxSessionId,
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
            "messageContext": [
                "location": "in-app",
                "saveToInbox": false,
                "silentInbox": false,
            ] as [String : Any],
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.trackInAppOpen(message,
                                          location: .inApp,
                                          inboxSessionId: inboxSessionId,
                                          onSuccess: expectations.onSuccess,
                                          onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppOpen,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
            "clickedUrl": clickedUrl,
            "messageContext": [
                "location": "inbox",
                "saveToInbox": false,
                "silentInbox": false,
            ] as [String : Any],
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.trackInAppClick(message,
                                           location: .inbox,
                                           inboxSessionId: inboxSessionId,
                                           clickedUrl: clickedUrl,
                                           onSuccess: expectations.onSuccess,
                                           onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppClick,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
            "clickedUrl": clickedUrl,
            "messageContext": [
                "location": "inbox",
                "saveToInbox": false,
                "silentInbox": false,
            ] as [String : Any],
            "closeAction": "link",
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.trackInAppClose(message, location: .inbox,
                                           inboxSessionId: inboxSessionId,
                                           source: closeSource,
                                           clickedUrl: clickedUrl,
                                           onSuccess: expectations.onSuccess,
                                           onFailure: expectations.onFailure)
            
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppClose,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.track(inboxSession: inboxSession,
                                 onSuccess: expectations.onSuccess,
                                 onFailure: expectations.onFailure)
            
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInboxSession,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
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
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.track(inAppDelivery: message,
                                 onSuccess: expectations.onSuccess,
                                 onFailure: expectations.onFailure)
            
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppDelivery,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppConsume() throws {
        let messageId = "message_id"
        
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.inAppConsume(messageId,
                                        onSuccess: expectations.onSuccess,
                                        onFailure: expectations.onFailure)
            
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.inAppConsume,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppConsume2() throws {
        let messageId = "message_id"
        let inboxSessionId = UUID().uuidString
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
            ] as [String : Any],
            "inboxSessionId": inboxSessionId,
            "deleteAction": "delete-button",
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) in
            requestHandler.inAppConsume(message: message,
                                        location: location,
                                        source: source,
                                        inboxSessionId: inboxSessionId,
                                        onSuccess: expectations.onSuccess,
                                        onFailure: expectations.onFailure)
            
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.inAppConsume,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppOpen2() throws {
        let messageId = "message_id"
        let inboxSessionId = UUID().uuidString
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
            "messageContext": [
                "location": "in-app",
                "saveToInbox": false,
                "silentInbox": false,
            ] as [String : Any],
            "inboxSessionId": inboxSessionId,
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError> in
            let message = IterableInAppMessage(messageId: messageId,
                                               campaignId: nil,
                                               content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""))
            
            return requestHandler.trackInAppOpen(message,
                                          location: .inApp,
                                          inboxSessionId: inboxSessionId,
                                          onSuccess: expectations.onSuccess,
                                          onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppOpen,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppClick2() throws {
        let messageId = "message_id"
        let clickedUrl = "https://somewhere.com"
        let bodyDict: [String: Any] = [
            "email": "user@example.com",
            "messageId": messageId,
            "deviceInfo": Self.deviceMetadata.asDictionary()!,
            "clickedUrl": clickedUrl,
            "messageContext": [
                "location": "in-app",
                "saveToInbox": false,
                "silentInbox": false,
            ] as [String : Any],
        ]
        
        let expectations = createExpectations(description: #function)
        
        let requestGenerator = { (requestHandler: RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError> in
            let message = IterableInAppMessage(messageId: messageId,
                                               campaignId: nil,
                                               content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""))
            
            return requestHandler.trackInAppClick(message,
                                           location: .inApp,
                                           inboxSessionId: nil,
                                           clickedUrl: clickedUrl,
                                           onSuccess: expectations.onSuccess,
                                           onFailure: expectations.onFailure)
        }
        
        try handleRequestWithSuccessAndFailure(requestGenerator: requestGenerator,
                                                path: Const.Path.trackInAppClick,
                                                bodyDict: bodyDict)
        
        wait(for: [expectations.successExpectation, expectations.failureExpectation], timeout: testExpectationTimeout)
    }
    
    func testDeleteAllTasksOnLogout() throws {
        let localStorage = MockLocalStorage()
        localStorage.offlineMode = true
        let internalApi = InternalIterableAPI.initializeForTesting(networkSession: MockNetworkSession(),
                                                                   localStorage: localStorage)
        internalApi.email = "user@example.com"
        
        let taskId = IterableUtil.generateUUID()
        try persistenceContextProvider.mainQueueContext().create(task: IterableTask(id: taskId,
                                                                                    type: .apiCall,
                                                                                    scheduledAt: Date(),
                                                                                    data: nil,
                                                                                    requestedAt: Date()))
        try persistenceContextProvider.mainQueueContext().save()

        internalApi.logoutUser()

        let result = TestUtils.tryUntil(attempts: 10) {
            let count = try! persistenceContextProvider.mainQueueContext().findAllTasks().count
            return count == 0
        }
        
        XCTAssertTrue(result)
    }
    
    func testGetRemoteConfiguration() throws {
        let expectation1 = expectation(description: #function)
        let expectedRemoteConfiguration = RemoteConfiguration(offlineMode: true)
        let data = try JSONEncoder().encode(expectedRemoteConfiguration)
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession(statusCode: 200, data: data)

        networkSession.requestCallback = { request in
            TestUtils.validate(request: request,
                               requestType: .get,
                               apiEndPoint: Endpoint.api,
                               path: Const.Path.getRemoteConfiguration,
                               queryParams: [("platform", "iOS"),
                                             ("systemVersion", UIDevice.current.systemVersion),
                                             ("SDKVersion", IterableAPI.sdkVersion),
                                             ("packageName", Bundle.main.appPackageName!)])
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: notificationCenter,
                                                  selectOffline: false)
        requestHandler.getRemoteConfiguration().onSuccess { remoteConfiguration in
            XCTAssertEqual(remoteConfiguration, expectedRemoteConfiguration)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testCreatedAtSentAtForOffline() throws {
        let expectation1 = expectation(description: #function)
        let date = Date().addingTimeInterval(-5000)
        dateProvider.currentDate = date

        let campaignId = 1
        let templateId = 2
        let messageId = "message_id"
        let appAlreadyRunning = true
        let dataFields: [String: Any] = [
            "var1": "val1",
            "var2": "val2",
        ]

        let networkSession = MockNetworkSession(statusCode: 200)
        networkSession.requestCallback = { request in
            if request.url?.absoluteString.contains(Const.Path.trackPushOpen) == true {
                let sentAt = request.value(forHTTPHeaderField: "Sent-At")
                let createdAt = TestUtils.getRequestBody(request: request)?["createdAt"] as? Int
                XCTAssertEqual(createdAt, Int(date.timeIntervalSince1970))
                XCTAssertEqual(sentAt, "\(Int(date.timeIntervalSince1970))")
                expectation1.fulfill()
            }
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: MockNotificationCenter(),
                                                  selectOffline: true)
        requestHandler.trackPushOpen(NSNumber(value: campaignId),
                                     templateId: NSNumber(value: templateId),
                                     messageId: messageId,
                                     appAlreadyRunning: appAlreadyRunning,
                                     dataFields: dataFields,
                                     onSuccess: nil,
                                     onFailure: nil)
        waitForTaskRunner(requestHandler: requestHandler, expectation: expectation1)
    }

    func testCreatedAtSentAtForOnline() throws {
        let expectation1 = expectation(description: #function)
        let date = Date().addingTimeInterval(-5000)
        dateProvider.currentDate = date

        let campaignId = 1
        let templateId = 2
        let messageId = "message_id"
        let appAlreadyRunning = true
        let dataFields: [String: Any] = [
            "var1": "val1",
            "var2": "val2",
        ]

        let networkSession = MockNetworkSession(statusCode: 200)
        networkSession.requestCallback = { request in
            let sentAt = request.value(forHTTPHeaderField: "Sent-At")
            XCTAssertEqual(sentAt, "\(Int(date.timeIntervalSince1970))")
            let createdAt = TestUtils.getRequestBody(request: request)?["createdAt"] as? Int
            XCTAssertEqual(createdAt, Int(date.timeIntervalSince1970))
            expectation1.fulfill()
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: MockNotificationCenter(),
                                                  selectOffline: false)
        requestHandler.trackPushOpen(NSNumber(value: campaignId),
                                     templateId: NSNumber(value: templateId),
                                     messageId: messageId,
                                     appAlreadyRunning: appAlreadyRunning,
                                     dataFields: dataFields,
                                     onSuccess: nil,
                                     onFailure: nil)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testNoRemoteConfigurationUsesOnline() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = nil
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        let expectation2 = expectation(description: #function)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains("track") {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                XCTAssertEqual(processor, Const.ProcessorTypeName.online)
                expectation2.fulfill()
            }
        }
        internalAPI.track("myEvent")
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    func testDefaultRemoteConfigurationUsesOnlineMode() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        let remoteConfigurationData = """
        {
            "offlineMode": false,
            "offlineModeBeta": false,
            "autoRetry": false
        }
        """.data(using: .utf8)!
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = remoteConfigurationData
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        let expectation2 = expectation(description: #function)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains("track") {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                XCTAssertEqual(processor, Const.ProcessorTypeName.online)
                expectation2.fulfill()
            }
        }
        internalAPI.track("myEvent")
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    func testFeatureFlagTurnOnOfflineMode() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        let remoteConfigurationData = """
        {
            "offlineMode": true,
            "offlineModeBeta": true,
            "autoRetry": true
        }
        """.data(using: .utf8)!
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = remoteConfigurationData
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true // Set offline mode in localStorage too
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        // Wait for offline mode to be properly set
        let offlineModeExpectation = expectation(description: "Wait for offline mode")
        var retryCount = 0
        let maxRetries = 5
        
        func checkOfflineMode() {
            if retryCount >= maxRetries {
                XCTFail("Failed to set offline mode after \(maxRetries) attempts")
                offlineModeExpectation.fulfill()
                return
            }
            
            // Make a test track call to check processor type
            networkSession.requestCallback = { request in
                if request.url!.absoluteString.contains("track") {
                    let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                    if processor == Const.ProcessorTypeName.offline {
                        offlineModeExpectation.fulfill()
                    } else {
                        retryCount += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            checkOfflineMode()
                        }
                    }
                }
            }
            internalAPI.track("testEvent\(retryCount)")
        }
        
        checkOfflineMode()
        wait(for: [offlineModeExpectation], timeout: testExpectationTimeout)

        // Now test the actual event tracking
        let expectation2 = expectation(description: #function)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains("track") {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                XCTAssertEqual(processor, Const.ProcessorTypeName.offline)
                expectation2.fulfill()
            }
        }
        internalAPI.track("myEvent")
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    func testLoadOfflineModeEnabledFromLocalStorage() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = nil
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = true
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        let expectation2 = expectation(description: #function)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains("track") {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                XCTAssertEqual(processor, Const.ProcessorTypeName.offline)
                expectation2.fulfill()
            }
        }
        internalAPI.track("myEvent")
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    func testLoadOfflineModeDisabledFromLocalStorage() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = nil
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        localStorage.offlineMode = false
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        let expectation2 = expectation(description: #function)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains("track") {
                let processor = request.allHTTPHeaderFields?[JsonKey.Header.requestProcessor]!
                XCTAssertEqual(processor, Const.ProcessorTypeName.online)
                expectation2.fulfill()
            }
        }
        internalAPI.track("myEvent")
        wait(for: [expectation2], timeout: testExpectationTimeout)
    }

    func testAutoRetryFlagParsedFromRemoteConfiguration() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        let remoteConfigurationData = """
        {
            "offlineMode": false,
            "autoRetry": true
        }
        """.data(using: .utf8)!
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = remoteConfigurationData
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        let autoRetryExpectation = expectation(description: "autoRetry is set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(localStorage.autoRetry)
            autoRetryExpectation.fulfill()
        }
        wait(for: [autoRetryExpectation], timeout: testExpectationTimeout)
    }

    func testAutoRetryDefaultsToFalseWhenMissingFromResponse() throws {
        let expectation1 = expectation(description: "getRemoteConfiguration is called")
        let remoteConfigurationData = """
        {
            "offlineMode": false
        }
        """.data(using: .utf8)!
        var mapper = [String: Data?]()
        mapper["getRemoteConfiguration"] = remoteConfigurationData
        let networkSession = MockNetworkSession(statusCode: 200, urlPatternDataMapping: mapper)
        networkSession.requestCallback = { request in
            if request.url!.absoluteString.contains(Const.Path.getRemoteConfiguration) {
                expectation1.fulfill()
            }
        }
        let localStorage = MockLocalStorage()
        localStorage.email = "user@example.com"
        let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: networkSession, localStorage: localStorage)
        wait(for: [expectation1], timeout: testExpectationTimeout)

        let autoRetryExpectation = expectation(description: "autoRetry defaults to false")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(localStorage.autoRetry)
            autoRetryExpectation.fulfill()
        }
        wait(for: [autoRetryExpectation], timeout: testExpectationTimeout)
    }

    private func handleRequestWithSuccessAndFailure(requestGenerator: (RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError>,
                                                     path: String,
                                                     bodyDict: [AnyHashable: Any]) throws {
        
        handleOnlineRequestWithSuccess(requestGenerator: requestGenerator,
                                        path: path,
                                        bodyDict: bodyDict)
        handleOnlineRequestWithFailure(requestGenerator: requestGenerator,
                                        path: path,
                                        bodyDict: bodyDict)
        handleOfflineRequestWithSuccess(requestGenerator: requestGenerator,
                                         path: path,
                                         bodyDict: bodyDict)
        handleOfflineRequestWithFailure(requestGenerator: requestGenerator,
                                         path: path,
                                         bodyDict: bodyDict)
    }
    
    private func handleOnlineRequestWithSuccess(requestGenerator: (RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError>,
                                                 path: String,
                                                 bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: notificationCenter,
                                                  selectOffline: false)
        let request = { requestGenerator(requestHandler) }
        let expectation1 = expectation(description: #function)
        handleRequestWithSuccess(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func handleOnlineRequestWithFailure(requestGenerator: (RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError>,
                                                 path: String,
                                                 bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession(statusCode: 400)
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: notificationCenter,
                                                  selectOffline: false)
        let request = { requestGenerator(requestHandler) }
        let expectation1 = expectation(description: #function)
        handleRequestWithFailure(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func handleOfflineRequestWithSuccess(requestGenerator: (RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError>,
                                                  path: String,
                                                  bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession()
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: request.bodyDict))
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: notificationCenter,
                                                  selectOffline: true)
        let request = { requestGenerator(requestHandler) }
        let expectation1 = expectation(description: #function)
        handleRequestWithSuccess(request: request,
                                 networkSession: networkSession,
                                 path: path,
                                 bodyDict: bodyDict,
                                 expectation: expectation1)
        waitForTaskRunner(requestHandler: requestHandler,
                          expectation: expectation1)
    }
    
    private func handleOfflineRequestWithFailure(requestGenerator: (RequestHandlerProtocol) -> Pending<SendRequestValue, SendRequestError>,
                                                  path: String,
                                                  bodyDict: [AnyHashable: Any]) {
        let notificationCenter = MockNotificationCenter()
        let networkSession = MockNetworkSession(statusCode: 400)
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            var requestBody = request.bodyDict
            requestBody.removeValue(forKey: "createdAt")
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: requestBody))
        }
        let requestHandler = createRequestHandler(networkSession: networkSession,
                                                  notificationCenter: notificationCenter,
                                                  selectOffline: true)
        let request = { requestGenerator(requestHandler) }
        let expectation1 = expectation(description: #function)
        handleRequestWithFailure(request: request,
                                  networkSession: networkSession,
                                  path: path,
                                  bodyDict: bodyDict,
                                  expectation: expectation1)
        waitForTaskRunner(requestHandler: requestHandler,
                          expectation: expectation1)
    }
    
    private func createRequestHandler(networkSession: NetworkSessionProtocol,
                                      notificationCenter: NotificationCenterProtocol,
                                      selectOffline: Bool,
                                      authProvider: AuthProvider? = nil) -> RequestHandlerProtocol {
        let resolvedAuthProvider: AuthProvider = authProvider ?? self
        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let taskScheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                                  notificationCenter: notificationCenter,
                                                  healthMonitor: healthMonitor,
                                                  dateProvider: dateProvider)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            dateProvider: dateProvider)

        let onlineProcessor = OnlineRequestProcessor(apiKey: "zee-api-key",
                                                     authProvider: resolvedAuthProvider,
                                                     authManager: nil,
                                                     endpoint: Endpoint.api,
                                                     networkSession: networkSession,
                                                     deviceMetadata: Self.deviceMetadata,
                                                     dateProvider: self.dateProvider)
        let offlineProcessor = OfflineRequestProcessor(apiKey: "zee-api-key",
                                                       authProvider: resolvedAuthProvider,
                                                       authManager: nil,
                                                       endpoint: Endpoint.api,
                                                       deviceMetadata: Self.deviceMetadata,
                                                       taskScheduler: taskScheduler,
                                                       taskRunner: taskRunner,
                                                       notificationCenter: notificationCenter)

        return RequestHandler(onlineProcessor: onlineProcessor,
                              offlineProcessor: offlineProcessor,
                              healthMonitor: healthMonitor,
                              authProvider: resolvedAuthProvider,
                              offlineMode: selectOffline)
    }
    
    private func handleRequestWithSuccess(request: () -> Pending<SendRequestValue, SendRequestError>,
                                           networkSession: MockNetworkSession,
                                           path: String,
                                           bodyDict: [AnyHashable: Any],
                                           expectation: XCTestExpectation) {
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            var requestBody = request.bodyDict
            requestBody.removeValue(forKey: "createdAt")
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: requestBody))
        }
        
        request().onSuccess { json in
            expectation.fulfill()
        }.onError { error in
            XCTFail()
        }
    }
    
    private func handleRequestWithFailure(request: () -> Pending<SendRequestValue, SendRequestError>,
                                           networkSession: MockNetworkSession,
                                           path: String,
                                           bodyDict: [AnyHashable: Any],
                                           expectation: XCTestExpectation) {
        networkSession.requestCallback = { request in
            TestUtils.validate(request: request, apiEndPoint: Endpoint.api, path: path)
            var requestBody = request.bodyDict
            requestBody.removeValue(forKey: "createdAt")
            XCTAssertTrue(TestUtils.areEqual(dict1: bodyDict, dict2: requestBody))
        }
        request().onSuccess { json in
            XCTFail()
        }.onError { error in
            expectation.fulfill()
        }
    }
    
    private func waitForTaskRunner(requestHandler: RequestHandlerProtocol,
                                   expectation: XCTestExpectation) {
        requestHandler.start()
        wait(for: [expectation], timeout: testExpectationTimeout)
        requestHandler.stop()
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
    
    private static let deviceMetadata = DeviceMetadata(deviceId: IterableUtil.generateUUID(),
                                                       platform: JsonValue.iOS,
                                                       appPackageName: Bundle.main.appPackageName ?? "")
    
    private let dateProvider = MockDateProvider()
    
    private lazy var persistenceContextProvider: IterablePersistenceContextProvider = {
        let provider = CoreDataPersistenceContextProvider(dateProvider: dateProvider)!
        return provider
    }()

    func testOfflineProcessor_callsOnFailure_whenJwt401AndAuthRetryExhausted() throws {
        let onFailureCalled = expectation(description: "onFailure invoked via onRetryExhausted")

        let jwtErrorData = ["code": JsonValue.Code.invalidJwtPayload].toJsonData()
        let networkSession = MockNetworkSession(statusCode: 401, data: jwtErrorData)
        let notificationCenter = MockNotificationCenter()
        let authManager = MockAuthManager()
        authManager.shouldRetry = false  // forces onRetryExhausted path in scheduleAuthTokenRefreshTimer

        let healthMonitor = HealthMonitor(dataProvider: HealthMonitorDataProvider(maxTasks: 1000,
                                                                                  persistenceContextProvider: persistenceContextProvider),
                                          dateProvider: dateProvider,
                                          networkSession: networkSession)
        let taskScheduler = IterableTaskScheduler(persistenceContextProvider: persistenceContextProvider,
                                                  notificationCenter: notificationCenter,
                                                  healthMonitor: healthMonitor,
                                                  dateProvider: dateProvider)
        let taskRunner = IterableTaskRunner(networkSession: networkSession,
                                            persistenceContextProvider: persistenceContextProvider,
                                            healthMonitor: healthMonitor,
                                            notificationCenter: notificationCenter,
                                            timeInterval: 0.5,
                                            dateProvider: dateProvider)

        let offlineProcessor = OfflineRequestProcessor(apiKey: "zee-api-key",
                                                       authProvider: self,
                                                       authManager: authManager,
                                                       endpoint: Endpoint.api,
                                                       deviceMetadata: Self.deviceMetadata,
                                                       taskScheduler: taskScheduler,
                                                       taskRunner: taskRunner,
                                                       notificationCenter: notificationCenter)

        offlineProcessor.start()
        offlineProcessor.updateCart(items: [CommerceItem(id: "id-1", name: "name-1", price: 1, quantity: 1)],
                                    onSuccess: nil,
                                    onFailure: { _, _ in onFailureCalled.fulfill() })

        wait(for: [onFailureCalled], timeout: testExpectationTimeout)
        XCTAssertTrue(authManager.handleAuthFailureCalled)
        offlineProcessor.stop()
    }
}

extension RequestHandlerTests: AuthProvider {
    var auth: Auth {
        Auth(userId: nil, email: "user@example.com", authToken: nil, userIdUnknownUser: nil)
    }
}

fileprivate extension MockNetworkSession {
    convenience init(statusCode: Int, urlPatternDataMapping: [String: Data?]?) {
        let mapping = urlPatternDataMapping?.mapValues { data in
            MockNetworkSession.MockResponse(statusCode: statusCode,
                                            data: data,
                                            delay: 0.0,
                                            error: nil)
        }
        self.init(mapping: mapping)
    }
}

fileprivate final class MutableAuthProvider: AuthProvider {
    var currentAuth: Auth
    init(initial: Auth) { currentAuth = initial }
    var auth: Auth { currentAuth }
}
