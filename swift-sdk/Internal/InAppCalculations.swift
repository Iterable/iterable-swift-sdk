//
//  Created by Tapash Majumder on 10/14/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import UIKit

struct InAppCalculations {
    static func calculateAnimationStartPosition(location: IterableMessageLocation,
                                       position: ViewPosition,
                                       safeAreaInsets: UIEdgeInsets) -> ViewPosition {
        let startPosition: ViewPosition
        switch location {
        case .top:
            startPosition = ViewPosition(width: position.width,
                                         height: position.height,
                                         center: CGPoint(x: position.center.x,
                                                         y:  position.center.y - position.height - safeAreaInsets.top))
        case .bottom:
            startPosition = ViewPosition(width: position.width,
                                         height: position.height,
                                         center: CGPoint(x: position.center.x,
                                                         y:  position.center.y + position.height + safeAreaInsets.bottom))
        case .center:
            startPosition = position
        case .full:
            startPosition = position
        }
        
        return startPosition
    }

    static func calculateAnimationStartAlpha(location: IterableMessageLocation) -> CGFloat {
        let startAlpha: CGFloat
        switch location {
        case .top:
            startAlpha = 1.0
        case .bottom:
            startAlpha = 1.0
        case .center:
            startAlpha = 0.0
        case .full:
            startAlpha = 0.0
        }
        
        return startAlpha
    }

    static func safeAreaInsets(for view: UIView) -> UIEdgeInsets {
        if #available(iOS 11, *) {
            return view.safeAreaInsets
        } else {
            return .zero
        }
    }
    
    static func adjustedPadding(from padding: UIEdgeInsets) -> UIEdgeInsets {
        var insetPadding = padding
        if insetPadding.left + insetPadding.right >= 100 {
            ITBError("Can't display an in-app with padding > 100%. Defaulting to 0 for padding left/right")
            insetPadding.left = 0
            insetPadding.right = 0
        }
        
        return insetPadding
    }
    
    static func calculateWebViewPosition(safeAreaInsets: UIEdgeInsets,
                                         parentPosition: ViewPosition,
                                         paddingLeft: CGFloat,
                                         paddingRight: CGFloat,
                                         location: IterableMessageLocation,
                                         inAppHeight: CGFloat) -> ViewPosition {
        var position = ViewPosition()
        // set the height
        position.height = inAppHeight
        
        // now set the width
        let notificationWidth = 100 - (paddingLeft + paddingRight)
        position.width = parentPosition.width * notificationWidth / 100
        
        // Position webview
        position.center = parentPosition.center
        
        // set center x
        position.center.x = parentPosition.width * (paddingLeft + notificationWidth / 2) / 100
        
        // set center y
        switch location {
        case .top:
            position.height = position.height + safeAreaInsets.top
            let halfWebViewHeight = position.height / 2
            position.center.y = halfWebViewHeight
        case .bottom:
            let halfWebViewHeight = position.height / 2
            position.center.y = parentPosition.height - halfWebViewHeight - safeAreaInsets.bottom
        default: break
        }
        
        return position
    }
}
