//
//  Created by Jay Kim on 5/5/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit
import XCTest

@testable import IterableSDK

class InAppPresenterTests: XCTestCase {
    static let delayTimerInterval = 0.5
    
    func testInAppPresenterDelegateExistence() {
        let topViewController = UIViewController()
        
        let htmlMessageViewController = IterableHtmlMessageViewController(parameters: getEmptyParameters())
        
        let inAppPresenter = InAppPresenter(topViewController: topViewController, htmlMessageViewController: htmlMessageViewController)
        
        print(inAppPresenter)
        
        XCTAssertNotNil(htmlMessageViewController.presenter)
    }
    
    func testInAppPresenterIsPresentingOnInit() {
        _ = InAppPresenter(topViewController: UIViewController(), htmlMessageViewController: getEmptyHtmlMessageViewController())
        
        XCTAssertFalse(InAppPresenter.isPresenting)
    }
    
    func testInAppPresenterWebViewDidFinish() {
        // also check for the timer being canceled
        
        XCTAssertFalse(InAppPresenter.isPresenting)
    }
    
    func testInAppPresenterTimerFinished() {
        let expectation1 = expectation(description: "delay timer executed")
        
        let topViewController = UIViewController()
        
        let inAppPresenter = InAppPresenter(topViewController: topViewController, htmlMessageViewController: getEmptyHtmlMessageViewController())
        
        inAppPresenter.show()
        
        XCTAssertTrue(InAppPresenter.isPresenting)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + InAppPresenterTests.delayTimerInterval + 0.1) {
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: testExpectationTimeout)
        
        // add a check for having presented in topViewController
        
        XCTAssertFalse(InAppPresenter.isPresenting)
    }
    
    private func getEmptyParameters() -> IterableHtmlMessageViewController.Parameters {
        return IterableHtmlMessageViewController.Parameters(html: "", isModal: false)
    }
    
    private func getEmptyHtmlMessageViewController() -> IterableHtmlMessageViewController {
        return IterableHtmlMessageViewController(parameters: getEmptyParameters())
    }
    
    private func getEmptyHtmlInAppContent() -> IterableHtmlInAppContent {
        return IterableHtmlInAppContent(edgeInsets: .zero, backgroundAlpha: 0.0, html: "")
    }
    
    private func getEmptyInAppMessage() -> IterableInAppMessage {
        return IterableInAppMessage(messageId: "asdf", campaignId: 1, content: getEmptyHtmlInAppContent())
    }
}
