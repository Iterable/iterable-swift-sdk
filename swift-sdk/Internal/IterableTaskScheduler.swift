//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

class IterableTaskScheduler {
    init(persistenceContextProvider: IterablePersistenceContextProvider,
         notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
         healthMonitor: HealthMonitor,
         dateProvider: DateProviderProtocol = SystemDateProvider()) {
        self.persistenceContextProvider = persistenceContextProvider
        self.notificationCenter = notificationCenter
        self.healthMonitor = healthMonitor
        self.dateProvider = dateProvider
    }
    
    func schedule(apiCallRequest: IterableAPICallRequest,
                  context: IterableTaskContext = IterableTaskContext(blocking: true),
                  scheduledAt: Date? = nil) -> Pending<String, IterableTaskError>  {
        ITBInfo()
        let fulfill = Fulfill<String, IterableTaskError>()
        let persistenceContext = persistenceContextProvider.newBackgroundContext()
        persistenceContext.perform { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let taskId = IterableUtil.generateUUID()
            do {
                let data = try JSONEncoder().encode(apiCallRequest)
                
                try persistenceContext.create(task: IterableTask(id: taskId,
                                                                 name: apiCallRequest.getPath(),
                                                                 type: .apiCall,
                                                                 scheduledAt: scheduledAt ?? strongSelf.dateProvider.currentDate,
                                                                 data: data,
                                                                 requestedAt: strongSelf.dateProvider.currentDate))
                try persistenceContext.save()
                
                strongSelf.notificationCenter.post(name: .iterableTaskScheduled, object: strongSelf, userInfo: nil)
            } catch let error {
                strongSelf.healthMonitor.onScheduleError(apiCallRequest: apiCallRequest)
                fulfill.reject(with: IterableTaskError.general("schedule taskId: \(taskId) failed with error: \(error.localizedDescription)"))
            }
            fulfill.resolve(with: taskId)
        }
        return fulfill
    }

    func deleteAllTasks() {
        ITBInfo()
        let persistenceContext = persistenceContextProvider.newBackgroundContext()
        persistenceContext.perform { [weak self] in
            do {
                try persistenceContext.deleteAllTasks()
                try persistenceContext.save()
            } catch {
                ITBError("deleteAllTasks: \(error.localizedDescription)")
                self?.healthMonitor.onDeleteAllTasksError()
            }
        }
    }

    private let persistenceContextProvider: IterablePersistenceContextProvider
    private let notificationCenter: NotificationCenterProtocol
    private let healthMonitor: HealthMonitor
    private let dateProvider: DateProviderProtocol
}
