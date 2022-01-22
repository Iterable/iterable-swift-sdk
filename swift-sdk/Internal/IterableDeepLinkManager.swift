//
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class IterableDeepLinkManager: NSObject {
    /// Handles a Universal Link
    /// For Iterable links, it will track the click and retrieve the original URL,
    /// pass it to `IterableURLDelegate` for handling
    /// If it's not an Iterable link, it just passes the same URL to `IterableURLDelegate`
    func handleUniversalLink(_ url: URL,
                             urlDelegate: IterableURLDelegate?,
                             urlOpener: UrlOpenerProtocol,
                             allowedProtocols: [String] = []) -> (Bool, Pending<IterableAttributionInfo?, Error>) {
        if isIterableDeepLink(url.absoluteString) {
            let pending = resolve(appLinkURL: url).map { (resolvedUrl, attributionInfo) -> IterableAttributionInfo? in
                var resolvedUrlString: String
                if let resolvedUrl = resolvedUrl {
                    resolvedUrlString = resolvedUrl.absoluteString
                } else {
                    resolvedUrlString = url.absoluteString
                }
                
                if let action = IterableAction.actionOpenUrl(fromUrlString: resolvedUrlString) {
                    let context = IterableActionContext(action: action, source: .universalLink)
                    
                    IterableActionRunner.execute(action: action,
                                                 context: context,
                                                 urlHandler: IterableUtil.urlHandler(fromUrlDelegate: urlDelegate,
                                                                                     inContext: context),
                                                 urlOpener: urlOpener,
                                                 allowedProtocols: allowedProtocols)
                }
                
                return attributionInfo
            }
            
            // Always return true for deep link
            return (true, pending)
        } else {
            if let action = IterableAction.actionOpenUrl(fromUrlString: url.absoluteString) {
                let context = IterableActionContext(action: action, source: .universalLink)
                
                IterableActionRunner.execute(action: action,
                                             context: context,
                                             urlHandler: IterableUtil.urlHandler(fromUrlDelegate: urlDelegate,
                                                                                 inContext: context),
                                             urlOpener: urlOpener,
                                             allowedProtocols: allowedProtocols)
            }
            return (false, Pending<IterableAttributionInfo?, Error>(value: nil))
        }
    }
    
    /// And we will resolve with redirected URL from our server and we will also try to get attribution info.
    /// Otherwise, we will just resolve with the original URL.
    private func resolve(appLinkURL: URL) -> Pending<(URL?, IterableAttributionInfo?), Error> {
        let fulfill = Pending<(URL?, IterableAttributionInfo?), Error>()
        
        deepLinkCampaignId = nil
        deepLinkTemplateId = nil
        deepLinkMessageId = nil
        
        if isIterableDeepLink(appLinkURL.absoluteString) {
            let trackAndRedirectTask = redirectUrlSession.dataTask(with: appLinkURL) { [unowned self] _, _, error in
                if let error = error {
                    ITBError("error: \(error.localizedDescription)")
                    fulfill.resolve(with: (nil, nil))
                } else {
                    if let deepLinkCampaignId = self.deepLinkCampaignId,
                        let deepLinkTemplateId = self.deepLinkTemplateId,
                        let deepLinkMessageId = self.deepLinkMessageId {
                        fulfill.resolve(with: (self.deepLinkLocation, IterableAttributionInfo(campaignId: deepLinkCampaignId, templateId: deepLinkTemplateId, messageId: deepLinkMessageId)))
                    } else {
                        fulfill.resolve(with: (self.deepLinkLocation, nil))
                    }
                }
            }
            
            trackAndRedirectTask.resume()
        } else {
            fulfill.resolve(with: (appLinkURL, nil))
        }
        
        return fulfill
    }
    
    private func isIterableDeepLink(_ urlString: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: Const.deepLinkRegex, options: []) else {
            return false
        }
        
        return regex.firstMatch(in: urlString, options: [], range: NSMakeRange(0, urlString.count)) != nil
    }
    
    private lazy var redirectUrlSession: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    private var deepLinkLocation: URL?
    private var deepLinkCampaignId: NSNumber?
    private var deepLinkTemplateId: NSNumber?
    private var deepLinkMessageId: String?
}

extension IterableDeepLinkManager: URLSessionDelegate, URLSessionTaskDelegate {
    /**
     Delegate handler when a redirect occurs. Stores a reference to the redirect url and does not execute the redirect.
     - parameters:
        - session: the session
        - task: the task
        - response: the redirectResponse
        - request: the request
        - completionHandler: the completionHandler
     */
    public func urlSession(_: URLSession,
                           task _: URLSessionTask,
                           willPerformHTTPRedirection response: HTTPURLResponse,
                           newRequest request: URLRequest,
                           completionHandler: @escaping (URLRequest?) -> Void) {
        deepLinkLocation = request.url
        
        guard let headerFields = response.allHeaderFields as? [String: String] else {
            return
        }
        
        guard let url = response.url else {
            return
        }
        
        for cookie in HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url) {
            if cookie.name == "iterableEmailCampaignId" {
                deepLinkCampaignId = number(fromString: cookie.value)
            } else if cookie.name == "iterableTemplateId" {
                deepLinkTemplateId = number(fromString: cookie.value)
            } else if cookie.name == "iterableMessageId" {
                deepLinkMessageId = cookie.value
            }
        }
        
        completionHandler(nil)
    }
    
    private func number(fromString str: String) -> NSNumber {
        if let intValue = Int(str) {
            return NSNumber(value: intValue)
        }
        
        return NSNumber(value: 0)
    }
}
