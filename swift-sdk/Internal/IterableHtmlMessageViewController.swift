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
        
        let inboxSessionId: String?
        
        init(html: String,
             padding: UIEdgeInsets = .zero,
             messageMetadata: IterableInAppMessageMetadata? = nil,
             isModal: Bool,
             inboxSessionId: String? = nil) {
            self.html = html
            self.padding = IterableHtmlMessageViewController.padding(fromPadding: padding)
            self.messageMetadata = messageMetadata
            self.isModal = isModal
            self.inboxSessionId = inboxSessionId
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
            if #available(iOS 13, *) {
                view.backgroundColor = UIColor.systemBackground
            } else {
                view.backgroundColor = UIColor.white
            }
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
            IterableAPI.internalImplementation?.trackInAppOpen(messageMetadata.message,
                                                               location: messageMetadata.location,
                                                               inboxSessionId: parameters.inboxSessionId)
        }
        
        webView?.layoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let webView = self.webView else {
            return
        }
        resizeWebView(webView)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard let messageMetadata = parameters.messageMetadata else {
            return
        }
        
        if let _ = navigationController, linkClicked == false {
            IterableAPI.internalImplementation?.trackInAppClose(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                source: InAppCloseSource.back,
                                                                clickedUrl: nil)
        } else {
            IterableAPI.internalImplementation?.trackInAppClose(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                source: InAppCloseSource.back,
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
    private var linkClicked = false
    private var clickedLink: String?
    
    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
    private func resizeWebView(_ aWebView: WKWebView) {
        guard location != .full else {
            webView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            return
        }
        
        aWebView.evaluateJavaScript("document.body.offsetHeight", completionHandler: { height, _ in
            guard let floatHeight = height as? CGFloat, floatHeight >= 20 else {
                ITBError("unable to get height")
                return
            }
            self.resize(webView: aWebView, withHeight: floatHeight)
        })
    }
    
    private func resize(webView: WKWebView, withHeight height: CGFloat) {
        ITBInfo("height: \(height)")
        // set the height
        webView.frame.size.height = height
        
        // now set the width
        let notificationWidth = 100 - (parameters.padding.left + parameters.padding.right)
        let screenWidth = view.bounds.width
        webView.frame.size.width = screenWidth * notificationWidth / 100
        
        // Position webview
        var center = view.center
        
        // set center x
        center.x = screenWidth * (parameters.padding.left + notificationWidth / 2) / 100
        
        // set center y
        let halfWebViewHeight = webView.frame.height / 2
        switch location {
        case .top:
            if #available(iOS 11, *) {
                center.y = halfWebViewHeight + view.safeAreaInsets.top
            } else {
                center.y = halfWebViewHeight
            }
        case .bottom:
            if #available(iOS 11, *) {
                center.y = view.frame.height - halfWebViewHeight - view.safeAreaInsets.bottom
            } else {
                center.y = view.frame.height - halfWebViewHeight
            }
        default: break
        }
        
        webView.center = center
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
        if let myWebview = self.webView {
            resizeWebView(myWebview)
        }
    }
    
    fileprivate func trackInAppClick(destinationUrl: String) {
        if let messageMetadata = parameters.messageMetadata {
            IterableAPI.internalImplementation?.trackInAppClick(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
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
