//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation
import UIKit

class IterableTaskRunner: NSObject {
    init(networkSession: NetworkSessionProtocol = URLSession(configuration: .default),
         persistenceContextProvider: IterablePersistenceContextProvider,
         healthMonitor: HealthMonitor,
         notificationCenter: NotificationCenterProtocol = NotificationCenter.default,
         timeInterval: TimeInterval = 1.0 * 60,
         connectivityManager: NetworkConnectivityManager = NetworkConnectivityManager(),
         dateProvider: DateProviderProtocol = SystemDateProvider()) {
        ITBInfo()
        self.networkSession = networkSession
        self.healthMonitor = healthMonitor
        self.notificationCenter = notificationCenter
        self.timeInterval = timeInterval
        self.dateProvider = dateProvider
        self.connectivityManager = connectivityManager
        self.persistenceContext = persistenceContextProvider.newBackgroundContext()
        
        super.init()

        self.notificationCenter.addObserver(self,
                                            selector: #selector(onTaskScheduled(notification:)),
                                            name: .iterableTaskScheduled,
                                            object: nil)
        self.notificationCenter.addObserver(self,
                                       selector: #selector(onAppWillEnterForeground(notification:)),
                                       name: UIApplication.willEnterForegroundNotification,
                                       object: nil)
        self.notificationCenter.addObserver(self,
                                       selector: #selector(onAppDidEnterBackground(notification:)),
                                       name: UIApplication.didEnterBackgroundNotification,
                                       object: nil)
        self.connectivityManager.connectivityChangedCallback = { [weak self]  in self?.onConnectivityChanged(connected: $0) }
    }
    
