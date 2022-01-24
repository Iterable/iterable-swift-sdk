//
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest
import WebKit

@testable import IterableSDK

class WebViewProtocolTests: XCTestCase {
    func testVerifyViewPosition() {
        let webView = WKWebView(frame: CGRect(x: 0, y: 1, width: 2, height: 3))
        
        XCTAssertEqual(webView.position.center, webView.center)
        XCTAssertEqual(webView.position.width, webView.frame.size.width)
        XCTAssertEqual(webView.position.height, webView.frame.size.height)
    }
    
    func testWebViewHeightCalculationReject() {
        let condition1 = expectation(description: "")
        
        let webView = WKWebView(frame: .zero)
        
        let heightCalculationFuture = webView.calculateHeight()
        
        heightCalculationFuture.onSuccess { height in
            XCTFail("fulfill shouldn't have succeeded")
        }
        
        heightCalculationFuture.onError { error in
            XCTAssertEqual(error.errorDescription, "unable to get height")
            
            condition1.fulfill()
        }
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
}
