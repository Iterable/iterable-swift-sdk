//
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class InAppPresenter {
    static var isPresenting = false
    
    private let maxDelay: TimeInterval
    
    private let topViewController: UIViewController
    private let htmlMessageViewController: IterableHtmlMessageViewController
    private var delayTimer: Timer?
    
    init(topViewController: UIViewController, htmlMessageViewController: IterableHtmlMessageViewController, maxDelay: TimeInterval = 0.75) {
        ITBInfo()
        
        self.topViewController = topViewController
        self.htmlMessageViewController = htmlMessageViewController
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
                self.present()
            }
        }
    }
    
    func webViewDidFinish() {
        ITBInfo()
        
        if delayTimer != nil {
            ITBInfo("canceling timer")
            
            delayTimer?.invalidate()
            delayTimer = nil
            
            present()
        }
    }
    
    private func present() {
        ITBInfo()
        
        InAppPresenter.isPresenting = false
        
        topViewController.present(htmlMessageViewController, animated: false)
        
        htmlMessageViewController.presenter = nil
    }
}
