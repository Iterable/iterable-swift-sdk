//
//  Created by Tapash Majumder on 2/15/19.
//  Copyright © 2019 Iterable. All rights reserved.
//
// Parses content JSON coming from the server based on 'contentType' attribute.
//

import Foundation
import UIKit

enum InAppContentParseResult {
    case success(content: IterableInAppContent)
    case failure(reason: String)
}

struct InAppContentParser {
    static func parse(contentDict: [AnyHashable: Any]) -> InAppContentParseResult {
        let contentType: IterableInAppContentType
        
        if let contentTypeStr = contentDict[JsonKey.InApp.type] as? String {
            contentType = IterableInAppContentType.from(string: contentTypeStr)
        } else {
            contentType = .html
        }
        
        return contentParser(forContentType: contentType).tryCreate(from: contentDict)
    }
    
    private static func contentParser(forContentType contentType: IterableInAppContentType) -> ContentFromJsonParser.Type {
        switch contentType {
        case .html:
            return HtmlContentParser.self
        default:
            return HtmlContentParser.self
        }
    }
}

private protocol ContentFromJsonParser {
    static func tryCreate(from json: [AnyHashable: Any]) -> InAppContentParseResult
}

struct HtmlContentParser {
    /**
     Parses the padding offsets from the payload
     
     - parameter settings:         the settings distionary.
     
     - returns: the UIEdgeInset
     */
    static func getPadding(fromInAppSettings settings: [AnyHashable: Any]?) -> UIEdgeInsets {
        guard let dict = settings else {
            return UIEdgeInsets.zero
        }
        
        var padding = UIEdgeInsets.zero
        
        if let topPadding = dict[PADDING_TOP] {
            padding.top = CGFloat(decodePadding(topPadding))
        }
        
        if let leftPadding = dict[PADDING_LEFT] {
            padding.left = CGFloat(decodePadding(leftPadding))
        }
        
        if let rightPadding = dict[PADDING_RIGHT] {
            padding.right = CGFloat(decodePadding(rightPadding))
        }
        
        if let bottomPadding = dict[PADDING_BOTTOM] {
            padding.bottom = CGFloat(decodePadding(bottomPadding))
        }
        
        return padding
    }
    
    /**
     Gets the location from a inset data
     
     - returns: the location as an INAPP_NOTIFICATION_TYPE
     */
    static func location(fromPadding padding: UIEdgeInsets) -> IterableMessageLocation {
        if padding.top == 0, padding.bottom == 0 {
            return .full
        } else if padding.top == 0, padding.bottom < 0 {
            return .top
        } else if padding.top < 0, padding.bottom == 0 {
            return .bottom
        } else {
            return .center
        }
    }
    
    /**
     Gets the int value of the padding from the payload
     
     @param value          the value
     
     @return the padding integer
     
     @discussion Passes back -1 for Auto expanded padding
     */
    static func decodePadding(_ value: Any?) -> Int {
        guard let dict = value as? [AnyHashable: Any] else {
            return 0
        }
        
        if let displayOption = dict[IN_APP_DISPLAY_OPTION] as? String, displayOption == IN_APP_AUTO_EXPAND {
            return -1
        } else {
            if let percentage = dict[IN_APP_PERCENTAGE] as? NSNumber {
                return percentage.intValue
            }
            
            return 0
        }
    }
    
    static func getBackgroundAlpha(fromInAppSettings settings: [AnyHashable: Any]?) -> Double {
        guard let settings = settings else {
            return 0
        }
        
        if let number = settings[JsonKey.InApp.backgroundAlpha] as? NSNumber {
            return number.doubleValue
        } else {
            return 0
        }
    }
    
    private static let PADDING_TOP = "top"
    private static let PADDING_LEFT = "left"
    private static let PADDING_BOTTOM = "bottom"
    private static let PADDING_RIGHT = "right"
    
    private static let IN_APP_DISPLAY_OPTION = "displayOption"
    private static let IN_APP_AUTO_EXPAND = "AutoExpand"
    private static let IN_APP_PERCENTAGE = "percentage"
}

extension HtmlContentParser: ContentFromJsonParser {
    fileprivate static func tryCreate(from json: [AnyHashable: Any]) -> InAppContentParseResult {
        guard let html = json[JsonKey.html.jsonKey] as? String else {
            return .failure(reason: "no html")
        }
        
        guard html.range(of: Const.href, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)")
        }
        
        let inAppDisplaySettings = json[JsonKey.InApp.inAppDisplaySettings] as? [AnyHashable: Any]
        let backgroundAlpha = getBackgroundAlpha(fromInAppSettings: inAppDisplaySettings)
        let edgeInsets = getPadding(fromInAppSettings: inAppDisplaySettings)
        
        return .success(content: IterableHtmlInAppContent(edgeInsets: edgeInsets, backgroundAlpha: backgroundAlpha, html: html))
    }
}
