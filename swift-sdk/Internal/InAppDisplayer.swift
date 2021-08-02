//
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

enum ShowResult {
    case shown(Future<URL, IterableError>)
    case notShown(String)
}

protocol InAppDisplayerProtocol {
    func isShowingInApp() -> Bool
    /// Shows an IterableMessage.
    /// - parameter message: The Iterable message to show
    /// - returns: A Future representing the url clicked by the user or
    /// `.notShown` with reason if the message could not be shown.
    func showInApp(message: IterableInAppMessage) -> ShowResult
}

@available(iOSApplicationExtension, unavailable)
class InAppDisplayer: InAppDisplayerProtocol {
    func isShowingInApp() -> Bool {
        InAppDisplayer.isShowingIterableMessage()
    }
    
    func showInApp(message: IterableInAppMessage) -> ShowResult {
        InAppDisplayer.show(iterableMessage: message)
    }
    
    /**
     Creates and shows a HTML In-app Notification with trackParameters, backgroundColor with callback handler
     
     - parameters:
     - htmlString:      The string containing the dialog HTML
     - messageMetadata: Message metadata object.
     - backgroundAlpha: The background alpha behind the notification
     - padding:         The padding around the notification
     - returns:
     A future representing the URL clicked by the user
     */
    @discardableResult static func showIterableHtmlMessage(_ htmlString: String,
                                                           messageMetadata: IterableInAppMessageMetadata? = nil,
                                                           padding: Padding = .zero) -> ShowResult {
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
        let createResult = IterableHtmlMessageViewController.create(parameters: parameters)
        let htmlMessageVC = createResult.viewController
        
        topViewController.definesPresentationContext = true
        
        htmlMessageVC.modalPresentationStyle = .overFullScreen
        
        let presenter = InAppPresenter(topViewController: topViewController, htmlMessageViewController: htmlMessageVC)
        presenter.show()
        
        return .shown(createResult.futureClickedURL)
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
    
    @discardableResult fileprivate static func show(iterableMessage: IterableInAppMessage) -> ShowResult {
        guard let content = iterableMessage.content as? IterableHtmlInAppContent else {
            return .notShown("Invalid content type")
        }
        
        let metadata = IterableInAppMessageMetadata(message: iterableMessage, location: .inApp)
        
        return showIterableHtmlMessage(content.html,
                                       messageMetadata: metadata,
                                       padding: content.padding)
    }
}
