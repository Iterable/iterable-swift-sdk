//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

public protocol IterableEmbeddedManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage]
    func getMessages(for placementId: Int) -> [IterableEmbeddedMessage]
    func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    
    func syncMessages(placementIds: [Int]?, completion: @escaping () -> Void)
    func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String)
    func reset()
}

public extension IterableEmbeddedManagerProtocol {
    func syncMessages(completion: @escaping () -> Void) {
        syncMessages(placementIds: nil, completion: completion)
    }
}
