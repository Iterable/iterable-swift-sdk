//
//  Created by Tapash Majumder on 3/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit
import WebKit

enum IterableMessageLocation: Int {
    case full
    case top
    case center
    case bottom
}

class IterableHtmlMessageViewController: UIViewController {
    struct Parameters {
        let html: String
        let padding: UIEdgeInsets
        let messageMetadata: IterableInAppMessageMetadata?
        let isModal: Bool
        
        init(html: String,
             padding: UIEdgeInsets = .zero,
             messageMetadata: IterableInAppMessageMetadata? = nil,
             isModal: Bool) {
            self.html = html
            self.padding = IterableHtmlMessageViewController.padding(fromPadding: padding)
            self.messageMetadata = messageMetadata
            self.isModal = isModal
        }
    }
    
    init(parameters: Parameters) {
        self.parameters = parameters
        futureClickedURL = Promise<URL, IterableError>()
        super.init(nibName: nil, bundle: nil)
    }
    
    struct CreateResult {
        let viewController: IterableHtmlMessageViewController
        let futureClickedURL: Future<URL, IterableError>
    }
    
    static func create(parameters: Parameters) -> CreateResult {
        let viewController = IterableHtmlMessageViewController(parameters: parameters)
        return CreateResult(viewController: viewController, futureClickedURL: viewController.futureClickedURL)
    }
    
    override var prefersStatusBarHidden: Bool { return parameters.isModal }
    
    /**
     Loads the view and sets up the webView
     */
    override func loadView() {
        ITBInfo()
        super.loadView()
        
        location = HtmlContentParser.location(fromPadding: parameters.padding)
        if parameters.isModal {
            view.backgroundColor = UIColor.clear
        } else {
            view.backgroundColor = UIColor.white
        }
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        webView.loadHTMLString(parameters.html, baseURL: URL(string: ""))
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.navigationDelegate = self
        
        view.addSubview(webView)
        self.webView = webView
    }
    
    /**
     Tracks an inApp open and layouts the webview
     */
    override func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()
        
        if let messageMetadata = parameters.messageMetadata {
            IterableAPI.track(inAppOpen: messageMetadata.message,
                              location: messageMetadata.location)
        }
        
        webView?.layoutSubviews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let webView = webView {
            resizeWebView(webView)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let messageMetadata = parameters.messageMetadata else {
            return
        }
        
        if let _ = navigationController, linkClicked == false {
            IterableAPI.track(inAppClose: messageMetadata.message,
                              location: messageMetadata.location,
                              source: InAppCloseSource.back,
                              clickedUrl: nil)
        } else {
            IterableAPI.track(inAppClose: messageMetadata.message,
                              location: messageMetadata.location,
                              source: InAppCloseSource.link,
                              clickedUrl: clickedLink)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        parameters = aDecoder.decodeObject(forKey: "input") as? Parameters ?? Parameters(html: "", isModal: false)
        futureClickedURL = Promise<URL, IterableError>()
        super.init(coder: aDecoder)
    }
    
    private var parameters: Parameters
    private let futureClickedURL: Promise<URL, IterableError>
    private var webView: WKWebView?
    private var location: IterableMessageLocation = .full
    private var loaded = false
    private var linkClicked = false
    private var clickedLink: String?
    
    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
    private func resizeWebView(_ aWebView: WKWebView) {
        guard loaded else {
            return
        }
        
        guard location != .full else {
            webView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            return
        }
        
        // Resizes the frame to match the HTML content with a max of the screen size.
        var frame = aWebView.frame
        frame.size.height = 1
        aWebView.frame = frame
        let fittingSize = aWebView.scrollView.contentSize
        frame.size = fittingSize
        let notificationWidth = 100 - (parameters.padding.left + parameters.padding.right)
        let screenWidth = view.bounds.width
        frame.size.width = screenWidth * notificationWidth / 100
        frame.size.height = min(frame.height, view.bounds.height)
        aWebView.frame = frame
        
        let resizeCenterX = screenWidth * (parameters.padding.left + notificationWidth / 2) / 100
        
        // Position webview
        var center = view.center
        let webViewHeight = aWebView.frame.height / 2
        switch location {
        case .top:
            center.y = webViewHeight
        case .bottom:
            center.y = view.frame.height - webViewHeight
        case .center, .full: break
        }
        
        center.x = resizeCenterX
        aWebView.center = center
    }
    
    private static func padding(fromPadding padding: UIEdgeInsets) -> UIEdgeInsets {
        var insetPadding = padding
        if insetPadding.left + insetPadding.right >= 100 {
            ITBError("Can't display an in-app with padding > 100%. Defaulting to 0 for padding left/right")
            insetPadding.left = 0
            insetPadding.right = 0
        }
        
        return insetPadding
    }
}

extension IterableHtmlMessageViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        loaded = true
        if let myWebview = self.webView {
            resizeWebView(myWebview)
        }
    }
    
    fileprivate func trackInAppClick(destinationUrl: String) {
        if let messageMetadata = parameters.messageMetadata {
            IterableAPI.track(inAppClick: messageMetadata.message,
                              location: messageMetadata.location,
                              clickedUrl: destinationUrl)
        }
    }
    
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        guard let parsed = InAppHelper.parse(inAppUrl: url) else {
            decisionHandler(.allow)
            return
        }
        
        let destinationUrl: String
        if case let InAppHelper.InAppClickedUrl.localResource(name) = parsed {
            destinationUrl = name
        } else {
            destinationUrl = url.absoluteString
        }
        
        linkClicked = true
        clickedLink = destinationUrl
        
        if parameters.isModal {
            dismiss(animated: true) { [weak self, destinationUrl] in
                self?.futureClickedURL.resolve(with: url)
                self?.trackInAppClick(destinationUrl: destinationUrl)
            }
        } else {
            futureClickedURL.resolve(with: url)
            trackInAppClick(destinationUrl: destinationUrl)
            
            navigationController?.popViewController(animated: true)
        }
        
        decisionHandler(.cancel)
    }
}
