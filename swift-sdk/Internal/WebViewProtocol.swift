//
//  Created by Tapash Majumder on 3/9/20.
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
    @discardableResult func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation?
    func set(position: ViewPosition)
    func set(navigationDelegate: WKNavigationDelegate?)
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
    func layoutSubviews()
    func calculateHeight() -> Future<CGFloat, IterableError>
}

extension WKWebView: WebViewProtocol {
    var view: UIView {
        self
    }
    
    func set(position: ViewPosition) {
        frame.size.width = position.width
        frame.size.height = position.height
        center = position.center
    }
    
    func set(navigationDelegate: WKNavigationDelegate?) {
        self.navigationDelegate = navigationDelegate
    }
    
    func calculateHeight() -> Future<CGFloat, IterableError> {
        let promise = Promise<CGFloat, IterableError>()
        
        evaluateJavaScript("document.body.offsetHeight", completionHandler: { height, _ in
            guard let floatHeight = height as? CGFloat, floatHeight >= 20 else {
                ITBError("unable to get height")
                promise.reject(with: IterableError.general(description: "unable to get height"))
                return
            }
            
            promise.resolve(with: floatHeight)
        })
        
        return promise
    }
}
