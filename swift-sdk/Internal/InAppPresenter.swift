//
//  Created by Jay Kim on 4/21/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

class InAppPresenter {
    var topVC: UIViewController
    var htmlMessageVC: IterableHtmlMessageViewController
    var delayTimer: Timer
    
    init(topViewController: UIViewController, htmlMessageViewController: IterableHtmlMessageViewController, timer: Timer) {
        topVC = topViewController
        htmlMessageVC = htmlMessageViewController
        delayTimer = timer
    }
    
    func show() {
        delayTimer.fire()
        
        htmlMessageVC.loadView()
    }
    
    func cancelTimer() {
        delayTimer.invalidate()
        
        topVC.present(htmlMessageVC, animated: false)
    }
}
