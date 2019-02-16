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
    static func parse(json: [AnyHashable : Any]) -> InAppContentParseResult {
        guard let contentDict = json[.ITBL_IN_APP_CONTENT] as? [AnyHashable : Any] else {
            return .failure(reason: "no content in json payload")
        }

        let contentType: IterableInAppContentType
        if let contentTypeStr = json[.ITBL_IN_APP_CONTENT_TYPE] as? String {
            contentType = IterableInAppContentType.from(string: contentTypeStr)
        } else {
            contentType = .html
        }

        return map(inAppType: .default, contentType: contentType).tryCreate(from: contentDict)
    }
    
    private static func map(inAppType: IterableInAppType, contentType: IterableInAppContentType) -> ContentFromJsonCreator.Type {
        switch inAppType {
        case .default:
            switch contentType {
            case .html:
                return IterableHtmlInAppContent.self
            default:
                return IterableHtmlInAppContent.self
            }
        case .inBox:
            switch contentType {
            case .html:
                return IterableHtmlInAppContent.self
            default:
                return IterableHtmlInAppContent.self
            }
        }
    }
}

fileprivate protocol ContentFromJsonCreator {
    static func tryCreate(from content: [AnyHashable : Any]) -> InAppContentParseResult
}

extension IterableHtmlInAppContent : ContentFromJsonCreator {
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

