//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

enum ShowResult {
    case shown
    case notShown(String)
}

protocol InAppDisplayerProtocol {
    func isShowingInApp() -> Bool
    /// Shows an IterableMessage.
    /// - parameter message: The Iterable message to show
    /// - parameter onclickCallback: Callback when a link is clicked in the in-app
    /// - returns: `.shown`  or
    /// `.notShown` with reason if the message could not be shown.
    func showInApp(message: IterableInAppMessage, onClickCallback: ((URL) -> Void)?) -> ShowResult
}

class InAppDisplayer: InAppDisplayerProtocol {
    func isShowingInApp() -> Bool {
        InAppDisplayer.isShowingIterableMessage()
    }
    
    func showInApp(message: IterableInAppMessage, onClickCallback: ((URL) -> Void)?) -> ShowResult {
        InAppDisplayer.show(iterableMessage: message, onClickCallback: onClickCallback)
    }
    
    /// Creates and shows a HTML In-app Notification with trackParameters, backgroundColor with callback handler
    /// - parameter htmlString:      The string containing the dialog HTML
    /// - parameter messageMetadata: Message metadata object.
    /// - parameter padding:         The padding around the notification
    /// - parameter onclickCallback: Callback when a link is clicked in the in-app
    /// - returns:  Whether the message was shown or not shown
    @discardableResult
    static func showIterableHtmlMessage(_ htmlString: String,
                                        messageMetadata: IterableInAppMessageMetadata? = nil,
                                        padding: Padding = .zero,
                                        onClickCallback: ((URL) -> Void)?) -> ShowResult {
        guard !InAppPresenter.isPresenting else {
            return .notShown("In-app notification is being presented.")
        }
        
        guard let topViewController = getTopViewController() else {
            return .notShown("No top view controller.")
        }
        
        if topViewController is IterableHtmlMessageViewController {
            return .notShown("Skipping the in-app notification. Another notification is already being displayed.")
        }
        
        let parameters = IterableHtmlMessageViewController.Parameters(html: htmlString,
                                                                      padding: padding,
                                                                      messageMetadata: messageMetadata,
                                                                      isModal: true)
        let htmlMessageVC = IterableHtmlMessageViewController.create(parameters: parameters, onClickCallback: onClickCallback)
        
        topViewController.definesPresentationContext = true
        
        htmlMessageVC.modalPresentationStyle = .overFullScreen
        
        let presenter = InAppPresenter(topViewController: topViewController, htmlMessageViewController: htmlMessageVC)
        presenter.show()
        
        return .shown
    }
    
    fileprivate static func isShowingIterableMessage() -> Bool {
        guard Thread.isMainThread else {
            ITBError("Must be called from main thread")
            return false
        }
        
        guard let topViewController = getTopViewController() else {
            return false
        }
        
        return topViewController is IterableHtmlMessageViewController
    }
    
    private static func getTopViewController() -> UIViewController? {
        guard let rootViewController = IterableUtil.rootViewController else {
            return nil
        }
        
        var topViewController = rootViewController
        
        while topViewController.presentedViewController != nil {
            topViewController = topViewController.presentedViewController!
        }
        
        return topViewController
    }
    
    @discardableResult
    fileprivate static func show(iterableMessage: IterableInAppMessage, onClickCallback: ((URL) -> Void)?) -> ShowResult {
        guard let content = iterableMessage.content as? IterableHtmlInAppContent else {
            return .notShown("Invalid content type")
        }
        
        let metadata = IterableInAppMessageMetadata(message: iterableMessage, location: .inApp)
        
        return showIterableHtmlMessage(content.html,
                                       messageMetadata: metadata,
                                       padding: content.padding,
                                       onClickCallback: onClickCallback)
    }
}
