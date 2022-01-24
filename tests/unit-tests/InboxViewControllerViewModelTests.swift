//
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxViewControllerViewModelTests: XCTestCase {
     override func setUp() {
          super.setUp()
     }
     
     override func tearDown() {
          // Put teardown code here. This method is called after the invocation of each test method in the class.
          super.tearDown()
     }
     
     func testDescendingSorting() {
          let expectation1 = expectation(description: #function)
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          
          let input = MockInboxState()
          input.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          
          let model = InboxViewControllerViewModel(input: input, notificationCenter: notificationCenter)
          model.comparator = IterableInboxViewController.DefaultComparator.descending
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message1")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }
     
     func testAscendingSorting() {
          let expectation1 = expectation(description: #function)
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          
          let input = MockInboxState()
          input.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          
          let model = InboxViewControllerViewModel(input: input, notificationCenter: notificationCenter)
          model.comparator = IterableInboxViewController.DefaultComparator.ascending
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message2")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }
     
     func testNoSortingIsDescending() {
          let expectation1 = expectation(description: #function)
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          
          let input = MockInboxState()
          input.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          
          let model = InboxViewControllerViewModel(input: input, notificationCenter: notificationCenter)
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message1")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }
     
     func testWithNoFiltering() {
          let expectation1 = expectation(description: #function)
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          
          let input = MockInboxState()
          input.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          
          let model = InboxViewControllerViewModel(input: input, notificationCenter: notificationCenter)
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message1")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }
     
     func testCustomFiltering() {
          let expectation1 = expectation(description: #function)
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          
          let input = MockInboxState()
          input.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          
          let model = InboxViewControllerViewModel(input: input, notificationCenter: notificationCenter)
          model.filter = { $0.messageId == "message1" }
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.numRows(in: 0), 1)
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }

     func testSampleFilter() {
          let expectation1 = expectation(description: #function)
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          
          let input = MockInboxState()
          input.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: ["messageType": "transactional"]),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: ["messageType": "promotional"]),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          
          let model = InboxViewControllerViewModel(input: input, notificationCenter: notificationCenter)
          model.filter = SampleInboxViewDelegateImplementations.Filter.usingCustomPayloadMessageType(in: "promotional")
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.numRows(in: 0), 1)
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }

     func testImageLoadingForExistingImage() {
          let expectation1 = expectation(description: #function)
          
          let mockNetworkSession = MockNetworkSession(statusCode: 200, data: Data(repeating: 0, count: 100))
          let fetcher = MockInAppFetcher()
          let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: mockNetworkSession, inAppFetcher: fetcher)
          let model = InboxViewControllerViewModel(input: InboxState(internalAPIProvider: internalAPI))
          
          let mockView = MockViewModelView(model: model)
          mockView.onImageLoadedCallback = { indexPath in
               XCTAssertNotNil(model.message(atIndexPath: indexPath).imageData)
               expectation1.fulfill()
          }
          model.view = mockView
          
          let imageLocation = Bundle(for: type(of: self)).url(forResource: "image", withExtension: "jpg")!.absoluteString
          
          let messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: IterableInboxMetadata(title: "inbox title", subtitle: "inbox subtitle", icon: imageLocation),
                                    customPayload: ["messageType": "transactional"]),
          ]
          fetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages)
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               model.beganUpdates()
               XCTAssertEqual(model.numRows(in: 0), 1)
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }
     
     func testImageLoadingForNonExistingImage() {
          let expectation1 = expectation(description: #function)
          expectation1.isInverted = true
          
          let mockNetworkSession = MockNetworkSession(statusCode: 404, data: nil)
          let fetcher = MockInAppFetcher()
          let internalAPI = InternalIterableAPI.initializeForTesting(networkSession: mockNetworkSession, inAppFetcher: fetcher)
          let model = InboxViewControllerViewModel(input: InboxState(internalAPIProvider: internalAPI))
          
          let mockView = MockViewModelView(model: model)
          mockView.onImageLoadedCallback = { indexPath in
               XCTAssertNotNil(model.message(atIndexPath: indexPath).imageData)
               expectation1.fulfill()
          }
          model.view = mockView
          
          let imageLocation = "file:///something.png"
          
          let messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: IterableInboxMetadata(title: "inbox title", subtitle: "inbox subtitle", icon: imageLocation),
                                    customPayload: ["messageType": "transactional"]),
          ]
          fetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages)
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               model.beganUpdates()
               XCTAssertEqual(model.numRows(in: 0), 1)
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
          }
          
          wait(for: [expectation1], timeout: 5.0)
     }

     func testSampleSectionMapper() {
          let expectation1 = expectation(description: #function)
          
          let date1 = Date()
          let date2 = date1.addingTimeInterval(5.0)
          let inboxState = MockInboxState()
          inboxState.messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date1,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: ["messageSection": 1]),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: date2,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ].map(InboxMessageViewModel.init(message:))
          
          let notificationCenter = MockNotificationCenter()
          let model = InboxViewControllerViewModel(input: inboxState, notificationCenter: notificationCenter)
          model.sectionMapper = SampleInboxViewDelegateImplementations.SectionMapper.usingCustomPayloadMessageSection
          notificationCenter.post(name: .iterableInboxChanged, object: nil, userInfo: nil)
          
          DispatchQueue.main.async {
               model.beganUpdates()
               XCTAssertEqual(model.numRows(in: 0), 1)
               XCTAssertEqual(model.numRows(in: 1), 1)
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
               XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 1)).iterableMessage.messageId, "message1")
               expectation1.fulfill()
          }
          
          wait(for: [expectation1], timeout: testExpectationTimeout)
     }

     func testRowDiff() {
          let expectation1 = expectation(description: "add one section and two rows")
          let expectation2 = expectation(description: "update first row")
          
          let firstMessageDate = Date()
          let secondMessageDate = firstMessageDate.addingTimeInterval(-5.0)
          let fetcher = MockInAppFetcher()
          let internalAPI = InternalIterableAPI.initializeForTesting(inAppFetcher: fetcher)
          let model = InboxViewControllerViewModel(input: InboxState(internalAPIProvider: internalAPI))
          let mockView = MockViewModelView(model: model)
          mockView.onViewModelChangedCallback = { diffs in
               if diffs.count == 3 {
                    expectation1.fulfill()
                    let messages = [
                         IterableInAppMessage(messageId: "message1",
                                              campaignId: 1,
                                              trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                              createdAt: firstMessageDate,
                                              content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                              saveToInbox: true,
                                              inboxMetadata: nil,
                                              customPayload: ["messageSection": 1],
                                              read: true),
                         IterableInAppMessage(messageId: "message2",
                                              campaignId: 1,
                                              trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                              createdAt: secondMessageDate,
                                              content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                              saveToInbox: true,
                                              inboxMetadata: nil,
                                              customPayload: nil),
                    ]
                    fetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages)
               } else {
                    if diffs.count == 1 {
                         if case RowDiff.update(let indexPath) = diffs[0] {
                              XCTAssertEqual(indexPath, IndexPath(row: 0, section: 0))
                              expectation2.fulfill()
                         }
                    }
               }
          }
          model.view = mockView
          
          let messages = [
               IterableInAppMessage(messageId: "message1",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: firstMessageDate,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: ["messageSection": 1]),
               IterableInAppMessage(messageId: "message2",
                                    campaignId: 1,
                                    trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                    createdAt: secondMessageDate,
                                    content: IterableHtmlInAppContent(edgeInsets: .zero, html: ""),
                                    saveToInbox: true,
                                    inboxMetadata: nil,
                                    customPayload: nil),
          ]
          fetcher.mockMessagesAvailableFromServer(internalApi: internalAPI, messages: messages)
          
          wait(for: [expectation1, expectation2], timeout: testExpectationTimeout, enforceOrder: true)
     }
     
     private class MockViewModelView: InboxViewControllerViewModelView {
          init(model: InboxViewControllerViewModel) {
               self.model = model
          }
          
          let currentlyVisibleRowIndexPaths: [IndexPath] = []
          var onImageLoadedCallback: ((IndexPath) -> Void)?
          var onViewModelChangedCallback: (([RowDiff]) -> Void)?
          
          func onViewModelChanged(diffs: [RowDiff]) {
               model.beganUpdates()
               onViewModelChangedCallback?(diffs)
          }
          
          func onImageLoaded(for indexPath: IndexPath) {
               onImageLoadedCallback?(indexPath)
          }
          
          private let model: InboxViewControllerViewModel
     }
}
