//
//  Created by Tapash Majumder on 7/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableTask {
    let id: String
    let created: Date?
    let modified: Date?
    let processor: String
    let attempts: Int
    let lastAttempt: Date?
    let processing: Bool
    let scheduleTime: Date?
    let data: Data?
    
    init(id: String,
         created: Date? = nil,
         modified: Date? = nil,
         processor: String,
         attempts: Int = 0,
         lastAttempt: Date? = nil,
         processing: Bool = false,
         scheduleTime: Date? = nil,
         data: Data? = nil) {
        self.id = id
        self.created = created
        self.modified = modified
        self.processor = processor
        self.attempts = attempts
        self.lastAttempt = lastAttempt
        self.processing = processing
        self.scheduleTime = scheduleTime
        self.data = data
    }
    
    func updated(attempts: Int? = nil,
                 lastAttempt: Date? = nil,
                 processing: Bool? = nil,
                 scheduleTime: Date? = nil,
                 data: Data? = nil) -> IterableTask {
        IterableTask(id: id,
                     created: created,
                     modified: modified,
                     processor: processor,
                     attempts: attempts ?? self.attempts,
                     lastAttempt: lastAttempt ?? self.lastAttempt,
                     processing: processing ?? self.processing,
                     scheduleTime: scheduleTime ?? self.scheduleTime,
                     data: data ?? self.data)
    }
}
