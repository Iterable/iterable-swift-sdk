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
    
    func testWebViewWidth() {
        IterableAPI.initializeForTesting()
        struct MockViewCalculations: ViewCalculationsProtocol {
            func width(for _: UIView) -> CGFloat {
                return 1234.0
            }
        }
        struct MockInjectedDependencyModule: InjectedDependencyModuleProtocol {
            let viewCalculations: ViewCalculationsProtocol = MockViewCalculations()
            
            var webView: WebViewProtocol {
                let webView = WKWebView(frame: .zero)
                webView.scrollView.bounces = false
                webView.isOpaque = false
                webView.backgroundColor = UIColor.clear
                return webView as WebViewProtocol
            }
        }
        InjectedDependencies.shared.set {
            MockInjectedDependencyModule() as InjectedDependencyModuleProtocol
        }
        
        let xpectation1 = expectation(description: "testWebViewWidth")
        xpectation1.isInverted = true // won't be called, used just for waiting
        let viewController = IterableHtmlMessageViewController.create(parameters: IterableHtmlMessageViewController.Parameters(html: "",
                                                                                                                               padding: UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0),
                                                                                                                               messageMetadata: nil,
                                                                                                                               isModal: true,
                                                                                                                               inboxSessionId: nil)).viewController
        viewController.loadView()
        viewController.viewDidLayoutSubviews()
        wait(for: [xpectation1], timeout: 5.0)
        XCTAssertEqual(viewController.webView.view.frame.width, 1234.0)
    }
}
