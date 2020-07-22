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
    
    func updated(attempts: Int? = nil,
                 lastAttempt: Date? = nil,
                 processing: Bool? = nil,
                 scheduleTime: Date? = nil,
                 data: Data? = nil) -> IterableTask {
        IterableTask(id: self.id,
                     created: self.created,
                     modified: self.modified,
                     processor: self.processor,
                     attempts: attempts ?? self.attempts,
                     lastAttempt: lastAttempt ?? self.lastAttempt,
                     processing: processing ?? self.processing,
                     scheduleTime: scheduleTime ?? self.scheduleTime,
                     data: data ?? self.data)
    }
}
