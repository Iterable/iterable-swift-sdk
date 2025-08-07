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
        
        topViewController.definesPresentationContext = true
        
        topViewController.present(htmlMessageViewController, animated: false)
        
        htmlMessageViewController.presenter = nil
    }
}
