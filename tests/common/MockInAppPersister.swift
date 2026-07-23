//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockInAppPersister: InAppPersistenceProtocol {
    var onPersist: (() -> Void)?

    private var messages = [IterableInAppMessage]()
    
    func getMessages() -> [IterableInAppMessage] {
        messages
    }
    
    func persist(_ messages: [IterableInAppMessage]) {
        self.messages = messages
        let callback = onPersist
        callback?()
    }
    
    func clear() {
        messages.removeAll()
    }
}
