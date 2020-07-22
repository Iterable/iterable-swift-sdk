//
//  Created by Tapash Majumder on 7/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableTask {
    let id: String
    var created: Date?
    var modified: Date?
    let processor: String
    var attempts: Int = 0
    var lastAttempt: Date?
    var processing: Bool = false
    var scheduleTime: Date?
    var data: Data?
}
