//
//  Copyright © 2021 Iterable. All rights reserved.
//
// Misc JSON serialization models.

import Foundation

struct RemoteConfiguration: Codable, Equatable {
    static let isBeta = true
    
    let offlineMode: Bool
    let offlineModeBeta: Bool
    
    func isOfflineModeEnabled() -> Bool {
        Self.isBeta ? offlineModeBeta : offlineMode
    }
    
}
