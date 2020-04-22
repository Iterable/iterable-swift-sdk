//
//  Created by Jay Kim on 4/21/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class InAppPresenter {
    var topVC: UIViewController
    var htmlMessageVC: IterableHtmlMessageViewController
    var delayTimer: Timer?
    
    init(topViewController: UIViewController, htmlMessageViewController: IterableHtmlMessageViewController) {
        topVC = topViewController
        htmlMessageVC = htmlMessageViewController
        
        htmlMessageVC.presenter = self
    }
    
    func show() {
        if #available(iOS 10.0, *) {
            delayTimer = Timer(timeInterval: 0.15, repeats: false) { _ in
                self.delayTimer = nil
                
                self.present()
            }
            
            delayTimer?.fire()
            
            htmlMessageVC.loadView()
        } else {
            present()
        }
    }
    
    func cancelTimer() {
        if delayTimer != nil {
            delayTimer?.invalidate()
            delayTimer = nil
            
            present()
        }
    }
    
    private func present() {
        topVC.present(htmlMessageVC, animated: false)
    }
}
