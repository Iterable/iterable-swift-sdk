//
//  Copyright © 2021 Iterable. All rights reserved.
//

#if canImport(SwiftUI) && !arch(arm) && !arch(i386)

import Foundation
import SwiftUI

@available(iOS 13.0, *)
struct InboxViewRepresentable: UIViewControllerRepresentable {
    var noMessagesTitle: String?
    var noMessagwsBody: String?
    var showCountInUnreadBadge = true
    var isPopup = true
    var cellNibName: String?
    var popupModalPresentationStyle: UIModalPresentationStyle?
    var viewDelegate: IterableInboxViewControllerViewDelegate?

    typealias UIViewControllerType = IterableInboxViewController
    
    func makeUIViewController(context: Context) -> IterableInboxViewController {
        let inbox = IterableInboxViewController()
        inbox.noMessagesTitle = noMessagesTitle
        inbox.noMessagesBody = noMessagwsBody
        inbox.showCountInUnreadBadge = showCountInUnreadBadge
        inbox.isPopup = isPopup
        inbox.cellNibName = cellNibName
        inbox.popupModalPresentationStyle = popupModalPresentationStyle
        inbox.viewDelegate = viewDelegate
        return inbox
    }
    
    func updateUIViewController(_ uiViewController: IterableInboxViewController, context: Context) {
    }
}

#endif

