//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockInAppDisplayer: InAppDisplayerProtocol {
    // when a message is shown this is called back
    var onShow: Fulfill<IterableInAppMessage, IterableError> = Fulfill<IterableInAppMessage, IterableError>()
    
    func isShowingInApp() -> Bool {
        showing
    }
    
    // This is not resolved until a url is clicked.
    func showInApp(message: IterableInAppMessage, onClickCallback: ((URL) -> Void)?) -> ShowResult {
        guard showing == false else {
            onShow.reject(with: IterableError.general(description: "showing something else"))
            return .notShown("showing something else")
        }
        
        showing = true
        self.onClickCallback = onClickCallback
        
        onShow.resolve(with: message)
        
        return .shown
    }
    
    // Mimics clicking a url
    func click(url: URL) {
        ITBInfo()
        showing = false
        DispatchQueue.main.async { [weak self] in
            self?.onClickCallback?(url)
        }
    }
    
    private var onClickCallback: ((URL) -> Void)?
    private var showing = false
}
