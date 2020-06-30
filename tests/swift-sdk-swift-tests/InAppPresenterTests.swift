//
//  Created by Jay Kim on 5/5/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit
import WebKit
import XCTest

@testable import IterableSDK

class InAppPresenterTests: XCTestCase {
    func testInAppPresenterDelegateExistence() {
        let htmlMessageViewController = IterableHtmlMessageViewController(parameters: getEmptyParameters())
        
        let inAppPresenter = InAppPresenter(topViewController: UIViewController(),
                                            htmlMessageViewController: htmlMessageViewController)
        
        // a "no-op" to suppress warning
        _ = inAppPresenter.self
        
        XCTAssertNotNil(htmlMessageViewController.presenter)
    }
    
    func testInAppPresenterIsPresentingOnInit() {
        _ = InAppPresenter(topViewController: UIViewController(),
                           htmlMessageViewController: getEmptyHtmlMessageViewController())
        
        XCTAssertFalse(InAppPresenter.isPresenting)
    }
    
    func testInAppPresenterTimerFinished() {
        let expectation1 = expectation(description: "delay timer executed")
        
        let topViewController = UIViewController()
        let maxDelay = 0.75
        let inAppPresenter = InAppPresenter(topViewController: topViewController,
                                            htmlMessageViewController: getEmptyHtmlMessageViewController(),
                                            maxDelay: maxDelay)
        
        inAppPresenter.show()
        
        XCTAssertTrue(InAppPresenter.isPresenting)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDelay + 0.1) {
            XCTAssertFalse(InAppPresenter.isPresenting)
            
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
    }
    
    private func getEmptyParameters() -> IterableHtmlMessageViewController.Parameters {
        IterableHtmlMessageViewController.Parameters(html: "", isModal: false)
    }
    
    private func getEmptyHtmlMessageViewController() -> IterableHtmlMessageViewController {
        IterableHtmlMessageViewController(parameters: getEmptyParameters())
    }
    
    private func getEmptyHtmlInAppContent() -> IterableHtmlInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
    
    private func getEmptyInAppMessage() -> IterableInAppMessage {
        IterableInAppMessage(messageId: "wasd", campaignId: 1, content: getEmptyHtmlInAppContent())
    }
}
