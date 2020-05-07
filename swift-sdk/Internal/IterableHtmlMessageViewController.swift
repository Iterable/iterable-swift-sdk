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
    
    init(parameters: Parameters, internalAPIProvider: @escaping @autoclosure () -> IterableAPIInternal? = IterableAPI.internalImplementation) {
        self.internalAPIProvider = internalAPIProvider
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
        
        webView.set(position: ViewPosition(width: view.frame.width, height: view.frame.height, center: view.center))
        webView.loadHTMLString(parameters.html, baseURL: URL(string: ""))
        webView.set(navigationDelegate: self)
        
        view.addSubview(webView.view)
    }
    
    /**
     Tracks an inApp open and layouts the webview
     */
    override func viewDidLoad() {
        ITBInfo()
        super.viewDidLoad()
        
        if let messageMetadata = parameters.messageMetadata {
            internalAPI?.trackInAppOpen(messageMetadata.message,
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
            internalAPI?.trackInAppClose(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                source: InAppCloseSource.back,
                                                                clickedUrl: nil)
        } else {
            internalAPI?.trackInAppClose(messageMetadata.message,
                                                                location: messageMetadata.location,
                                                                inboxSessionId: parameters.inboxSessionId,
                                                                source: InAppCloseSource.link,
                                                                clickedUrl: clickedLink)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("IterableHtmlMessageViewController cannot be instantiated from Storyboard")
    }
    
    deinit {
        ITBInfo()
    }
    
    private var internalAPIProvider: () -> IterableAPIInternal?
    private var parameters: Parameters
    private let futureClickedURL: Promise<URL, IterableError>
    private var location: IterableMessageLocation = .full
    private var linkClicked = false
    private var clickedLink: String?
    @Inject private var dependencyModule: InjectedDependencyModuleProtocol!
    private lazy var viewCalculations: ViewCalculationsProtocol! = {
        dependencyModule.viewCalculations
    }()
    
    lazy var webView: WebViewProtocol! = {
        dependencyModule.webView
    }()
    var internalAPI: IterableAPIInternal? {
        return internalAPIProvider()
    }
    
    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
    private func resizeWebView(_ aWebView: WebViewProtocol) {
        guard location != .full else {
            webView.set(position: ViewPosition(width: viewCalculations.width(for: view), height: viewCalculations.height(for: view), center: viewCalculations.center(for: view)))
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
    
    private func resize(webView: WebViewProtocol, withHeight height: CGFloat) {
        ITBInfo("height: \(height)")
        var position = ViewPosition()
        // set the height
        position.height = height
        
        // now set the width
        let notificationWidth = 100 - (parameters.padding.left + parameters.padding.right)
        let screenWidth = viewCalculations.width(for: view)
        position.width = screenWidth * notificationWidth / 100
        
        // Position webview
        position.center = viewCalculations.center(for: view)
        
        // set center x
        position.center.x = screenWidth * (parameters.padding.left + notificationWidth / 2) / 100
        
        // set center y
        let halfWebViewHeight = height / 2
        switch location {
        case .top:
            position.center.y = halfWebViewHeight + viewCalculations.safeAreaInsets(for: view).top
        case .bottom:
            position.center.y = viewCalculations.height(for: view) - halfWebViewHeight - viewCalculations.safeAreaInsets(for: view).bottom
        default: break
        }
        
        webView.set(position: position)
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
            internalAPI?.trackInAppClick(messageMetadata.message,
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
