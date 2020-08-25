//
//  Created by Tapash Majumder on 3/9/20.
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
        checkPositioning(viewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .top,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 100.0)))
    }
    
    func testWebViewBottomPositioning() {
        checkPositioning(viewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .bottom,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 300.0)))
    }
    
    func testWebViewCenterPositioning() {
        checkPositioning(viewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .center,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 200.0)))
    }
    
    func testWebViewFullPositioning() {
        checkPositioning(viewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: .zero,
                         inAppHeight: 200,
                         messageLocation: .full,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)))
    }
    
    func testWebViewTopPositioningWithSafeAreaInsets() {
        checkPositioning(viewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: UIEdgeInsets(top: 25, left: 0, bottom: 30, right: 0),
                         inAppHeight: 200,
                         messageLocation: .top,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 125.0)))
    }
    
    func testWebViewBottomPositioningWithSafeAreaInsets() {
        checkPositioning(viewPosition: ViewPosition(width: 1234, height: 400, center: CGPoint(x: 617.0, y: 200.0)),
                         safeAreaInsets: UIEdgeInsets(top: 25, left: 0, bottom: 30, right: 0),
                         inAppHeight: 200,
                         messageLocation: .bottom,
                         expectedWebViewPosition: ViewPosition(width: 1234, height: 200, center: CGPoint(x: 617.0, y: 270.0)))
    }
    
    private func checkPositioning(viewPosition: ViewPosition,
                                  safeAreaInsets: UIEdgeInsets,
                                  inAppHeight: CGFloat,
                                  messageLocation: IterableMessageLocation,
                                  expectedWebViewPosition: ViewPosition) {
        let expectation1 = expectation(description: "checkPositioning")
        let webView = MockWebView(height: inAppHeight)
        
        let future = IterableHtmlMessageViewController.calculateWebViewPosition(webView: webView,
                                                                                safeAreaInsets: safeAreaInsets,
                                                                                parentPosition: viewPosition,
                                                                                paddingLeft: 0,
                                                                                paddingRight: 0,
                                                                                location: messageLocation)
        future.onSuccess { position in
            XCTAssertEqual(position, expectedWebViewPosition)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
}
