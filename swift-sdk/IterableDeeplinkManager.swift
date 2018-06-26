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
    func resolve(applinkURL: URL, callbackBlock: @escaping ITBURLCallback) {
        deeplinkCampaignId = nil
        deeplinkTemplateId = nil
        deeplinkMessageId = nil
        
        if isDeeplink(applinkURL.absoluteString) {
            let trackAndRedirectTask = redirectUrlSession.dataTask(with: applinkURL) {[unowned self] (data, response, error) in
                if let error = error {
                    ITBError("error: \(error.localizedDescription)")
                    callbackBlock(self.deeplinkLocation)
                    return
                }
                
                if let deeplinkCampaignId = self.deeplinkCampaignId,
                    let deeplinkTemplateId = self.deeplinkTemplateId,
                    let deeplinkMessageId = self.deeplinkMessageId {
                    IterableAPI.instance?.attributionInfo = IterableAttributionInfo(campaignId: deeplinkCampaignId, templateId: deeplinkTemplateId, messageId: deeplinkMessageId)
                }
                callbackBlock(self.deeplinkLocation)
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
    
    private var deeplinkLocation: URL?
    private var deeplinkCampaignId: NSNumber?
    private var deeplinkTemplateId: NSNumber?
    private var deeplinkMessageId: String?

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
        deeplinkLocation = request.url
        
        guard let headerFields = response.allHeaderFields as? [String : String] else {
            return
        }
        guard let url = response.url else {
            return
        }

        for cookie in HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url) {
            if cookie.name == "iterableEmailCampaignId" {
                deeplinkCampaignId = number(fromString: cookie.value)
            } else if cookie.name == "iterableTemplateId" {
                deeplinkTemplateId = number(fromString: cookie.value)
            } else if cookie.name == "iterableMessageId" {
                deeplinkMessageId = cookie.value
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
