//
//  Created by Tapash Majumder on 2/15/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation

enum InAppContentParseResult {
    case success(content: IterableInAppContent)
    case failure(reason: String)
}

struct InAppContentParser {
    static func parse(contentDict: [AnyHashable : Any]) -> InAppContentParseResult {
        let contentType: IterableInAppContentType
        if let contentTypeStr = contentDict[.ITBL_IN_APP_CONTENT_TYPE] as? String {
            contentType = IterableInAppContentType.from(string: contentTypeStr)
        } else {
            contentType = .html
        }

        return contentCreator(forContentType: contentType).tryCreate(from: contentDict)
    }
    
    private static func contentCreator(forContentType contentType: IterableInAppContentType) -> ContentFromJsonCreator.Type {
        switch contentType {
        case .html:
            return DefaultHtmlInAppContentCreator.self
        default:
            return DefaultHtmlInAppContentCreator.self
        }
    }
}

fileprivate protocol ContentFromJsonCreator {
    static func tryCreate(from content: [AnyHashable : Any]) -> InAppContentParseResult
}

struct DefaultHtmlInAppContentCreator : ContentFromJsonCreator {
    fileprivate static func tryCreate(from content: [AnyHashable : Any]) -> InAppContentParseResult {
        guard let html = content[.ITBL_IN_APP_HTML] as? String else {
            return .failure(reason: "no html")
        }
        guard html.range(of: AnyHashable.ITBL_IN_APP_HREF, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)")
        }
        
        let inAppDisplaySettings = content[.ITBL_IN_APP_DISPLAY_SETTINGS] as? [AnyHashable : Any]
        let backgroundAlpha = InAppHelper.getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
        let edgeInsets = InAppHelper.getPadding(fromInAppSettings: inAppDisplaySettings)
        return .success(content: IterableHtmlInAppContent(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, html: html))
    }
}

