//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct PersistenceHelper {
    static func task(from: IterableTaskManagedObject) -> IterableTask {
        IterableTask(id: from.id,
                     name: from.name,
                     version: Int(from.version),
                     createdAt: from.createdAt,
                     modifiedAt: from.modifiedAt,
                     type: IterableTaskType(rawValue: from.type) ?? .apiCall,
                     attempts: Int(from.attempts),
                     lastAttemptedAt: from.lastAttemptedAt,
                     processing: from.processing,
                     scheduledAt: from.scheduledAt,
                     data: from.data,
                     failed: from.failed,
                     blocking: from.blocking,
                     requestedAt: from.requestedAt,
                     taskFailureData: from.taskFailureData)
    }
    
    static func copy(from: IterableTask, to: IterableTaskManagedObject) {
        to.id = from.id
        to.name = from.name
        to.version = Int64(from.version)
        to.createdAt = from.createdAt
        to.modifiedAt = from.modifiedAt
        to.type = from.type.rawValue
        to.attempts = Int64(from.attempts)
        to.lastAttemptedAt = from.lastAttemptedAt
        to.processing = from.processing
        to.scheduledAt = from.scheduledAt
        to.data = from.data
        to.failed = from.failed
        to.blocking = from.blocking
        to.requestedAt = from.requestedAt
        to.taskFailureData = from.taskFailureData
    }
}
