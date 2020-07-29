//
//  Created by Tapash Majumder on 7/22/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct PersistenceHelper {
    static func task(from: IterableTaskManagedObject) -> IterableTask {
        IterableTask(id: from.id!,
                     created: from.created,
                     modified: from.modified,
                     processor: from.processor!,
                     attempts: Int(from.attempts),
                     lastAttempt: from.lastAttempt,
                     processing: from.processing,
                     scheduleTime: from.scheduleTime,
                     data: from.data)
    }
    
    static func copy(from: IterableTask, to: IterableTaskManagedObject) {
        to.id = from.id
        to.created = from.created
        to.modified = from.modified
        to.processor = from.processor
        to.attempts = Int64(from.attempts)
        to.lastAttempt = from.lastAttempt
        to.processing = from.processing
        to.scheduleTime = from.scheduleTime
        to.data = from.data
    }
}
