//
//  Copyright © 2018 Iterable. All rights reserved.
//

/// This file contains in-app and inbox messaging classes.

import Foundation
import UIKit

/// `show` to show the in-app otherwise `skip` to skip.
@objc public enum InAppShowResponse: Int {
    case show
    case skip
}

/// Iterable Notification names
public extension Notification.Name {
    /// This is fired when in app inbox changes.
    static let iterableInboxChanged = Notification.Name(rawValue: "itbl_inbox_changed")
}

@objcMembers open class DefaultInAppDelegate: IterableInAppDelegate {
    public init() {}
    
    /// By default, every single in-app will be shown as soon as it is available.
    /// If more than 1 in-app is available, we show the first showable one.
    open func onNew(message _: IterableInAppMessage) -> InAppShowResponse {
        ITBInfo()
        return .show
    }
}

@objc public enum IterableInAppContentType: Int, Codable {
    case html
    case alert
    case banner
}

@objc public protocol IterableInAppContent {
    var type: IterableInAppContentType { get }
}

@objcMembers public final class IterableHtmlInAppContent: NSObject, IterableInAppContent {
    public let type = IterableInAppContentType.html
    
    public let edgeInsets: UIEdgeInsets
    public let html: String
    public let shouldAnimate: Bool
    public let backgroundColor: UIColor?

    // MARK: - Private/Internal
    
    init(edgeInsets: UIEdgeInsets,
         html: String,
         shouldAnimate: Bool = false,
         backgroundColor: UIColor? = nil) {
        self.edgeInsets = edgeInsets
        self.html = html
        self.shouldAnimate = shouldAnimate
        self.backgroundColor = backgroundColor
    }
}

extension IterableHtmlInAppContent {
    var padding: Padding {
        Padding.from(edgeInsets: edgeInsets)
    }
}

@objcMembers public final class IterableInboxMetadata: NSObject {
    public let title: String?
    public let subtitle: String?
    public let icon: String?
    
    // MARK: - Private/Internal
    
    init(title: String? = nil,
         subtitle: String? = nil,
         icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

/// `immediate` will try to display the in-app automatically immediately
/// `event` is used for Push to in-app
/// `never` will not display the in-app automatically via the SDK
@objc public enum IterableInAppTriggerType: Int, Codable {
    case immediate
    case event
    case never
}

@objcMembers public final class IterableInAppTrigger: NSObject {
    public let type: IterableInAppTriggerType
    
    // MARK: - Private/Internal
    
    let dict: [AnyHashable: Any]
    
    init(dict: [AnyHashable: Any]) {
        self.dict = dict
        
        if let typeString = dict[JsonKey.InApp.type] as? String {
            type = IterableInAppTriggerType.from(string: typeString)
        } else {
            type = IterableInAppTriggerType.immediate
        }
    }
}
