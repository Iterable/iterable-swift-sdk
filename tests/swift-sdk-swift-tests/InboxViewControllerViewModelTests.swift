//
//  Created by Tapash Majumder on 12/4/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class InboxViewControllerViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        TestUtils.clearTestUserDefaults()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDescendingSorting() {
        let expectation1 = expectation(description: "testDescendingSorting")
        
        let model = InboxViewControllerViewModel()
        model.comparator = IterableInboxViewController.DefaultComparator.descending
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message1")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testAscendingSorting() {
        let expectation1 = expectation(description: "testAscendingSorting")
        
        let model = InboxViewControllerViewModel()
        model.comparator = IterableInboxViewController.DefaultComparator.ascending
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message2")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testNoSortingIsDescending() {
        let expectation1 = expectation(description: "testNoSorting")
        
        let model = InboxViewControllerViewModel()
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message1")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testWithNoFiltering() {
        let expectation1 = expectation(description: "testWithNoFiltering")
        
        let model = InboxViewControllerViewModel()
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.numRows(in: 0), 2)
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 1, section: 0)).iterableMessage.messageId, "message1")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testCustomFiltering() {
        let expectation1 = expectation(description: "testCustomFiltering")
        
        let model = InboxViewControllerViewModel()
        model.filter = { $0.messageId == "message1" }
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.numRows(in: 0), 1)
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testSampleFilter() {
        let expectation1 = expectation(description: "testSampleFilter")
        
        let model = InboxViewControllerViewModel()
        model.filter = SampleInboxViewDelegateImplementations.Filter.usingCustomPayloadMessageType(in: "promotional")
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: ["messageType": "transactional"]),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: ["messageType": "promotional"]),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.numRows(in: 0), 1)
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testImageLoadingForExistingImage() {
        let expectation1 = expectation(description: "testImageLoadingForExistingImage")
        
        let model = InboxViewControllerViewModel()
        
        let mockView = MockViewModelView()
        mockView.onImageLoadedCallback = { indexPath in
            XCTAssertNotNil(model.message(atIndexPath: indexPath).imageData)
            expectation1.fulfill()
        }
        model.view = mockView
        
        let mockNetworkSession = MockNetworkSession(statusCode: 200, data: Data(repeating: 0, count: 100))
        let fetcher = MockInAppFetcher()
        IterableAPI.initializeForTesting(
            networkSession: mockNetworkSession,
            inAppFetcher: fetcher
        )
        
        let imageLocation = Bundle(for: type(of: self)).url(forResource: "image", withExtension: "jpg")!.absoluteString
        
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: IterableInboxMetadata(title: "inbox title", subtitle: "inbox subtitle", icon: imageLocation),
                                 customPayload: ["messageType": "transactional"]),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.numRows(in: 0), 1)
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testImageLoadingForNonExistingImage() {
        let expectation1 = expectation(description: "testImageLoadingForNonExistingImage")
        expectation1.isInverted = true
        
        let model = InboxViewControllerViewModel()
        
        let mockView = MockViewModelView()
        mockView.onImageLoadedCallback = { indexPath in
            XCTAssertNotNil(model.message(atIndexPath: indexPath).imageData)
            expectation1.fulfill()
        }
        model.view = mockView
        
        let mockNetworkSession = MockNetworkSession(statusCode: 404, data: nil)
        let fetcher = MockInAppFetcher()
        IterableAPI.initializeForTesting(
            networkSession: mockNetworkSession,
            inAppFetcher: fetcher
        )
        
        let imageLocation = "file:///something.png"
        
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: IterableInboxMetadata(title: "inbox title", subtitle: "inbox subtitle", icon: imageLocation),
                                 customPayload: ["messageType": "transactional"]),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.numRows(in: 0), 1)
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message1")
        }
        
        wait(for: [expectation1], timeout: 5.0)
    }
    
    func testSampleSectionMapper() {
        let expectation1 = expectation(description: "testSampleSectionMapper")
        
        let model = InboxViewControllerViewModel()
        model.sectionMapper = SampleInboxViewDelegateImplementations.SectionMapper.usingCustomPayloadMessageSection
        
        let fetcher = MockInAppFetcher()
        
        IterableAPI.initializeForTesting(
            inAppFetcher: fetcher
        )
        
        let date1 = Date()
        let date2 = date1.addingTimeInterval(5.0)
        let messages = [
            IterableInAppMessage(messageId: "message1",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date1,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: ["messageSection": 1]),
            IterableInAppMessage(messageId: "message2",
                                 campaignId: "",
                                 trigger: IterableInAppTrigger(dict: [JsonKey.InApp.type: "never"]),
                                 createdAt: date2,
                                 content: IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: ""),
                                 saveToInbox: true,
                                 inboxMetadata: nil,
                                 customPayload: nil),
        ]
        fetcher.mockMessagesAvailableFromServer(messages: messages)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            model.beganUpdates()
            XCTAssertEqual(model.numRows(in: 0), 1)
            XCTAssertEqual(model.numRows(in: 1), 1)
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 0)).iterableMessage.messageId, "message2")
            XCTAssertEqual(model.message(atIndexPath: IndexPath(row: 0, section: 1)).iterableMessage.messageId, "message1")
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private class MockViewModelView: InboxViewControllerViewModelView {
        let currentlyVisibleRowIndexPaths: [IndexPath] = []
        
        var onImageLoadedCallback: ((IndexPath) -> Void)?
        
        func onViewModelChanged(diff _: [SectionedDiffStep<Int, InboxMessageViewModel>]) {}
        
        func onImageLoaded(for indexPath: IndexPath) {
            onImageLoadedCallback?(indexPath)
        }
    }
}
