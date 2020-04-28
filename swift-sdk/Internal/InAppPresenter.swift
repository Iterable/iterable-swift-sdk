//
//  Created by Jay Kim on 4/21/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class InAppPresenter {
    static var isPresenting = false
    
    private let delayInterval: TimeInterval = 1.0
    
    private var topVC: UIViewController
    private var htmlMessageVC: IterableHtmlMessageViewController
    private var delayTimer: Timer?
    
    init(topViewController: UIViewController, htmlMessageViewController: IterableHtmlMessageViewController) {
        ITBInfo()
        topVC = topViewController
        htmlMessageVC = htmlMessageViewController
        
        // shouldn't be necessary, but in case there's some kind of race condition
        // that leaves it hanging as true, it should be false at this point
        InAppPresenter.isPresenting = false
        
        htmlMessageVC.presenter = self
    }
    
    deinit {
        ITBInfo()
    }
    
    func show() {
        ITBInfo()
        InAppPresenter.isPresenting = true
        
        if #available(iOS 10.0, *) {
            DispatchQueue.main.async {
                self.delayTimer = Timer.scheduledTimer(withTimeInterval: self.delayInterval, repeats: false) { _ in
                    ITBInfo("delayTimer called")
                    self.delayTimer = nil
                    self.present()
                }
            }
        } else {
            // for lack of a better stop-gap, we might as well just present
            present()
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
        
        topVC.present(htmlMessageVC, animated: false)
        
        htmlMessageVC.presenter = nil
    }
}
