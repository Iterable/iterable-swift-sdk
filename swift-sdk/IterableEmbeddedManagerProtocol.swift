//
//  Copyright © 2023 Iterable. All rights reserved.
//

import Foundation

public protocol IterableEmbeddedManagerProtocol {
    func getMessages() -> [IterableEmbeddedMessage]
    func getMessages(for placementId: Int) -> [IterableEmbeddedMessage]
    func resolveMessages(_ messages: [IterableEmbeddedMessage], completion: @escaping ([ResolvedMessage]) -> Void)

    func addUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    func removeUpdateListener(_ listener: IterableEmbeddedUpdateDelegate)
    
    func syncMessages(completion: @escaping () -> Void)
}
