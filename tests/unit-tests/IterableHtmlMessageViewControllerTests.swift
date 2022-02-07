//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

import WebKit

@testable import IterableSDK

class IterableHtmlMessageViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWebViewTopPositioning() {
        checkPositioning(parentPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .top,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 100.0)))
    }
    
    func testWebViewBottomPositioning() {
        checkPositioning(parentPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .bottom,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 300.0)))
    }
    
    func testWebViewCenterPositioning() {
        checkPositioning(parentPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .center,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 200.0)))
    }
    
    func testWebViewFullPositioning() {
        checkPositioning(parentPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .full,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)))
    }
    
    func testWebViewTopPositioningWithSafeAreaInsets() {
        let inAppHeight: CGFloat = 200
        let safeAreaTop: CGFloat = 25
        let calculatedHeight = inAppHeight + safeAreaTop
        let calculatedCenterY = calculatedHeight / 2
        checkPositioning(parentPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 400 / 2)),
                         safeAreaInsets: UIEdgeInsets(top: safeAreaTop, left: 0, bottom: 30, right: 0),
                         inAppHeight: inAppHeight,
                         messageLocation: .top,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: calculatedHeight, center: CGPoint(x: 617.0, y: calculatedCenterY)))
    }
    
    func testWebViewBottomPositioningWithSafeAreaInsets() {
        checkPositioning(parentPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: UIEdgeInsets(top: 25, left: 0, bottom: 30, right: 0),
                         inAppHeight: 200,
                         messageLocation: .bottom,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 270.0)))
    }
    
    func testTopAnimation() {
        let safeAreaInsets = UIEdgeInsets(top: 55, left: 0, bottom: 30, right: 0)
        let width: CGFloat = 200
        let height: CGFloat = 100
        let center = CGPoint(x: width / 2, y: 200)
        let position = ViewPosition(width: width, height: height, center: center)
        let startPos = InAppCalculations.calculateAnimationStartPosition(for: position,
                                                                         location: .top,
                                                                         safeAreaInsets: safeAreaInsets)
        let expectedPosition = ViewPosition(width: width,
                                            height: height,
                                            center: CGPoint(x: center.x,
                                                            y: center.y - height - safeAreaInsets.top))
        XCTAssertEqual(startPos, expectedPosition)
        
        XCTAssertEqual(InAppCalculations.calculateAnimationStartAlpha(location: .top), 1.0)
    }

    func testCenterAnimation() {
        let safeAreaInsets = UIEdgeInsets(top: 55, left: 0, bottom: 30, right: 0)
        let width: CGFloat = 200
        let height: CGFloat = 100
        let center = CGPoint(x: width / 2, y: 200)
        let position = ViewPosition(width: width, height: height, center: center)
        let startPos = InAppCalculations.calculateAnimationStartPosition(for: position,
                                                                         location: .center,
                                                                         safeAreaInsets: safeAreaInsets)
        XCTAssertEqual(startPos, position)
        
        XCTAssertEqual(InAppCalculations.calculateAnimationStartAlpha(location: .center), 0.0)
    }

    func testFullAnimation() {
        let safeAreaInsets = UIEdgeInsets(top: 55, left: 0, bottom: 30, right: 0)
        let width: CGFloat = 200
        let height: CGFloat = 100
        let center = CGPoint(x: width / 2, y: 200)
        let position = ViewPosition(width: width, height: height, center: center)
        let startPos = InAppCalculations.calculateAnimationStartPosition(for: position,
                                                                         location: .full,
                                                                         safeAreaInsets: safeAreaInsets)
        XCTAssertEqual(startPos, position)
        
        XCTAssertEqual(InAppCalculations.calculateAnimationStartAlpha(location: .full), 0.0)
    }

    func testBottomAnimation() {
        let safeAreaInsets = UIEdgeInsets(top: 55, left: 0, bottom: 30, right: 0)
        let width: CGFloat = 200
        let height: CGFloat = 100
        let center = CGPoint(x: width / 2, y: 200)
        let position = ViewPosition(width: width, height: height, center: center)
        let startPos = InAppCalculations.calculateAnimationStartPosition(for: position,
                                                                         location: .bottom,
                                                                         safeAreaInsets: safeAreaInsets)
        let expectedPosition = ViewPosition(width: width,
                                            height: height,
                                            center: CGPoint(x: center.x,
                                                            y: center.y + height + safeAreaInsets.bottom))
        XCTAssertEqual(startPos, expectedPosition)
        
        XCTAssertEqual(InAppCalculations.calculateAnimationStartAlpha(location: .bottom), 1.0)
    }

    private func checkPositioning(parentPosition: ViewPosition,
                                  safeAreaInsets: UIEdgeInsets,
                                  inAppHeight: CGFloat,
                                  messageLocation: IterableMessageLocation,
                                  expectedWebViewPosition: ViewPosition) {
        let expectation1 = expectation(description: "checkPositioning")
        let webView = MockWebView(height: inAppHeight)
        
        let pending = IterableHtmlMessageViewController.calculateWebViewPosition(webView: webView,
                                                                                safeAreaInsets: safeAreaInsets,
                                                                                parentPosition: parentPosition,
                                                                                paddingLeft: 0,
                                                                                paddingRight: 0,
                                                                                location: messageLocation)
        pending.onSuccess { position in
            XCTAssertEqual(position, expectedWebViewPosition)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    func testTrackInAppOpen() throws {
        let expectation1 = expectation(description: #function)
        let messageId = UUID().uuidString
        let campaignId = TestHelper.generateIntGuid() as NSNumber
        let eventTracker = MockMessageViewControllerEventTracker()
        eventTracker.trackInAppOpenCallback = { (message, _, _) in
            XCTAssertEqual(message.messageId, messageId)
            XCTAssertEqual(message.campaignId, campaignId)
            expectation1.fulfill()
        }
        let parameters = IterableHtmlMessageViewController.Parameters.createForTesting(messageId: messageId, campaignId: campaignId)
        let viewController = IterableHtmlMessageViewController.create(parameters: parameters,
                                                                      eventTracker: eventTracker,
                                                                      onClickCallback: nil)
        viewController.viewDidLoad()
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackInAppClose() throws {
        let expectation1 = expectation(description: #function)
        let messageId = UUID().uuidString
        let campaignId = TestHelper.generateIntGuid() as NSNumber
        let eventTracker = MockMessageViewControllerEventTracker()
        eventTracker.trackInAppCloseCallback = { (message, _, _, _, _) in
            XCTAssertEqual(message.messageId, messageId)
            XCTAssertEqual(message.campaignId, campaignId)
            expectation1.fulfill()
        }
        let parameters = IterableHtmlMessageViewController.Parameters.createForTesting(messageId: messageId, campaignId: campaignId)
        let viewController = IterableHtmlMessageViewController.create(parameters: parameters,
                                                                      eventTracker: eventTracker,
                                                                      onClickCallback: nil)
        viewController.viewWillDisappear(true)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }

    func testTrackInAppClick() throws {
        let expectation1 = expectation(description: #function)
        let testUrl = URL(string: "https://app.iterable.com")!
        let messageId = UUID().uuidString
        let campaignId = TestHelper.generateIntGuid() as NSNumber
        let eventTracker = MockMessageViewControllerEventTracker()
        eventTracker.trackInAppClickCallback = { (message, _, _, urlString) in
            XCTAssertEqual(message.messageId, messageId)
            XCTAssertEqual(message.campaignId, campaignId)
            XCTAssertEqual(urlString, testUrl.absoluteString)
            expectation1.fulfill()
        }
        let parameters = IterableHtmlMessageViewController.Parameters.createForTesting(messageId: messageId, campaignId: campaignId)
        let viewController = IterableHtmlMessageViewController.create(parameters: parameters,
                                                                      eventTracker: eventTracker,
                                                                      onClickCallback: nil)

        let testAction = FakeNavigationAction(url: testUrl)
        let webView = WKWebView()
        viewController.webView(webView, decidePolicyFor: testAction, decisionHandler: testAction.decisionHandler)
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}

final class FakeNavigationAction: WKNavigationAction {
    let urlRequest: URLRequest
    
    var receivedPolicy: WKNavigationActionPolicy?
    
    override var request: URLRequest { urlRequest }

    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
        super.init()
    }
    
    convenience init(url: URL) {
        self.init(urlRequest: URLRequest(url: url))
    }
    
    func decisionHandler(_ policy: WKNavigationActionPolicy) { self.receivedPolicy = policy }
}
