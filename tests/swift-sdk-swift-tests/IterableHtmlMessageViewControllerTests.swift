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
        
        TestUtils.clearTestUserDefaults()
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
        let viewCalculations = MockViewCalculations(viewPosition: viewPosition, safeAreaInsets: safeAreaInsets)
        let webView = MockWebView(height: inAppHeight)
        let dependencyModule = MockInjectedDependencyModule(viewCalculations: viewCalculations, webView: webView)
        
        InjectedDependencies.shared.set {
            dependencyModule as InjectedDependencyModuleProtocol
        }
        
        let viewController = IterableHtmlMessageViewController.create(parameters: IterableHtmlMessageViewController.Parameters(html: "",
                                                                                                                               padding: padding(from: messageLocation),
                                                                                                                               messageMetadata: nil,
                                                                                                                               isModal: true,
                                                                                                                               inboxSessionId: nil)).viewController
        viewController.loadView()
        viewController.viewDidLayoutSubviews()
        
        checkPosition(for: webView.view, expectedPosition: expectedWebViewPosition)
    }
    
    private func checkPosition(for view: UIView, expectedPosition: ViewPosition) {
        XCTAssertEqual(view.frame.width, expectedPosition.width)
        XCTAssertEqual(view.frame.height, expectedPosition.height)
        XCTAssertEqual(view.center.x, expectedPosition.center.x)
        XCTAssertEqual(view.center.y, expectedPosition.center.y)
    }
    
    private func padding(from messageLocation: IterableMessageLocation) -> UIEdgeInsets {
        switch messageLocation {
        case .top:
            return UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0)
        case .bottom:
            return UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
        case .center:
            return UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
        case .full:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}
