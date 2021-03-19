//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol CardStreamViewControllerViewModelProtocol {
    func isEmpty() -> Bool
    func numRows() -> Int
    func getWebViewForMessage(index: Int) -> WebViewProtocol
    func getSizeForMessage(index: Int, frame: CGRect) -> CGSize
}

class CardStreamViewControllerViewModel: CardStreamViewControllerViewModelProtocol {
    init(internalAPIProvider: @escaping @autoclosure () -> InternalIterableAPI? = IterableAPI.internalImplementation) {
        self.internalAPIProvider = internalAPIProvider
    }
    
    // MARK: - CardStreamViewControllerViewModelProtocol
    
    func isEmpty() -> Bool {
        inAppManager?.getInboxMessages().isEmpty ?? true && pushes.isEmpty
    }
    
    func numRows() -> Int {
        inAppManager?.getInboxMessages().count ?? 0 + pushes.count
    }
    
    func getWebViewForMessage(index: Int) -> WebViewProtocol {
        guard let message = inAppManager?.getInboxMessages()[index] else {
            return CardStreamViewControllerViewModel.createWebView()
        }
        
        return getWebView(message: message)
    }
    
    func getSizeForMessage(index: Int, frame: CGRect) -> CGSize {
        guard let message = inAppManager?.getInboxMessages()[index] else {
            return .zero
        }
        
        let webView = getWebView(message: message)
        
        webView.set(position: ViewPosition(width: frame.width,
                                           height: frame.height,
                                           center: frame.origin))
        
        print("jay getSizeForMessage \(webView.view.frame.width)")
        
        var webViewSize = CGSize(width: webView.view.frame.width, height: 0)
        
        webView.calculateHeight().onSuccess { calculatedHeight in
            webViewSize.height = calculatedHeight
            print("jay getSizeForMessage \(calculatedHeight)")
        }
        
        return webViewSize
    }
    
    // MARK: - Private/Internal
    
    private var inAppWebViewMap: [IterableInAppMessage: WebViewProtocol] = [:]
    
    private var pushes: [String] = []
    
    private var internalAPIProvider: () -> InternalIterableAPI?
    
    private var internalAPI: InternalIterableAPI? {
        internalAPIProvider()
    }
    
    private var inAppManager: IterableInternalInAppManagerProtocol? {
        internalAPI?.inAppManager
    }
    
    private static func createWebView() -> WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }
    
    private func getWebView(message: IterableInAppMessage) -> WebViewProtocol {
        // if it's already been made for the in-app, return that
        // otherwise create it and return that
        
        if let existingWebView = inAppWebViewMap[message] {
            return existingWebView
        } else {
            let webView = CardStreamViewControllerViewModel.createWebView()
            
            guard let content = message.content as? IterableHtmlInAppContent else {
                return webView
            }
            
            webView.loadHTMLString(content.html, baseURL: URL(string: ""))
            
            inAppWebViewMap[message] = webView
            
            return webView
        }
    }
}
