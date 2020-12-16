//
//  Created by Tapash Majumder on 8/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)
class IterableTaskScheduler {
    init(persistenceContextProvider: IterablePersistenceContextProvider,
         notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
         dateProvider: DateProviderProtocol = SystemDateProvider()) {
        self.persistenceContextProvider = persistenceContextProvider
        self.notificationCenter = notificationCenter
        self.dateProvider = dateProvider
    }
    
    func schedule(apiCallRequest: IterableAPICallRequest,
                  context: IterableTaskContext = IterableTaskContext(blocking: true),
                  scheduledAt: Date? = nil) -> Result<String, IterableTaskError> {
        ITBInfo()
        let taskId = IterableUtil.generateUUID()
        do {
            let data = try JSONEncoder().encode(apiCallRequest)
            
            try persistenceContext.create(task: IterableTask(id: taskId,
                                                             name: apiCallRequest.getPath(),
                                                             type: .apiCall,
                                                             scheduledAt: scheduledAt ?? dateProvider.currentDate,
                                                             data: data,
                                                             requestedAt: dateProvider.currentDate))
            try persistenceContext.save()
            
            notificationCenter.post(name: .iterableTaskScheduled, object: self, userInfo: nil)
        } catch let error {
            return Result.failure(IterableTaskError.general("schedule taskId: \(taskId) failed with error: \(error.localizedDescription)"))
        }
        return Result.success(taskId)
    }
    
    func deleteAllTasks() throws {
        ITBInfo()
        try persistenceContextProvider.mainQueueContext().deleteAllTasks()
    }
    
    private let persistenceContextProvider: IterablePersistenceContextProvider
    private let notificationCenter: NotificationCenterProtocol
    private let dateProvider: DateProviderProtocol

    private lazy var persistenceContext: IterablePersistenceContext = {
        return persistenceContextProvider.newBackgroundContext()
    }()
}
