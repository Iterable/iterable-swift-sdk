//
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit
import WebKit
import XCTest

@testable import IterableSDK

class InAppPresenterTests: XCTestCase {
    func testInAppPresenterDelegateExistence() {
        let htmlMessageViewController = IterableHtmlMessageViewController.create(parameters: getEmptyParameters(), onClickCallback: nil)
        
        let inAppPresenter = InAppPresenter(htmlMessageViewController: htmlMessageViewController,
                                            message: getEmptyInAppMessage())
        
        // a "no-op" to suppress warning
        _ = inAppPresenter.self
        
        XCTAssertNotNil(htmlMessageViewController.presenter)
    }
    
    func testInAppPresenterIsPresentingOnInit() {
        _ = InAppPresenter(htmlMessageViewController: getEmptyHtmlMessageViewController(),
                           message: getEmptyInAppMessage())
        
        XCTAssertFalse(InAppPresenter.isPresenting)
    }
    
    func testInAppPresenterShowMethod() {
        let expectation1 = expectation(description: "delay timer executed")
        
        let maxDelay = 0.75
        let inAppPresenter = InAppPresenter(htmlMessageViewController: getEmptyHtmlMessageViewController(),
                                            message: getEmptyInAppMessage(),
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
        IterableHtmlMessageViewController.create(parameters: getEmptyParameters(), onClickCallback: nil)
    }
    
    private func getEmptyHtmlInAppContent() -> IterableHtmlInAppContent {
        IterableHtmlInAppContent(edgeInsets: .zero, html: "")
    }
    
    private func getEmptyInAppMessage() -> IterableInAppMessage {
        IterableInAppMessage(messageId: "wasd", campaignId: 1, content: getEmptyHtmlInAppContent())
    }
}
