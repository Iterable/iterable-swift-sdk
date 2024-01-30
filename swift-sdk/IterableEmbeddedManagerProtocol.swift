//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

public protocol IterableEmbeddedManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage]
    func getMessages(for placementId: Int) -> [IterableEmbeddedMessage]
    func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    
    func syncMessages(completion: @escaping () -> Void)
    func handleEmbeddedClick(message: IterableEmbeddedMessage, buttonIdentifier: String?, clickedUrl: String)
    func reset()
}
