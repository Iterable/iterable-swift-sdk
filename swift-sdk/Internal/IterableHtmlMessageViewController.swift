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

protocol MessageViewControllerEventTrackerProtocol {
    func trackInAppOpen(_ message: IterableInAppMessage,
                        location: InAppLocation,
                        inboxSessionId: String?)
    func trackInAppClose(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         source: InAppCloseSource?,
                         clickedUrl: String?)
    func trackInAppClick(_ message: IterableInAppMessage,
                         location: InAppLocation,
                         inboxSessionId: String?,
                         clickedUrl: String)
}

class MessageViewControllerEventTracker: MessageViewControllerEventTrackerProtocol {
    init(requestHandler: RequestHandlerProtocol?) {
        self.requestHandler = requestHandler
    }
    
    func trackInAppOpen(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?) {
        requestHandler?.trackInAppOpen(message, location: location, inboxSessionId: inboxSessionId, onSuccess: nil, onFailure: nil)
    }
    
    func trackInAppClose(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?, source: InAppCloseSource?, clickedUrl: String?) {
        requestHandler?.trackInAppClose(message, location: location, inboxSessionId: inboxSessionId, source: source, clickedUrl: clickedUrl, onSuccess: nil, onFailure: nil)
    }
    
    func trackInAppClick(_ message: IterableInAppMessage, location: InAppLocation, inboxSessionId: String?, clickedUrl: String) {
        requestHandler?.trackInAppClick(message, location: location, inboxSessionId: inboxSessionId, clickedUrl: clickedUrl, onSuccess: nil, onFailure: nil)
    }
    
    private let requestHandler: RequestHandlerProtocol?
}

