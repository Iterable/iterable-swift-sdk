//
//  Created by Tapash Majumder on 8/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
struct IterableTaskScheduler {
    // TODO: @tqm Use DateProvider
    func schedule(apiCallRequest: IterableAPICallRequest,
                  context: IterableTaskContext,
                  scheduledAt: Date = Date()) throws -> String {
        // persist data
        let taskId = IterableUtil.generateUUID()
        let data = try JSONEncoder().encode(apiCallRequest)

        let persistenceContext = persistenceProvider.newBackgroundContext()
        try persistenceContext.create(task: IterableTask(id: taskId,
                                                         type: .apiCall,
                                                         scheduledAt: scheduledAt,
                                                         data: data,
                                                         requestedAt: Date()))
        try persistenceContext.save()

        return taskId
    }
    
    private let persistenceProvider: IterablePersistenceContextProvider = CoreDataPersistenceContextProvider()
}
