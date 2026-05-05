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

    // Delete every task except those whose `name` (set to the API path at schedule time)
    // matches `preservedName`. Used by the logout flow so that an in-flight
    // `disableDevice` task — which carries its own identity snapshot and is explicitly
    // meant to run after the user logs out — survives the queue purge.
    func deleteAllTasks(preservingTasksWithName preservedName: String) {
        ITBInfo()
        let persistenceContext = persistenceContextProvider.newBackgroundContext()
        persistenceContext.perform { [weak self] in
            do {
                let tasks = try persistenceContext.findAllTasks()
                for task in tasks where task.name != preservedName {
                    try persistenceContext.delete(task: task)
                }
                try persistenceContext.save()
            } catch {
                ITBError("deleteAllTasks(preserving:) failed: \(error.localizedDescription)")
                self?.healthMonitor.onDeleteAllTasksError()
            }
        }
    }

    private let persistenceContextProvider: IterablePersistenceContextProvider
    private let notificationCenter: NotificationCenterProtocol
    private let healthMonitor: HealthMonitor
    private let dateProvider: DateProviderProtocol
}
