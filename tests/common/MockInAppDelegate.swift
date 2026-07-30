//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockInAppDelegate: IterableInAppDelegate {
    var onNewMessageCallback: ((IterableInAppMessage) -> Void)?
    var onJsonOnlyMessageAvailableCallback: ((IterableInAppMessage) -> Void)?
    
    init(showInApp: InAppShowResponse = .show) {
        self.showInApp = showInApp
    }
    
    func onNew(message: IterableInAppMessage) -> InAppShowResponse {
        onNewMessageCallback?(message)
        return showInApp
    }

    func onJsonOnlyMessageAvailable(message: IterableInAppMessage) {
        onJsonOnlyMessageAvailableCallback?(message)
    }
    
    private let showInApp: InAppShowResponse
}
