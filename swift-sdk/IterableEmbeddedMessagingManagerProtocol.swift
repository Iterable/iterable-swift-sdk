//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

public protocol IterableEmbeddedMessagingManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage]
    func resolveMessages(_ messages: [IterableEmbeddedMessage], completion: @escaping ([ResolvedMessage]) -> Void)

    
    func addUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate)
    func removeUpdateListener(_ listener: IterableEmbeddedMessagingUpdateDelegate)
    
    func syncMessages(completion: @escaping () -> Void)
}
