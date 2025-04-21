//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation
import UIKit

/// We can't use `.systemBackground` etc for
/// older verions of iOS so this is a work around for that.
extension UIColor {
    static var iterableSystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        } else {
            return .white
        }
    }

    static var iterableLabel: UIColor {
        if #available(iOS 13, *) {
            return .label
        } else {
            return .black
        }
    }
    
    static var iterableSecondaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        } else {
            return .lightGray
        }
    }
}
