//
//  Copyright © 2021 Iterable. All rights reserved.
//

#if canImport(SwiftUI) && !arch(arm) && !arch(i386)

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public struct IterableInboxView: View {
    public init() {
    }
    
    /// We default, we don't show any message when inbox is empty.
    /// If you want to show a message, such as, "There are no messages", you will
    /// have to set the `noMessagesTitle` and  `noMessagesBody` properties below.

    /// Use this to set the title to show when there are no message in the inbox.
    public func noMessagesTitle(_ value: String) -> IterableInboxView {
        var view = self
        view.noMessagesTitle = value
        return view
    }
    
    /// Use this to set the message to show when there are no message in the inbox.
    public func noMessagesBody(_ value: String) -> IterableInboxView {
        var view = self
        view.noMessagesBody = value
        return view
    }
    
    /// If `true`, the inbox badge will show a number when there are any unread messages in the inbox.
    /// If `false` it will simply show an indicator if there are any unread messages in the inbox.
    public func showCountInUnreadBadge(_ value: Bool) -> IterableInboxView {
        var view = self
        view.showCountInUnreadBadge = value
        return view
    }
    
    /// Set this to `true` to show a popup when an inbox message is selected in the list.
    /// Set this to `false`to push inbox message into navigation stack.
    public func isPopup(_ value: Bool) -> IterableInboxView {
        var view = self
        view.isPopup = value
        return view
    }
    
    /// If you want to use a custom layout for your inbox TableViewCell
    /// you should set this. Please note that this assumes
    /// that the nib is present in the main bundle.
    public func cellNibName(_ value: String) -> IterableInboxView {
        var view = self
        view.cellNibName = value
        return view
    }
    
    /// when in popup mode, specify here if you'd like to change the presentation style
    public func popupModalPresentationStyle(_ value: UIModalPresentationStyle) -> IterableInboxView {
        var view = self
        view.popupModalPresentationStyle = value
        return view
    }
    
    /// Set this property to override default inbox display behavior.
    /// Please see `IterableInboxViewControllerViewDelegate` for more details
    public func viewDelegate(_ value: IterableInboxViewControllerViewDelegate) -> IterableInboxView {
        var view = self
        view.viewDelegate = value
        return view
    }
    
    public var body: some View {
        var view = InboxViewRepresentable()
        view.noMessagesTitle = noMessagesTitle
        view.noMessagwsBody = noMessagesBody
        view.showCountInUnreadBadge = showCountInUnreadBadge
        view.isPopup = isPopup
        view.cellNibName = cellNibName
        view.popupModalPresentationStyle = popupModalPresentationStyle
        view.viewDelegate = viewDelegate
        return view
    }
    
    private var noMessagesTitle: String?
    private var noMessagesBody: String?
    private var showCountInUnreadBadge = true
    private var isPopup = true
    private var cellNibName: String?
    private var popupModalPresentationStyle: UIModalPresentationStyle?
    private var viewDelegate: IterableInboxViewControllerViewDelegate?
}

#endif
