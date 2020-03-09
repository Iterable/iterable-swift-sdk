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
    
    func testWebViewPositioning() {
        IterableAPI.initializeForTesting()
        struct MockViewCalculations: ViewCalculationsProtocol {
            func width(for _: UIView) -> CGFloat {
                return 1234.0
            }
        }
        class MockWebView: WebViewProtocol {
            let view: UIView = UIView()
            
            func loadHTMLString(_: String, baseURL _: URL?) -> WKNavigation? {
                return nil
            }
            
            func set(position: ViewPosition) {
                self.position = position
                view.frame.size.width = position.width
                view.frame.size.height = position.height
                view.center = position.center
            }
            
            func set(navigationDelegate _: WKNavigationDelegate?) {}
            
            func evaluateJavaScript(_: String, completionHandler: ((Any?, Error?) -> Void)?) {
                completionHandler?(CGFloat(200.0), nil)
            }
            
            func layoutSubviews() {}
            
            var position: ViewPosition?
        }
        struct MockInjectedDependencyModule: InjectedDependencyModuleProtocol {
            static let shared = MockInjectedDependencyModule()
            
            let viewCalculations: ViewCalculationsProtocol = MockViewCalculations()
            
            let webView: WebViewProtocol = MockWebView()
            
            init() {}
        }
        
        InjectedDependencies.shared.set {
            MockInjectedDependencyModule.shared as InjectedDependencyModuleProtocol
        }
        
        let viewController = IterableHtmlMessageViewController.create(parameters: IterableHtmlMessageViewController.Parameters(html: "",
                                                                                                                               padding: UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 0),
                                                                                                                               messageMetadata: nil,
                                                                                                                               isModal: true,
                                                                                                                               inboxSessionId: nil)).viewController
        viewController.loadView()
        viewController.viewDidLayoutSubviews()
        
        let mockWebView = MockInjectedDependencyModule.shared.webView as! MockWebView
        XCTAssertEqual(mockWebView.view.frame.width, 1234.0)
        XCTAssertEqual(mockWebView.view.frame.height, 200.0)
        XCTAssertEqual(mockWebView.view.center.x, 617.0)
        XCTAssertEqual(mockWebView.view.center.y, 100.0)
    }
}
