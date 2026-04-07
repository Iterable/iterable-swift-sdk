//
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class InAppPresenter {
    static var isPresenting = false

    private let maxDelay: TimeInterval
    private let htmlMessageViewController: IterableHtmlMessageViewController
    private let message: IterableInAppMessage
    private var delayTimer: Timer?
    /// The top view controller captured at show() time, before any async delay.
    /// This prevents issues where the view hierarchy changes during the delay,
    /// causing the in-app message to be presented on the wrong view controller.
    private weak var capturedTopViewController: UIViewController?

    init(htmlMessageViewController: IterableHtmlMessageViewController,
         message: IterableInAppMessage,
         maxDelay: TimeInterval = 0.75) {
        ITBInfo()

        self.htmlMessageViewController = htmlMessageViewController
        self.message = message
        self.maxDelay = maxDelay

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

        // Capture the top view controller now, before the async delay.
        // This ensures we present on the correct VC even if the hierarchy changes.
        capturedTopViewController = InAppDisplayer.getTopViewController()

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

        // Prefer the view controller captured at show() time.
        // Fall back to the current top VC if the captured one was deallocated.
        guard let topViewController = capturedTopViewController ?? InAppDisplayer.getTopViewController() else {
            ITBInfo("No top view controller available after delay")
            return
        }

        if topViewController is IterableHtmlMessageViewController {
            ITBInfo("Another Iterable message is already being displayed")
            return
        }

        topViewController.definesPresentationContext = true

        topViewController.present(htmlMessageViewController, animated: false)

        htmlMessageViewController.presenter = nil
    }
}
