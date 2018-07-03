//
//  IterableInAppHTMLViewController.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/7/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

@objc public class IterableInAppHTMLViewController: UIViewController {
    /**
     Constructs an inapp notification with via html
     
     - parameter htmlString: the html string
     */
    @objc public init(data htmlString: String) {
        self.htmlString = htmlString
        super.init(nibName: nil, bundle: nil)
    }
    
    /**
     Sets the padding
     
     - parameter: insetPadding the padding
     
     - remark: defaults to 0 for left/right if left+right > 100
     */
    @objc public func ITESetPadding(_ padding: UIEdgeInsets) {
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
    @objc public func ITESetCallback(_ callbackBlock: ITEActionBlock?) {
        customBlockCallback = callbackBlock
    }

    /**
     Sets the track parameters
     
     - parameter params: the track parameters
     */
    @objc public func ITESetTrackParams(_ params:IterableNotificationMetadata?) {
        trackParams = params
    }

    /**
     Gets the html string
     
     - returns: a NSString of the html
     */
    @objc public func getHtml() -> String? {
        return htmlString
    }
    
    /**
     Gets the location from a inset data
     
     - returns: the location as an INAPP_NOTIFICATION_TYPE
     */
    @objc public static func setLocation(_ padding: UIEdgeInsets) -> INAPP_NOTIFICATION_TYPE {
        if padding.top == 0 && padding.bottom == 0 {
            return .FULL
        } else if padding.top == 0 && padding.bottom < 0 {
            return .TOP
        } else if padding.top < 0 && padding.bottom == 0 {
            return .BOTTOM
        } else {
            return .CENTER
        }
    }
    
    /**
     Loads the view and sets up the webView
     */
    public override func loadView() {
        super.loadView()
        
        location = IterableInAppHTMLViewController.setLocation(insetPadding)
        view.backgroundColor = UIColor.clear
        
        let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        webView.loadHTMLString(htmlString, baseURL: URL(string: ""))
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
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let trackParams = trackParams, let messageId = trackParams.messageId {
            IterableAPI.sharedInstance?.trackInAppOpen(messageId)
        }

        webView?.layoutSubviews()
    }
    
    public override var prefersStatusBarHidden: Bool {return true}

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let webView = webView {
            resizeWebView(webView)
        }
    }
    
    private let htmlString: String
    private var insetPadding: UIEdgeInsets = UIEdgeInsets.zero
    private var customBlockCallback: ITEActionBlock?
    private var trackParams: IterableNotificationMetadata?
    private var webView: UIWebView?
    private var location: INAPP_NOTIFICATION_TYPE = .FULL
    private var loaded = false
    
    private let customUrlScheme = "applewebdata"
    private let httpUrlScheme = "http://"
    private let httpsUrlScheme = "https://"
    private let itblUrlScheme = "itbl://"


    public required init?(coder aDecoder: NSCoder) {
        self.htmlString = aDecoder.decodeObject(forKey: "htmlString") as? String ?? ""

        super.init(coder: aDecoder)
    }
    
    /**
     Resizes the webview based upon the insetPadding if the html is finished loading
     
     - parameter: aWebView the webview
     */
    private func resizeWebView(_ aWebView :UIWebView) {
        guard loaded else {
            return
        }
        guard location != .FULL else {
            webView?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            return
        }
        
        //Resizes the frame to match the HTML content with a max of the screen size.
        var frame = aWebView.frame
        frame.size.height = 1
        aWebView.frame = frame;
        let fittingSize = aWebView.sizeThatFits(.zero)
        frame.size = fittingSize
        let notificationWidth = 100 - (insetPadding.left + insetPadding.right)
        let screenWidth = view.bounds.width
        frame.size.width = screenWidth*notificationWidth/100
        frame.size.height = min(frame.height, self.view.bounds.height)
        aWebView.frame = frame;
        
        let resizeCenterX = screenWidth*(insetPadding.left + notificationWidth/2)/100

        //Position webview
        var center = self.view.center
        let webViewHeight = aWebView.frame.height/2
        switch location {
        case .TOP:
            center.y = webViewHeight
        case .BOTTOM:
            center.y = view.frame.height - webViewHeight
        case .CENTER,.FULL: break
        }
        center.x = resizeCenterX;
        aWebView.center = center;
    }
}

extension IterableInAppHTMLViewController : UIWebViewDelegate {
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        loaded = true
        if let myWebview = self.webView {
            resizeWebView(myWebview)
        }
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard navigationType == .linkClicked else {
            return true
        }
        guard let url = request.url else {
            return true
        }

        var destinationURL = url.absoluteString
        var callbackURL = url.absoluteString

        if url.scheme == customUrlScheme {
            // Since we are calling loadHTMLString with a nil baseUrl, any request url without a valid scheme get treated as a local resource.
            // Removes the extra applewebdata scheme/host data that is appended to the original url.
            guard let host = url.host else {
                return true
            }
            let urlArray = destinationURL.components(separatedBy: host)
            guard urlArray.count > 1 else {
                return true
            }
            let urlPath = urlArray[1]
            if urlPath.count > 0 {
                //Removes extra "/" from the url path
                if urlPath.starts(with: "/") {
                    destinationURL = String(urlPath.dropFirst())
                }
            }
            callbackURL = destinationURL

            //Warn the client that the request url does not contain a valid scheme
            ITBError("Request url contains an invalid scheme: \(destinationURL)")
        } else if destinationURL.hasPrefix(itblUrlScheme) == true {
            callbackURL = destinationURL.replacingOccurrences(of: itblUrlScheme, with: "")
        }
        
        dismiss(animated: false) { [weak self, callbackURL] in
            self?.customBlockCallback?(callbackURL)
            if let trackParams = self?.trackParams, let messageId = trackParams.messageId {
                IterableAPI.sharedInstance?.trackInAppClick(messageId, buttonURL: destinationURL)
            }
        }
        return false
    }
}
