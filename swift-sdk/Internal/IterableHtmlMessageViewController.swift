//
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

@available(iOSApplicationExtension, unavailable)
class IterableHtmlMessageViewController: UIViewController {
    struct Parameters {
        let html: String
        let padding: Padding
        let messageMetadata: IterableInAppMessageMetadata?
        let isModal: Bool
        
        let inboxSessionId: String?
        let animationDuration = 0.67

        init(html: String,
             padding: Padding = .zero,
             messageMetadata: IterableInAppMessageMetadata? = nil,
             isModal: Bool,
             inboxSessionId: String? = nil) {
            ITBInfo()
            self.html = html
            self.padding = padding.adjusted()
            self.messageMetadata = messageMetadata
            self.isModal = isModal
            self.inboxSessionId = inboxSessionId
        }
        
        var shouldAnimate: Bool {
            messageMetadata
                .flatMap { $0.message.content as? IterableHtmlInAppContent }
                .map { $0.shouldAnimate } ?? false
        }
        
        var backgroundColor: UIColor? {
            messageMetadata
                .flatMap { $0.message.content as? IterableHtmlInAppContent }
                .flatMap { $0.backgroundColor }
        }
        
        var location: IterableMessageLocation {
            HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: padding)
        }
    }
    
    weak var presenter: InAppPresenter?
    
    init(parameters: Parameters,
         internalAPIProvider: @escaping @autoclosure () -> InternalIterableAPI? = IterableAPI.internalImplementation,
         webViewProvider: @escaping @autoclosure () -> WebViewProtocol = IterableHtmlMessageViewController.createWebView()) {
        ITBInfo()
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
    
    override var prefersStatusBarHidden: Bool { parameters.isModal }
    
    override func loadView() {
        ITBInfo()
        
        super.loadView()
        
        location = parameters.location

        view.backgroundColor = InAppCalculations.initialViewBackgroundColor(isModal: parameters.isModal)
        
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
    
        resizeWebView(animate: false)
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
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
    
    private var internalAPIProvider: () -> InternalIterableAPI?
    private var webViewProvider: () -> WebViewProtocol
    private var parameters: Parameters
    private let futureClickedURL: Promise<URL, IterableError>
    private var location: IterableMessageLocation = .full
    private var linkClicked = false
    private var clickedLink: String?
    
    private lazy var webView = webViewProvider()
    private var internalAPI: InternalIterableAPI? {
        internalAPIProvider()
    }
    
    private static func createWebView() -> WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }
    
    /// Resizes the webview based upon the insetPadding, height etc
    private func resizeWebView(animate: Bool) {
        let parentPosition = ViewPosition(width: view.bounds.width,
                                          height: view.bounds.height,
                                          center: view.center)
        IterableHtmlMessageViewController.calculateWebViewPosition(webView: webView,
                                                                   safeAreaInsets: InAppCalculations.safeAreaInsets(for: view),
                                                                   parentPosition: parentPosition,
                                                                   paddingLeft: CGFloat(parameters.padding.left),
                                                                   paddingRight: CGFloat(parameters.padding.right),
                                                                   location: location)
            .onSuccess { [weak self] position in
                if animate {
                    self?.animateWhileEntering(position)
                } else {
                    self?.webView.set(position: position)
                }
            }
    }
    
    private func animateWhileEntering(_ position: ViewPosition) {
        ITBInfo()
        createAnimationDetail(withPosition: position).map { applyAnimation(animationDetail: $0) } ?? (webView.set(position: position))
    }

    private func animateWhileLeaving(_ position: ViewPosition) {
        let animation = createAnimationDetail(withPosition: position).map(InAppCalculations.swapAnimation(animationDetail:))
        let dismisser = InAppCalculations.createDismisser(for: self,
                                                          isModal: parameters.isModal,
                                                          isInboxMessage: parameters.messageMetadata?.location == .inbox)
        animation.map { applyAnimation(animationDetail: $0, completion: dismisser) } ?? (dismisser())
    }

    private func createAnimationDetail(withPosition position: ViewPosition) -> InAppCalculations.AnimationDetail? {
        let input = InAppCalculations.AnimationInput(position: position,
                                                     isModal: parameters.isModal,
                                                     shouldAnimate: parameters.shouldAnimate,
                                                     location: location,
                                                     safeAreaInsets: InAppCalculations.safeAreaInsets(for: view),
                                                     backgroundColor: parameters.backgroundColor)
        return InAppCalculations.calculateAnimationDetail(animationInput: input)
    }
    
    private func applyAnimation(animationDetail: InAppCalculations.AnimationDetail, completion: (() -> Void)? = nil) {
        Self.animate(duration: parameters.animationDuration) { [weak self] in
            self?.webView.set(position: animationDetail.initial.position)
            self?.webView.view.alpha = animationDetail.initial.alpha
            self?.view.backgroundColor = animationDetail.initial.bgColor
        } finalValues: { [weak self] in
            self?.webView.set(position: animationDetail.final.position)
            self?.webView.view.alpha = animationDetail.final.alpha
            self?.view.backgroundColor = animationDetail.final.bgColor
        } completion: {
            completion?()
        }
    }
    
    static func animate(duration: TimeInterval,
                        initialValues: @escaping () -> Void,
                        finalValues: @escaping () -> Void,
                        completion: (() -> Void)? = nil) {
        ITBInfo()
        initialValues()
        UIView.animate(withDuration: duration) {
            finalValues()
        } completion: { _ in
            completion?()
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
            return InAppCalculations.calculateWebViewPosition(safeAreaInsets: safeAreaInsets,
                                                              parentPosition: parentPosition,
                                                              paddingLeft: paddingLeft,
                                                              paddingRight: paddingRight,
                                                              location: location,
                                                              inAppHeight: height)
        }
    }
}

@available(iOSApplicationExtension, unavailable)
extension IterableHtmlMessageViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        ITBInfo()
        resizeWebView(animate: true)
        presenter?.webViewDidFinish()
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

        Self.trackClickOnDismiss(internalAPI: internalAPI,
                                 params: parameters,
                                 futureClickedURL: futureClickedURL,
                                 withURL: url,
                                 andDestinationURL: destinationUrl)

        animateWhileLeaving(webView.position)

        decisionHandler(.cancel)
    }

    private static func trackClickOnDismiss(internalAPI: InternalIterableAPI?,
                                            params: Parameters,
                                            futureClickedURL: Promise<URL, IterableError>,
                                            withURL url: URL,
                                            andDestinationURL destinationURL: String) {
        ITBInfo()
        futureClickedURL.resolve(with: url)
        if let messageMetadata = params.messageMetadata {
            internalAPI?.trackInAppClick(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: params.inboxSessionId,
                                         clickedUrl: destinationURL)
        }
    }

}
