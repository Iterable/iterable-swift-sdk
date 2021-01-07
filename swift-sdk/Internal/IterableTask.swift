//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableTask {
    static let currentVersion = 1
    
    let id: String
    let name: String?
    let version: Int
    let createdAt: Date? // Time at which this task record was created
    let modifiedAt: Date? // Time when this record was modified
    let type: IterableTaskType
    let attempts: Int
    let lastAttemptedAt: Date?
    let processing: Bool
    let scheduledAt: Date // Time after which this task can be scheduled
    let data: Data?
    let failed: Bool
    let blocking: Bool
    let requestedAt: Date // Time when the request was made by SDK
    let taskFailureData: Data?
    
    init(id: String,
         name: String? = nil,
         version: Int = IterableTask.currentVersion,
         createdAt: Date? = nil,
         modifiedAt: Date? = nil,
         type: IterableTaskType,
         attempts: Int = 0,
         lastAttemptedAt: Date? = nil,
         processing: Bool = false,
         scheduledAt: Date,
         data: Data? = nil,
         failed: Bool = false,
         blocking: Bool = true,
         requestedAt: Date,
         taskFailureData: Data? = nil) {
        self.id = id
        self.name = name
        self.version = version
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.type = type
        self.attempts = attempts
        self.lastAttemptedAt = lastAttemptedAt
        self.processing = processing
        self.scheduledAt = scheduledAt
        self.data = data
        self.failed = failed
        self.blocking = blocking
        self.requestedAt = requestedAt
        self.taskFailureData = taskFailureData
    }
    
    func updated(attempts: Int? = nil,
                 lastAttemptedAt: Date? = nil,
                 processing: Bool? = nil,
                 scheduledAt: Date? = nil,
                 data: Data? = nil,
                 failed: Bool? = nil,
                 taskFailureData: Data? = nil) -> IterableTask {
        IterableTask(id: id,
                     name: name,
                     version: version,
                     createdAt: createdAt,
                     modifiedAt: modifiedAt,
                     type: type,
                     attempts: attempts ?? self.attempts,
                     lastAttemptedAt: lastAttemptedAt ?? self.lastAttemptedAt,
                     processing: processing ?? self.processing,
                     scheduledAt: scheduledAt ?? self.scheduledAt,
                     data: data ?? self.data,
                     failed: failed ?? false,
                     blocking: blocking,
                     requestedAt: requestedAt,
                     taskFailureData: taskFailureData ?? self.taskFailureData)
    }
}
