//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation
import WebKit

struct ViewPosition: Equatable {
    var width: CGFloat = 0
    var height: CGFloat = 0
    var center: CGPoint = CGPoint.zero
}

protocol WebViewProtocol {
    var view: UIView { get }
    var position: ViewPosition { get }
    @discardableResult func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation?
    func set(position: ViewPosition)
    func set(navigationDelegate: WKNavigationDelegate?)
    func layoutSubviews()
    func calculateHeight() -> Pending<CGFloat, IterableError>
}

extension WKWebView: WebViewProtocol {
    var view: UIView {
        self
    }
    
    var position: ViewPosition {
        ViewPosition(width: frame.size.width, height: frame.size.height, center: center)
    }
    
    func set(position: ViewPosition) {
        frame.size.width = position.width
        frame.size.height = position.height
        center = position.center
    }
    
    func set(navigationDelegate: WKNavigationDelegate?) {
        self.navigationDelegate = navigationDelegate
    }
    
    func calculateHeight() -> Pending<CGFloat, IterableError> {
        let fulfill = Fulfill<CGFloat, IterableError>()

        // First measurement
        evaluateJavaScript("document.body.offsetHeight", completionHandler: { [weak self] firstHeight, _ in
            guard let floatHeight = firstHeight as? CGFloat, floatHeight >= 20 else {
                ITBError("unable to get height")
                fulfill.reject(with: IterableError.general(description: "unable to get height"))
                return
            }

            // Wait briefly for the DOM to stabilize, then re-measure.
            // This prevents the auto-dismiss freeze that occurs when the initial height
            // measurement is taken before the DOM has fully laid out, leading to incorrect
            // positioning and an unresponsive dismiss gesture.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.evaluateJavaScript("document.body.offsetHeight", completionHandler: { secondHeight, _ in
                    if let stableHeight = secondHeight as? CGFloat, stableHeight >= 20 {
                        fulfill.resolve(with: stableHeight)
                    } else {
                        // Fall back to first measurement if second fails
                        fulfill.resolve(with: floatHeight)
                    }
                })
            }
        })

        return fulfill
    }
}
