//
//  Created by Tapash Majumder on 2/15/19.
//  Copyright © 2019 Iterable. All rights reserved.
//
// Parses content JSON coming from the server based on 'contentType' attribute.
//

import Foundation

enum InAppContentParseResult {
    case success(content: IterableContent)
    case failure(reason: String)
}

struct InAppContentParser {
    static func parse(contentDict: [AnyHashable : Any]) -> InAppContentParseResult {
        let contentType: IterableContentType
        if let contentTypeStr = contentDict[.ITBL_IN_APP_CONTENT_TYPE] as? String {
            contentType = IterableContentType.from(string: contentTypeStr)
        } else {
            contentType = .html
        }

        return contentCreator(forContentType: contentType).tryCreate(from: contentDict)
    }
    
    private static func contentCreator(forContentType contentType: IterableContentType) -> ContentFromJsonCreator.Type {
        switch contentType {
        case .html:
            return InAppHtmlContentCreator.self
        case .inboxHtml:
            return InboxHtmlContentCreator.self
        default:
            return InAppHtmlContentCreator.self
        }
    }
}

fileprivate protocol ContentFromJsonCreator {
    static func tryCreate(from json: [AnyHashable : Any]) -> InAppContentParseResult
}

struct HtmlContentCreator {
    enum Result {
        case success(content: HtmlContent)
        case failure(reason: String)
    }
    
    struct HtmlContent {
        let edgeInsets: UIEdgeInsets
        let backgroundAlpha: Double
        let html: String
    }
    
    fileprivate static func tryCreate(from json: [AnyHashable : Any]) -> Result {
        guard let html = json[.ITBL_IN_APP_HTML] as? String else {
            return .failure(reason: "no html")
        }
        guard html.range(of: AnyHashable.ITBL_IN_APP_HREF, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)")
        }
        
        let inAppDisplaySettings = json[.ITBL_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
        let backgroundAlpha = InAppHelper.getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
        let edgeInsets = InAppHelper.getPadding(fromInAppSettings: inAppDisplaySettings)
        return .success(content: HtmlContent(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, html: html))
    }
}

struct InAppHtmlContentCreator : ContentFromJsonCreator {
    fileprivate static func tryCreate(from json: [AnyHashable : Any]) -> InAppContentParseResult {
        switch HtmlContentCreator.tryCreate(from: json) {
        case .failure(let reason):
            return .failure(reason: reason)
        case .success(let content):
            return .success(content: IterableInAppHtmlContent(edgeInsets: content.edgeInsets, backgroundAlpha: content.backgroundAlpha, html: content.html))
        }
    }
}

struct InboxHtmlContentCreator : ContentFromJsonCreator {
    fileprivate static func tryCreate(from json: [AnyHashable : Any]) -> InAppContentParseResult {
        switch HtmlContentCreator.tryCreate(from: json) {
        case .failure(let reason):
            return .failure(reason: reason)
        case .success(let content):
            return .success(content: IterableInboxHtmlContent(edgeInsets: content.edgeInsets, backgroundAlpha: content.backgroundAlpha, html: content.html, title: nil, subTitle: nil, icon: nil))//!!!
        }
    }
}

