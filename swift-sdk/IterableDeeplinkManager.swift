//
//  IterableDeeplinkManager.swift
//  new-ios-sdk
//
//  Created by Tapash Majumder on 6/1/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation

class IterableDeeplinkManager : NSObject {
    /**
     A singleton of IterableDeeplinkManager
     */
    static var instance = IterableDeeplinkManager()
    
    /**
     Tracks a link click and passes the redirected URL to the callback
     
     - parameter webpageURL:      the URL that was clicked
     - parameter callbackBlock:   the callback to send after the webpageURL is called
     
     - remark:            passes the string of the redirected URL to the callback
     */
    func getAndTrackDeeplink(webpageURL: URL, callbackBlock: @escaping ITEActionBlock) {
        _ = resolve(applinkURL: webpageURL) { (resolvedUrl) in
            callbackBlock(resolvedUrl?.absoluteString)
        }
    }

    /**
     Tracks a link click and passes the redirected URL to the callback
     
     - parameter applinkURL:      the URL that was clicked
     - parameter callbackBlock:   the callback to send when the link is resolved
     - returns: true if the link was an Iterable tracking link
     - remark:            passes the string of the redirected URL to the callback
     */
    func resolve(applinkURL: URL, callbackBlock: @escaping ItblUrlBlock) {
        deepLinkCampaignId = nil
        deepLinkTemplateId = nil
        deepLinkMessageId = nil
        
        if isDeeplink(applinkURL.absoluteString) {
            let trackAndRedirectTask = redirectUrlSession.dataTask(with: applinkURL) {[unowned self] (data, response, error) in
                if let error = error {
                    ITBError("error: \(error.localizedDescription)")
                    callbackBlock(self.deepLinkLocation)
                    return
                }
                
                if let deepLinkCampaignId = self.deepLinkCampaignId,
                    let deepLinkTemplateId = self.deepLinkTemplateId,
                    let deepLinkMessageId = self.deepLinkMessageId {
                    IterableAPI.instance?.attributionInfo = IterableAttributionInfo(campaignId: deepLinkCampaignId, templateId: deepLinkTemplateId, messageId: deepLinkMessageId)
                }
                callbackBlock(self.deepLinkLocation)
            }
            
            trackAndRedirectTask.resume()
        } else {
            callbackBlock(applinkURL)
        }
    }

    private func isDeeplink(_ urlString: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: ITBL_DEEPLINK_IDENTIFIER, options: []) else {
            return false
        }
        return regex.firstMatch(in: urlString, options: [], range: NSMakeRange(0, urlString.count)) != nil
    }
    
    private lazy var redirectUrlSession: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    } ()
    
    private var deepLinkLocation: URL?
    private var deepLinkCampaignId: NSNumber?
    private var deepLinkTemplateId: NSNumber?
    private var deepLinkMessageId: String?

    // Singleton, only initialized via 'instance'
    private override init() {
        super.init()
    }
}

extension IterableDeeplinkManager : URLSessionDelegate , URLSessionTaskDelegate {
    /**
     Delegate handler when a redirect occurs. Stores a reference to the redirect url and does not execute the redirect.
     - parameters:
        - session: the session
        - task: the task
        - response: the redirectResponse
        - request: the request
        - completionHandler: the completionHandler
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        deepLinkLocation = request.url
        
        guard let headerFields = response.allHeaderFields as? [String : String] else {
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
        } else {
            return NSNumber(value: 0)
        }
    }
}
