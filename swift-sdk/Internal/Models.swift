//
//  Copyright © 2021 Iterable. All rights reserved.
//
// Misc JSON serialization models.

import Foundation

struct RemoteConfiguration: Codable, Equatable {
    let offlineMode: Bool
}