protocol MessageViewControllerDelegate: AnyObject {
    func messageDidAppear()
    func messageDidDisappear()
    func messageDeinitialized()
}

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
    
    private init(parameters: Parameters,
                 eventTrackerProvider:  @escaping @autoclosure () -> MessageViewControllerEventTrackerProtocol?,
                 onClickCallback: ((URL) -> Void)?,
                 webViewProvider: @escaping @autoclosure () -> WebViewProtocol = IterableHtmlMessageViewController.createWebView(),
                 delegate: MessageViewControllerDelegate?) {
        ITBInfo()
        self.eventTrackerProvider = eventTrackerProvider
        self.webViewProvider = webViewProvider
        self.parameters = parameters
        self.onClickCallback = onClickCallback
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    static func create(parameters: Parameters,
                       eventTracker: @escaping @autoclosure () -> MessageViewControllerEventTrackerProtocol? = MessageViewControllerEventTracker(requestHandler: IterableAPI.implementation?.requestHandler),
                       onClickCallback: ((URL) -> Void)?,
                       delegate: MessageViewControllerDelegate? = nil) -> IterableHtmlMessageViewController {
        IterableHtmlMessageViewController(parameters: parameters, eventTrackerProvider: eventTracker(), onClickCallback: onClickCallback, delegate: delegate)
    }
    
    override var prefersStatusBarHidden: Bool { parameters.isModal }
    
    override func loadView() {
        ITBInfo()
        
        super.loadView()
        
        location = parameters.location

        if parameters.location == .full, let bgColor = parameters.backgroundColor {
            view.backgroundColor = bgColor
        } else {
            view.backgroundColor = InAppCalculations.initialViewBackgroundColor(isModal: parameters.isModal)
        }
        
        webView.set(position: ViewPosition(width: view.frame.width, height: view.frame.height, center: view.center))

        if location == .full {
            // Prevent the scroll view from automatically adjusting content insets for the safe area,
            // so the HTML content can extend behind the status bar / Dynamic Island / home indicator.
            if let wkWebView = webView.view as? WKWebView {
                wkWebView.scrollView.contentInsetAdjustmentBehavior = .never
            }
        }

        let html = (location == .full) ? Self.injectViewportFitCover(html: parameters.html) : parameters.html
        webView.loadHTMLString(html, baseURL: URL(string: ""))
        webView.set(navigationDelegate: self)

        view.addSubview(webView.view)
    }
    
    override func viewDidLoad() {
        ITBInfo()
        
        super.viewDidLoad()
        
        // Tracks an in-app open and lays out the webview
        if let messageMetadata = parameters.messageMetadata {
            eventTracker?.trackInAppOpen(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: parameters.inboxSessionId)
        }
        
        webView.layoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Only resize if webview has finished loading to prevent positioning issues
        // caused by calculating height before DOM is ready
        if webViewDidFinishLoading {
            resizeWebView(animate: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ITBInfo()
        super.viewDidAppear(animated)
        
        delegate?.messageDidAppear()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        ITBInfo()
        super.viewWillDisappear(animated)
        
        guard let messageMetadata = parameters.messageMetadata else {
            return
        }
        
        if let _ = navigationController, linkClicked == false {
            eventTracker?.trackInAppClose(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: parameters.inboxSessionId,
                                         source: InAppCloseSource.back,
                                         clickedUrl: nil)
        } else {
            eventTracker?.trackInAppClose(messageMetadata.message,
                                         location: messageMetadata.location,
                                         inboxSessionId: parameters.inboxSessionId,
                                         source: InAppCloseSource.link,
                                         clickedUrl: clickedLink)
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ITBInfo()
        delegate?.messageDidDisappear()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("IterableHtmlMessageViewController cannot be instantiated from Storyboard")
    }
    
    deinit {
        ITBInfo()
        delegate?.messageDeinitialized()
    }
    
    private var eventTrackerProvider: () -> MessageViewControllerEventTrackerProtocol?
    private var webViewProvider: () -> WebViewProtocol
    private var parameters: Parameters
    private var onClickCallback: ((URL) -> Void)?
    private var delegate: MessageViewControllerDelegate?
    private var location: IterableMessageLocation = .full
    private var linkClicked = false
    private var clickedLink: String?
    private var webViewDidFinishLoading = false
    
    private lazy var webView = webViewProvider()
    private var eventTracker: MessageViewControllerEventTrackerProtocol? {
        eventTrackerProvider()
    }
    
    private static func createWebView() -> WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }

    /// Injects `viewport-fit=cover` into the HTML viewport meta tag so the webview
    /// content extends behind the safe area (status bar / Dynamic Island / home indicator).
    /// If a viewport meta tag exists, appends `viewport-fit=cover` to it.
    /// If no viewport meta tag exists, inserts one into `<head>`.
    static func injectViewportFitCover(html: String) -> String {
        // Already has viewport-fit=cover — no change needed
        if html.range(of: "viewport-fit=cover", options: .caseInsensitive) != nil {
            return html
        }

        // Has a viewport meta tag — append viewport-fit=cover to its content
        // Matches both single and double quotes: name="viewport" or name='viewport'
        if let range = html.range(of: #"(<meta\s+name\s*=\s*["']viewport["']\s+content\s*=\s*)(["'])"#,
                                  options: [.regularExpression, .caseInsensitive]) {
            let quoteChar = String(html[html.index(before: range.upperBound)])
            if let contentEnd = html.range(of: quoteChar, options: [], range: range.upperBound..<html.endIndex) {
                var modified = html
                modified.insert(contentsOf: ", viewport-fit=cover", at: contentEnd.lowerBound)
                return modified
            }
        }

        // Also check content-first ordering: <meta content="..." name="viewport">
        if let range = html.range(of: #"(<meta\s+content\s*=\s*)(["'])"#,
                                  options: [.regularExpression, .caseInsensitive]) {
            let quoteChar = String(html[html.index(before: range.upperBound)])
            let afterQuote = range.upperBound
            // Verify this meta tag has name="viewport" or name='viewport'
            if let tagEnd = html.range(of: ">", options: [], range: afterQuote..<html.endIndex),
               let nameCheck = html.range(of: #"name\s*=\s*["']viewport["']"#,
                                          options: [.regularExpression, .caseInsensitive],
                                          range: afterQuote..<tagEnd.upperBound),
               !nameCheck.isEmpty,
               let contentEnd = html.range(of: quoteChar, options: [], range: afterQuote..<html.endIndex) {
                var modified = html
                modified.insert(contentsOf: "viewport-fit=cover, ", at: contentEnd.lowerBound)
                return modified
            }
        }

        // No viewport meta tag — insert one into <head>
        if let headClose = html.range(of: "</head>", options: .caseInsensitive) {
            var modified = html
            modified.insert(contentsOf: #"<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">"#  + "\n",
                            at: headClose.lowerBound)
            return modified
        }

        // No <head> tag — prepend a viewport meta tag
        return #"<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">"# + "\n" + html
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
                                         location: IterableMessageLocation) -> Pending<ViewPosition, IterableError> {
        guard location != .full else {
            return Fulfill(value: parentPosition)
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

extension IterableHtmlMessageViewController: WKNavigationDelegate {
    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        ITBInfo()
        webViewDidFinishLoading = true
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

        Self.trackClickOnDismiss(eventTracker: eventTracker,
                                 params: parameters,
                                 onClickCallback: onClickCallback,
                                 withURL: url,
                                 andDestinationURL: destinationUrl)

        animateWhileLeaving(webView.position)

        decisionHandler(.cancel)
    }
    
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if #available(iOS 14.0, *) {
            preferences.allowsContentJavaScript = false
        }
        guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
            decisionHandler(.allow, preferences)
            return
        }
        
        guard let parsed = InAppHelper.parse(inAppUrl: url) else {
            decisionHandler(.allow, preferences)
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

        Self.trackClickOnDismiss(eventTracker: eventTracker,
                                 params: parameters,
                                 onClickCallback: onClickCallback,
                                 withURL: url,
                                 andDestinationURL: destinationUrl)

        animateWhileLeaving(webView.position)

        decisionHandler(.cancel, preferences)
    }

    private static func trackClickOnDismiss(eventTracker: MessageViewControllerEventTrackerProtocol?,
                                            params: Parameters,
                                            onClickCallback: ((URL) -> Void)?,
                                            withURL url: URL,
                                            andDestinationURL destinationURL: String) {
        ITBInfo()
        onClickCallback?(url)
        if let messageMetadata = params.messageMetadata {
            eventTracker?.trackInAppClick(messageMetadata.message,
                                          location: messageMetadata.location,
                                          inboxSessionId: params.inboxSessionId,
                                          clickedUrl: destinationURL)
        }
    }

}
