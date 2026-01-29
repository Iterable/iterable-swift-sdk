//
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class InAppPresenter {
    static var isPresenting = false
    /// Window used for full-position IAMs to cover entire screen including status bar
    static var overlayWindow: UIWindow?

    private let maxDelay: TimeInterval
    private let htmlMessageViewController: IterableHtmlMessageViewController
    private let message: IterableInAppMessage
    private var delayTimer: Timer?
    private let isFullPosition: Bool

    init(htmlMessageViewController: IterableHtmlMessageViewController,
         message: IterableInAppMessage,
         maxDelay: TimeInterval = 0.75) {
        ITBInfo()

        self.htmlMessageViewController = htmlMessageViewController
        self.message = message
        self.maxDelay = maxDelay

        // Check if this is a full-position IAM
        if let content = message.content as? IterableHtmlInAppContent {
            let location = HtmlContentParser.InAppDisplaySettingsParser.PaddingParser.location(fromPadding: content.padding)
            self.isFullPosition = (location == .full)
        } else {
            self.isFullPosition = false
        }

        // shouldn't be necessary, but in case there's some kind of race condition
        // that leaves it hanging as true, it should be false at this point
        InAppPresenter.isPresenting = false

        htmlMessageViewController.presenter = self
    }

    deinit {
        ITBInfo()
    }

    func show() {
        ITBInfo()

        InAppPresenter.isPresenting = true

        DispatchQueue.main.async {
            self.delayTimer = Timer.scheduledTimer(withTimeInterval: self.maxDelay, repeats: false) { _ in
                ITBInfo("delayTimer called")

                self.delayTimer = nil
                self.presentAfterDelayValidation()
            }
        }
    }

    func webViewDidFinish() {
        ITBInfo()

        if delayTimer != nil {
            ITBInfo("canceling timer")

            delayTimer?.invalidate()
            delayTimer = nil

            presentAfterDelayValidation()
        }
    }

    private func presentAfterDelayValidation() {
        ITBInfo()

        InAppPresenter.isPresenting = false

        guard let topViewController = InAppDisplayer.getTopViewController() else {
            ITBInfo("No top view controller available after delay")
            return
        }

        if topViewController is IterableHtmlMessageViewController {
            ITBInfo("Another Iterable message is already being displayed")
            return
        }

        if isFullPosition {
            presentUsingWindow()
        } else {
            presentUsingModal(from: topViewController)
        }

        htmlMessageViewController.presenter = nil
    }

    /// Present full-position IAM using a UIWindow to cover entire screen including status bar
    private func presentUsingWindow() {
        ITBInfo()

        let window: UIWindow
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                ITBInfo("No active window scene")
                return
            }
            window = UIWindow(windowScene: windowScene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window.frame = UIScreen.main.bounds
        window.windowLevel = .statusBar + 1
        window.rootViewController = htmlMessageViewController
        window.backgroundColor = .clear
        window.makeKeyAndVisible()

        InAppPresenter.overlayWindow = window
    }

    /// Present non-full-position IAM using standard modal presentation
    private func presentUsingModal(from topViewController: UIViewController) {
        ITBInfo()

        topViewController.definesPresentationContext = true
        topViewController.present(htmlMessageViewController, animated: false)
    }

    /// Dismiss the overlay window (called when full-position IAM is dismissed)
    static func dismissOverlayWindow() {
        ITBInfo()

        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
    }
}
