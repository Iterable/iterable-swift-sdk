//
//
//  Created by Tapash Majumder on 3/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

enum IterableMessageLocation : Int {
    case full
    case top
    case center
    case bottom
}

class IterableHtmlMessageViewController: UIViewController {
    struct Input {
        let html: String
        let padding: UIEdgeInsets
        let callback: ITEActionBlock?
        let trackParams: IterableNotificationMetadata?
        let isModal: Bool
        
        init(html: String,
             padding: UIEdgeInsets = .zero,
             callback: ITEActionBlock? = nil,
             trackParams: IterableNotificationMetadata? = nil,
             isModal: Bool) {
            self.html = html
            self.padding = IterableHtmlMessageViewController.padding(fromPadding: padding)
            self.callback = callback
            self.trackParams = trackParams
            self.isModal = isModal
        }
    }

    init(input: Input) {
        self.input = input
        super.init(nibName: nil, bundle: nil)
    }
    
    override var prefersStatusBarHidden: Bool {return input.isModal}
    
    /**
     Loads the view and sets up the webView
     */
    override func loadView() {
        super.loadView()
        
        location = HtmlContentParser.location(fromPadding: input.padding)
        if input.isModal {
            view.backgroundColor = UIColor.clear
        } else {
            view.backgroundColor = UIColor.white
        }
        
        let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        webView.loadHTMLString(input.html, baseURL: URL(string: ""))
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.delegate = self
        
        view.addSubview(webView)
        self.webView = webView
    }

    
    /**
     Tracks an inApp open and layouts the webview
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let trackParams = input.trackParams, let messageId = trackParams.messageId {
            IterableAPIInternal.sharedInstance?.trackInAppOpen(messageId)
        }
        
        webView?.layoutSubviews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let webView = webView {
            resizeWebView(webView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.input = aDecoder.decodeObject(forKey: "input") as? Input ?? Input(html: "", isModal: false)

        super.init(coder: aDecoder)
    }

    private var input: Input
    private var webView: UIWebView?
    private var location: IterableMessageLocation = .full
    private var loaded = false

    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
    private func resizeWebView(_ aWebView :UIWebView) {
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
        aWebView.frame = frame;
        let fittingSize = aWebView.sizeThatFits(.zero)
        frame.size = fittingSize
        let notificationWidth = 100 - (input.padding.left + input.padding.right)
        let screenWidth = view.bounds.width
        frame.size.width = screenWidth*notificationWidth/100
        frame.size.height = min(frame.height, self.view.bounds.height)
        aWebView.frame = frame;
        
        let resizeCenterX = screenWidth*(input.padding.left + notificationWidth/2)/100
        
        // Position webview
        var center = self.view.center
        let webViewHeight = aWebView.frame.height/2
        switch location {
        case .top:
            center.y = webViewHeight
        case .bottom:
            center.y = view.frame.height - webViewHeight
        case .center,.full: break
        }
        center.x = resizeCenterX;
        aWebView.center = center;
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

extension IterableHtmlMessageViewController : UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loaded = true
        if let myWebview = self.webView {
            resizeWebView(myWebview)
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard navigationType == .linkClicked, let url = request.url else {
            return true
        }
        
        guard let (callbackURL, destinationURL) = InAppHelper.getCallbackAndDestinationUrl(url: url) else {
            return true
        }
        
        if input.isModal {
            dismiss(animated: false) { [weak self, callbackURL] in
                self?.input.callback?(callbackURL)
                if let trackParams = self?.input.trackParams, let messageId = trackParams.messageId {
                    IterableAPIInternal.sharedInstance?.trackInAppClick(messageId, buttonURL: destinationURL)
                }
            }
        } else {
            input.callback?(callbackURL)
            if let trackParams = input.trackParams, let messageId = trackParams.messageId {
                IterableAPIInternal.sharedInstance?.trackInAppClick(messageId, buttonURL: destinationURL)
            }
            navigationController?.popViewController(animated: true)
        }
        
        return false
    }
}
