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
    
    weak var presenter: InAppPresenter?
    
    init(parameters: Parameters,
         internalAPIProvider: @escaping @autoclosure () -> IterableAPIInternal? = IterableAPI.internalImplementation,
         webViewProvider: @escaping @autoclosure () -> WebViewProtocol = IterableHtmlMessageViewController.createWebView()) {
        self.internalAPIProvider = internalAPIProvider
        self.webViewProvider = webViewProvider
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
    
    override func viewDidLoad() {
        ITBInfo()
        
        super.viewDidLoad()
        
        // Tracks an in-app open and layouts the webview
        if let messageMetadata = parameters.messageMetadata {
            internalAPI?.trackInAppOpen(messageMetadata.message,
                                        location: messageMetadata.location,
                                        inboxSessionId: parameters.inboxSessionId)
        }
        
        webView.layoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resizeWebView()
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
    
    required init?(coder _: NSCoder) {
        fatalError("IterableHtmlMessageViewController cannot be instantiated from Storyboard")
    }
    
    deinit {
        ITBInfo()
    }
    
    private var internalAPIProvider: () -> IterableAPIInternal?
    private var webViewProvider: () -> WebViewProtocol
    private var parameters: Parameters
    private let futureClickedURL: Promise<URL, IterableError>
    private var location: IterableMessageLocation = .full
    private var linkClicked = false
    private var clickedLink: String?
    
    private lazy var webView = webViewProvider()
    private var internalAPI: IterableAPIInternal? {
        return internalAPIProvider()
    }
    
    private static func createWebView() -> WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }
    
    /// Resizes the webview based upon the insetPadding, height etc
    private func resizeWebView() {
        let parentPosition = ViewPosition(width: view.bounds.width,
                                          height: view.bounds.height,
                                          center: view.center)
        IterableHtmlMessageViewController.calculateWebViewPosition(webView: webView,
                                                                   safeAreaInsets: IterableHtmlMessageViewController.safeAreaInsets(for: view),
                                                                   parentPosition: parentPosition,
                                                                   paddingLeft: parameters.padding.left,
                                                                   paddingRight: parameters.padding.right,
                                                                   location: location)
            .onSuccess { [weak self] position in
                self?.webView.set(position: position)
            }
    }
    
    private static func safeAreaInsets(for view: UIView) -> UIEdgeInsets {
        if #available(iOS 11, *) {
            return view.safeAreaInsets
        } else {
            return .zero
        }
    }
    
    static func calculateWebViewPosition(webView: WebViewProtocol,
                                         safeAreaInsets: UIEdgeInsets,
                                         parentPosition: ViewPosition,
                                         paddingLeft: CGFloat,
                                         paddingRight: CGFloat,
                                         location: IterableMessageLocation) -> Future<ViewPosition, IterableError> {
        guard location != .full else {
            return Promise(value: parentPosition)
        }
        
        return webView.calculateHeight().map { height in
            ITBInfo("height: \(height)")
            return IterableHtmlMessageViewController.calculateWebViewPosition(safeAreaInsets: safeAreaInsets,
                                                                              parentPosition: parentPosition,
                                                                              paddingLeft: paddingLeft,
                                                                              paddingRight: paddingRight,
                                                                              location: location,
                                                                              inAppHeight: height)
        }
    }
    
    private static func calculateWebViewPosition(safeAreaInsets: UIEdgeInsets,
                                                 parentPosition: ViewPosition,
                                                 paddingLeft: CGFloat,
                                                 paddingRight: CGFloat,
                                                 location: IterableMessageLocation,
                                                 inAppHeight: CGFloat) -> ViewPosition {
        var position = ViewPosition()
        // set the height
        position.height = inAppHeight
        
        // now set the width
        let notificationWidth = 100 - (paddingLeft + paddingRight)
        position.width = parentPosition.width * notificationWidth / 100
        
        // Position webview
        position.center = parentPosition.center
        
        // set center x
        position.center.x = parentPosition.width * (paddingLeft + notificationWidth / 2) / 100
        
        // set center y
        let halfWebViewHeight = inAppHeight / 2
        switch location {
        case .top:
            position.center.y = halfWebViewHeight + safeAreaInsets.top
        case .bottom:
            position.center.y = parentPosition.height - halfWebViewHeight - safeAreaInsets.bottom
        default: break
        }
        
        return position
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
        ITBInfo()
        resizeWebView()
        presenter?.webViewDidFinish()
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