    func start() {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            self?.paused = false
            self?.connectivityManager.start()
            self?.run()
        }
    }
    
    func stop() {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            self?.paused = true
            self?.running = false
            self?.connectivityManager.stop()
        }
    }
    
    @objc
    private func onTaskScheduled(notification: Notification) {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            if self?.paused == false {
                self?.run()
            }
        }
    }
    
    @objc
    private func onAppWillEnterForeground(notification _: Notification) {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            self?.start()
        }
    }
    
    @objc
    private func onAppDidEnterBackground(notification _: Notification) {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            self?.stop()
        }
    }

    private func onConnectivityChanged(connected: Bool) {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            if connected {
                if self?.paused == true {
                    self?.paused = false
                    self?.run()
                }
            } else {
                if self?.paused == false {
                    self?.paused = true
                }
            }
        }
    }
    
    private func run() {
        ITBInfo()
        guard !paused else {
            ITBInfo("Cannot run when paused")
            return
        }
        guard !running else {
            ITBInfo("Already running")
            return
        }

        running = true
        
        workItem?.cancel()
        
        processTasks()
    }
    
    private func scheduleNext() {
        ITBInfo()
        guard !paused else {
            ITBInfo("Paused")
            return
        }
        
        running = false

        workItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.persistenceContext.perform {
                self?.run()
            }
        }
        self.workItem = workItem
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval, execute: workItem)
    }

    private func processTasks() {
        ITBInfo()

        /// This is a recursive function.
        /// Check whether we were stopped in the middle of running tasks
        guard !paused else {
            ITBInfo("Tasks paused before finishing processTasks()")
            scheduleNext()
            return
        }
        guard healthMonitor.canProcess() else {
            ITBInfo("Health monitor stopped processing")
            scheduleNext()
            return
        }

        do {
            if let task = try persistenceContext.nextTask() {
                execute(task: task).onSuccess { [weak self] executionResult in
                    ITBInfo()
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.persistenceContext.perform {
                        switch executionResult {
                        case .success, .failure, .error:
                            strongSelf.processTasks()
                        case .processing, .retry:
                            strongSelf.scheduleNext()
                        }
                    }
                }
            } else {
                ITBInfo("No tasks to execute")
                scheduleNext()
            }
        } catch let error {
            ITBError("Next task error: \(error.localizedDescription)")
            healthMonitor.onNextTaskError()
            scheduleNext()
        }
    }
    
    @discardableResult
    private func execute(task: IterableTask) -> Pending<TaskExecutionResult, Never> {
        ITBInfo("Executing taskId: \(task.id), name: \(task.name ?? "nil")")
        guard task.processing == false else {
            return Fulfill<TaskExecutionResult, Never>(value: .processing)
        }

        switch task.type {
        case .apiCall:
            let processor = IterableAPICallTaskProcessor(networkSession: networkSession, dateProvider: dateProvider)
            return processAPICallTask(processor: processor, task: task)
        }
    }

    private func processAPICallTask(processor: IterableAPICallTaskProcessor,
                                    task: IterableTask) -> Pending<TaskExecutionResult, Never> {
        ITBInfo()
        let result = Fulfill<TaskExecutionResult, Never>()
        do {
            try processor.process(task: task).onCompletion { [weak self] taskResult in
                guard let strongSelf = self else {
                    ITBError("Could not create strongSelf")
                    result.resolve(with: .error)
                    return
                }
                strongSelf.processTaskResultInQueue(task: task, taskResult: taskResult).onSuccess { taskExecutionResult in
                    result.resolve(with: taskExecutionResult)
                }
            } receiveError: { [weak self] error in
                // TODO: test
                ITBError("task processing error: \(error.localizedDescription)")
                guard let strongSelf = self else {
                    return
                }
                strongSelf.deleteTask(task: task)
                result.resolve(with: .failure)
            }
        } catch let error {
            // TODO: test
            ITBError("Error proessing task: \(task.id), message: \(error.localizedDescription)")
            deleteTask(task: task)
            result.resolve(with: .error)
        }
        
        return result
    }

    private func processTaskResultInQueue(task: IterableTask,  taskResult: IterableTaskResult) -> Pending<TaskExecutionResult, Never> {
        ITBInfo()
        let fulfill = Fulfill<TaskExecutionResult, Never>()
        
        persistenceContext.perform { [weak self] in
            guard let strongSelf = self else {
                ITBError()
                return
            }
            switch taskResult {
            case let .success(detail: detail):
                ITBInfo("task: \(task.id) succeeded")
                strongSelf.deleteTask(task: task)
                if let successDetail = detail as? SendRequestValue {
                    let userInfo = IterableNotificationUtil.sendRequestValueToUserInfo(successDetail, taskId: task.id)
                    strongSelf.notificationCenter.post(name: .iterableTaskFinishedWithSuccess,
                                                       object: strongSelf,
                                                       userInfo: userInfo)
                }
                fulfill.resolve(with: .success)
            case let .failureWithNoRetry(detail: detail):
                ITBInfo("task: \(task.id) failed with no retry.")
                strongSelf.deleteTask(task: task)
                if let failureDetail = detail as? SendRequestError {
                    let userInfo = IterableNotificationUtil.sendRequestErrorToUserInfo(failureDetail, taskId: task.id)
                    strongSelf.notificationCenter.post(name: .iterableTaskFinishedWithNoRetry,
                                                       object: strongSelf,
                                                       userInfo: userInfo)
                }
                fulfill.resolve(with: .failure)
            case let .failureWithRetry(_, detail: detail):
                ITBInfo("task: \(task.id) processed with retry")
                if let failureDetail = detail as? SendRequestError {
                    let userInfo = IterableNotificationUtil.sendRequestErrorToUserInfo(failureDetail, taskId: task.id)
                    strongSelf.notificationCenter.post(name: .iterableTaskFinishedWithRetry,
                                                       object: strongSelf,
                                                       userInfo: userInfo)
                }
                fulfill.resolve(with: .retry)
            }
        }
        
        return fulfill
    }
    
    deinit {
        ITBInfo()
        notificationCenter.removeObserver(self)
    }
    
    private func deleteTask(task: IterableTask) {
        ITBInfo("deleting task: \(task.id)")
        do {
            try self.persistenceContext.delete(task: task)
            try self.persistenceContext.save()
        } catch let error {
            ITBError(error.localizedDescription)
            self.healthMonitor.onDeleteError(task: task)
        }
    }
    
    private enum TaskExecutionResult {
        case processing
        case success
        case failure
        case retry
        case error
    }
    
    private var workItem: DispatchWorkItem?
    private var paused = false
    private let networkSession: NetworkSessionProtocol
    private let healthMonitor: HealthMonitor
    private let notificationCenter: NotificationCenterProtocol
    private let timeInterval: TimeInterval
    private let dateProvider: DateProviderProtocol
    private let connectivityManager: NetworkConnectivityManager
    private var running = false

    private let persistenceContext: IterablePersistenceContext
}
