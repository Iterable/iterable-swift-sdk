//
//  Copyright © 2019 Iterable. All rights reserved.
//

/// Parses content JSON coming from the server based on `contentType` attribute.

import Foundation
import UIKit

typealias PaddingParser = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser
typealias Padding = PaddingParser.Padding

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
    static func getPadding(fromInAppSettings settings: [AnyHashable: Any]?) -> Padding {
        InAppDisplaySettingsParser.PaddingParser.getPadding(fromInAppSettings: settings)
    }
    
    static func parseShouldAnimate(fromInAppSettings inAppSettings: [AnyHashable: Any]) -> Bool {
        InAppDisplaySettingsParser.parseShouldAnimate(fromInAppSettings: inAppSettings)
    }
    
    static func parseBackgroundColor(fromInAppSettings inAppSettings: [AnyHashable: Any]) -> UIColor? {
        InAppDisplaySettingsParser.parseBackgroundColor(fromInAppSettings: inAppSettings)
    }
    
    struct InAppDisplaySettingsParser {
        private enum Key {
            static let shouldAnimate = "shouldAnimate"
            static let bgColor = "bgColor"
            
            enum BGColor {
                static let hex = "hex"
                static let alpha = "alpha"
            }
        }
        
        static func parseShouldAnimate(fromInAppSettings settings: [AnyHashable: Any]) -> Bool {
            settings.getBoolValue(for: Key.shouldAnimate) ?? false
        }
        
        static func parseBackgroundColor(fromInAppSettings settings: [AnyHashable: Any]) -> UIColor? {
            guard let bgColorSettings = settings[Key.bgColor] as? [AnyHashable: Any],
                  let hexString = bgColorSettings[Key.BGColor.hex] as? String else {
                return nil
            }
            
            let hex = hexString.starts(with: "#") ? String(hexString.dropFirst()) : hexString
            
            let alpha = bgColorSettings.getDoubleValue(for: Key.BGColor.alpha) ?? 0.0
            
            return UIColor(hex: hex, alpha: CGFloat(alpha))
        }
        
        struct PaddingParser {
            private enum PaddingEdge: String {
                case top = "top"
                case left = "left"
                case right = "right"
                case bottom = "bottom"
            }
            
            enum PaddingValue: Equatable {
                case percent(value: Int)
                case autoExpand
                
                func toCGFloat() -> CGFloat {
                    switch self {
                    case .percent(value: let value):
                        return CGFloat(value)
                    case .autoExpand:
                        return CGFloat(-1)
                    }
                }
                
                static func from(cgFloat: CGFloat) -> PaddingValue {
                    switch cgFloat {
                    case -1:
                        return .autoExpand
                    default:
                        return .percent(value: Int(cgFloat))
                    }
                }
            }
            
            struct Padding: Equatable {
                static let zero = Padding(top: .percent(value: 0),
                                          left: 0,
                                          bottom: .percent(value: 0),
                                          right: 0)
                let top: PaddingValue
                let left: Int
                let bottom: PaddingValue
                let right: Int
                
                func adjusted() -> Padding {
                    if left + right >= 100 {
                        return Padding(top: top,
                                       left: 0,
                                       bottom: bottom,
                                       right: 0)
                    } else {
                        return self
                    }
                }
                
                func toEdgeInsets() -> UIEdgeInsets {
                    UIEdgeInsets(top: top.toCGFloat(),
                                 left: CGFloat(left),
                                 bottom: bottom.toCGFloat(),
                                 right: CGFloat(right))
                }
                
                static func from(edgeInsets: UIEdgeInsets) -> Padding {
                    Padding(top: PaddingValue.from(cgFloat: edgeInsets.top),
                            left: Int(edgeInsets.left),
                            bottom: PaddingValue.from(cgFloat: edgeInsets.bottom),
                            right: Int(edgeInsets.right))
                }
            }
            
            private enum PaddingKey {
                static let displayOption = "displayOption"
                static let percentage = "percentage"
            }

            static let displayOptionAutoExpand = "AutoExpand"

            /// `settings` json looks like the following
            /// {"bottom": {"displayOption": "AutoExpand"}, "left": {"percentage": 60}, "right": {"percentage": 60}, "top": {"displayOption": "AutoExpand"}}
            static func getPadding(fromInAppSettings settings: [AnyHashable: Any]?) -> Padding {
                Padding(top: getEdgePaddingValue(fromInAppSettings: settings, edge: .top),
                        left: getEdgePadding(fromInAppSettings: settings, edge: .left),
                        bottom: getEdgePaddingValue(fromInAppSettings: settings, edge: .bottom),
                        right: getEdgePadding(fromInAppSettings: settings, edge: .right))
            }
            
            /// json comes in as
            /// `{"displayOption": "AutoExpand"}`
            /// or `{"percentage": 60}`
            static func decodePaddingValue(_ value: Any?) -> PaddingValue {
                guard let dict = value as? [AnyHashable: Any] else {
                    return .percent(value: 0)
                }
                
                if let displayOption = dict[PaddingKey.displayOption] as? String, displayOption == Self.displayOptionAutoExpand {
                    return .autoExpand
                } else {
                    if let percentage = dict[PaddingKey.percentage] as? NSNumber {
                        return .percent(value: Int(truncating: percentage))
                    }
                    
                    return .percent(value: 0)
                }
            }

            /// json comes in as
            /// `{"percentage": 60}`
            static func decodePadding(_ value: Any?) -> Int {
                guard let dict = value as? [AnyHashable: Any] else {
                    return 0
                }
                
                if let percentage = dict[PaddingKey.percentage] as? NSNumber {
                    return Int(truncating: percentage)
                }
                
                return 0
            }

            static func location(fromPadding padding: Padding) -> IterableMessageLocation {
                if case .percent(let topPadding) = padding.top,
                   case .percent(let bottomPadding) = padding.bottom,
                   topPadding == 0,
                   bottomPadding == 0 {
                    return .full
                } else if case .autoExpand = padding.bottom,
                          case .percent(let topPadding) = padding.top,
                          topPadding == 0 {
                    return .top
                } else if case .autoExpand = padding.top,
                          case .percent(let bottomPadding) = padding.bottom,
                          bottomPadding == 0 {
                    return .bottom
                } else {
                    return .center
                }
            }

            private static func getEdgePaddingValue(fromInAppSettings settings: [AnyHashable: Any]?,
                                               edge: PaddingEdge) -> PaddingValue {
                settings?[edge.rawValue]
                    .map(decodePaddingValue(_:)) ?? .percent(value: 0)
            }

            private static func getEdgePadding(fromInAppSettings settings: [AnyHashable: Any]?,
                                               edge: PaddingEdge) -> Int {
                settings?[edge.rawValue]
                    .map(decodePadding(_:)) ?? 0
            }
        }
    }
}

extension HtmlContentParser: ContentFromJsonParser {
    fileprivate static func tryCreate(from json: [AnyHashable: Any]) -> InAppContentParseResult {
        guard let html = json[JsonKey.html] as? String else {
            return .failure(reason: "no html")
        }
        
        guard html.range(of: Const.href, options: [.caseInsensitive]) != nil else {
            return .failure(reason: "No href tag found in in-app html payload \(html)")
        }
        
        let inAppDisplaySettings = json[JsonKey.InApp.inAppDisplaySettings] as? [AnyHashable: Any]
        let padding = getPadding(fromInAppSettings: inAppDisplaySettings)
        
        let shouldAnimate = inAppDisplaySettings.map(Self.parseShouldAnimate(fromInAppSettings:)) ?? false
        let backgroundColor = inAppDisplaySettings.flatMap(Self.parseBackgroundColor(fromInAppSettings:))
        
        return .success(content: IterableHtmlInAppContent(edgeInsets: padding.toEdgeInsets(),
                                                          html: html,
                                                          shouldAnimate: shouldAnimate,
                                                          backgroundColor: backgroundColor))
    }
}
