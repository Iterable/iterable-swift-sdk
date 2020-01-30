//
//
//  Created by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit
import WebKit

enum InAppNotificationType : Int {
    case full
    case top
    case center
    case bottom
}

class IterableInAppHTMLViewController: UIViewController {
    /**
     Constructs an inapp notification with via html
     
     - parameter htmlString: the html string
     */
    init(data htmlString: String) {
        self.htmlString = htmlString
        super.init(nibName: nil, bundle: nil)
    }
    
    /**
     Sets the padding
     
     - parameter: insetPadding the padding
     
     - remark: defaults to 0 for left/right if left+right > 100
     */
    func ITESetPadding(_ padding: UIEdgeInsets) {
        var insetPadding = padding
        
        if insetPadding.left + insetPadding.right >= 100 {
            ITBError("Can't display an in-app with padding > 100%. Defaulting to 0 for padding left/right")
            insetPadding.left = 0
            insetPadding.right = 0
        }

        self.insetPadding = insetPadding
    }

    /**
     Sets the callback
     
     - parameter callbackBlock: the payload data
     */
    func ITESetCallback(_ callbackBlock: ITBURLCallback?) {
        customBlockCallback = callbackBlock
    }

    /**
     Sets the track parameters
     
     - parameter params: the track parameters
     */
    func ITESetTrackParams(_ params:IterableNotificationMetadata?) {
        trackParams = params
    }

    /**
     Gets the html string
     
     - returns: a NSString of the html
     */
    func getHtml() -> String? {
        return htmlString
    }
    
    /**
     Gets the location from a inset data
     
     - returns: the location as an INAPP_NOTIFICATION_TYPE
     */
    static func location(fromPadding padding: UIEdgeInsets) -> InAppNotificationType {
        if padding.top == 0 && padding.bottom == 0 {
            return .full
        } else if padding.top == 0 && padding.bottom < 0 {
            return .top
        } else if padding.top < 0 && padding.bottom == 0 {
            return .bottom
        } else {
            return .center
        }
    }
    
    /**
     Loads the view and sets up the webView
     */
    override func loadView() {
        super.loadView()
        
        location = IterableInAppHTMLViewController.location(fromPadding: insetPadding)
        view.backgroundColor = UIColor.clear
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        webView.loadHTMLString(htmlString, baseURL: URL(string: ""))
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
        super.viewDidLoad()
        
        if let trackParams = trackParams, let messageId = trackParams.messageId {
            IterableAPIInternal.sharedInstance?.trackInAppOpen(messageId)
        }

        webView?.layoutSubviews()
    }
    
    override var prefersStatusBarHidden: Bool {return true}
    
    private let htmlString: String
    private var insetPadding: UIEdgeInsets = UIEdgeInsets.zero
    private var customBlockCallback: ITBURLCallback?
    private var trackParams: IterableNotificationMetadata?
    private var webView: WKWebView?
    private var location: InAppNotificationType = .full
    
    required init?(coder aDecoder: NSCoder) {
        self.htmlString = aDecoder.decodeObject(forKey: "htmlString") as? String ?? ""

        super.init(coder: aDecoder)
    }
    
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
        let notificationWidth = 100 - (insetPadding.left + insetPadding.right)
        let screenWidth = view.bounds.width
        webView.frame.size.width = screenWidth * notificationWidth / 100
        
        // Position webview
        var center = view.center
        
        // set center x
        center.x = screenWidth * (insetPadding.left + notificationWidth / 2) / 100
        
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
}

extension IterableInAppHTMLViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ITBInfo()
        
        if let myWebview = self.webView {
            resizeWebView(myWebview)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        ITBInfo()
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
        
        dismiss(animated: false) { [weak self] in
            self?.customBlockCallback?(url)
            if let trackParams = self?.trackParams, let messageId = trackParams.messageId {
                IterableAPIInternal.sharedInstance?.trackInAppClick(messageId, buttonURL: destinationUrl)
            }
        }

        decisionHandler(.cancel)
    }
}
