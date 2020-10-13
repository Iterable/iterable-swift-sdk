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
    static func getPadding(fromInAppSettings settings: [AnyHashable: Any]?) -> UIEdgeInsets {
        PaddingParser.getPadding(fromInAppSettings: settings)
    }
    
    static func location(fromPadding padding: UIEdgeInsets) -> IterableMessageLocation {
        PaddingParser.location(fromPadding: padding)
    }

    static func decodePadding(_ value: Any?) -> Int {
        PaddingParser.decodePadding(value)
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

    struct PaddingParser {
        enum PaddingEdge: String, JsonKeyRepresentable {
            var jsonKey: String {
                rawValue
            }

            case top
            case left
            case right
            case bottom
        }
        
        enum PaddingKey: String, JsonKeyRepresentable {
            var jsonKey: String {
                rawValue
            }
            
            case displayOption
            case percentage
        }

        static let displayOptionAutoExpand = "AutoExpand"

        /// `settings` json looks like the following
        /// {"bottom": {"displayOption": "AutoExpand"}, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}
        static func getPadding(fromInAppSettings settings: [AnyHashable: Any]?) -> UIEdgeInsets {
            UIEdgeInsets(top: getEdgePadding(fromInAppSettings: settings, edge: .top),
                         left: getEdgePadding(fromInAppSettings: settings, edge: .left),
                         bottom: getEdgePadding(fromInAppSettings: settings, edge: .bottom),
                         right: getEdgePadding(fromInAppSettings: settings, edge: .right))
        }
        
        /// json comes in as
        /// `{"displayOption": "AutoExpand"}`
        /// or `{"percentage": 60}`
        /// returns `-1` for `AutoExpand` type
        static func decodePadding(_ value: Any?) -> Int {
            guard let dict = value as? [AnyHashable: Any] else {
                return 0
            }
            
            if let displayOption = dict.getValue(for: PaddingKey.displayOption) as? String, displayOption == Self.displayOptionAutoExpand {
                return -1
            } else {
                if let percentage = dict.getValue(for: PaddingKey.percentage) as? NSNumber {
                    return percentage.intValue
                }
                
                return 0
            }
        }
        
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
        
        private static func getEdgePadding(fromInAppSettings settings: [AnyHashable: Any]?,
                                           edge: PaddingEdge) -> CGFloat {
            settings?.getValue(for: edge)
                .map(decodePadding(_:))
                .map { CGFloat($0) } ?? .zero
        }
    }

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
