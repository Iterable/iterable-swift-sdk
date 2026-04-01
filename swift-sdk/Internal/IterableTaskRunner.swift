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
         dateProvider: DateProviderProtocol = SystemDateProvider(),
         autoRetry: Bool = false,
         connectivityDebounceInterval: TimeInterval = 3.0) {
        ITBInfo()
        self.networkSession = networkSession
        self.healthMonitor = healthMonitor
        self.notificationCenter = notificationCenter
        self.timeInterval = timeInterval
        self.connectivityDebounceInterval = connectivityDebounceInterval
        self.dateProvider = dateProvider
        self.connectivityManager = connectivityManager
        self.persistenceContext = persistenceContextProvider.newBackgroundContext()
        self.autoRetry = autoRetry

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
        self.notificationCenter.addObserver(self,
                                               selector: #selector(onAuthTokenRefreshed(notification:)),
                                               name: .iterableAuthTokenRefreshed,
                                               object: nil)
        self.connectivityManager.connectivityChangedCallback = { [weak self]  in self?.onConnectivityChanged(connected: $0) }
    }
    
    func start() {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            self?.paused = false
            self?.authPaused = false
            self?.connectivityManager.start()
            self?.run()
        }
    }
    
    func stop() {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            self?.connectivityDebounceWorkItem?.cancel()
            self?.connectivityDebounceWorkItem = nil
            self?.paused = true
            self?.running = false
            self?.connectivityManager.stop()
        }
    }
    
    @objc
    private func onTaskScheduled(notification: Notification) {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            guard self?.paused == false else { return }
            // Allow run() even when authPaused — processTasks() will
            // selectively execute only tasks that don't require JWT auth.
            self?.run()
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
            guard let self = self else { return }

            // Cancel any pending reconnect debounce.
            self.connectivityDebounceWorkItem?.cancel()
            self.connectivityDebounceWorkItem = nil

            if connected {
                // Debounce reconnect: wait a short period to confirm connectivity
                // is stable before resuming task processing. This prevents rapid
                // pause/resume cycles when the network is flapping.
                let workItem = DispatchWorkItem { [weak self] in
                    self?.persistenceContext.perform {
                        guard let self = self, self.paused else { return }
                        ITBInfo("Connectivity confirmed stable, resuming")
                        self.paused = false
                        self.run()
                    }
                }
                self.connectivityDebounceWorkItem = workItem
                DispatchQueue.global().asyncAfter(
                    deadline: .now() + self.connectivityDebounceInterval,
                    execute: workItem
                )
            } else {
                if !self.paused {
                    ITBInfo("Network disconnected, pausing")
                    self.paused = true
                }
            }
        }
    }

    @objc
    private func onAuthTokenRefreshed(notification _: Notification) {
        ITBInfo()
        persistenceContext.perform { [weak self] in
            guard let self = self else { return }

            if self.authPaused {
                ITBInfo("Auth token refreshed, clearing auth pause")
                self.authPaused = false
            }

            // Only resume if network is also available.
            // If paused (no connectivity), run() will be triggered
            // when connectivity returns via onConnectivityChanged.
            guard !self.paused else {
                ITBInfo("Network still unavailable, deferring resume until connectivity returns")
                return
            }
            self.run()
        }
    }

    private func run() {
        ITBInfo()
        guard !paused else {
            ITBInfo("Cannot run when network paused")
            return
        }
        // Note: authPaused is NOT checked here.
        // processTasks() handles it per-task, allowing unauthenticated
        // tasks to proceed while auth-required tasks stay queued.
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
        running = false
        guard !paused else {
            ITBInfo("Paused")
            return
        }
        guard !authPaused else {
            ITBInfo("Auth paused — waiting for token refresh")
            return
        }

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
        /// Check whether we were stopped in the middle of running tasks.
        /// Note: authPaused is NOT checked here — the per-task logic below
        /// handles it by routing to unauthenticated tasks only.
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
            let task: IterableTask?
            if authPaused {
                // When auth is paused, only execute tasks that don't require JWT.
                // Auth-required tasks stay in the queue until auth resumes.
                task = try nextTaskNotRequiringAuth()
                if task == nil {
                    ITBInfo("Auth paused and no unauthenticated tasks to process")
                    running = false
                    return
                }
            } else {
                task = try persistenceContext.nextTask()
            }

            if let task = task {
                execute(task: task).onSuccess { [weak self] executionResult in
                    ITBInfo()
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.persistenceContext.perform {
                        switch executionResult {
                        case .success, .failure, .error:
                            strongSelf.processTasks()
                        case .processing:
                            strongSelf.scheduleNext()
                        case .retry:
                            if strongSelf.authPaused && Self.taskRequiresAuth(task) {
                                // An auth-required task caused the pause.
                                // Continue processing to drain any unauthenticated
                                // tasks remaining in the queue.
                                strongSelf.processTasks()
                            } else if strongSelf.authPaused {
                                // An unauthenticated task retried during auth pause
                                // (e.g., network error). Stop to avoid a tight retry
                                // loop; processing resumes on auth refresh or new task.
                                strongSelf.running = false
                            } else {
                                strongSelf.scheduleNext()
                            }
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
            let processor = IterableAPICallTaskProcessor(networkSession: networkSession, dateProvider: dateProvider, autoRetry: autoRetry)
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
                    if strongSelf.autoRetry && IterableAPICallTaskProcessor.isJWTAuthFailure(sendRequestError: failureDetail) {
                        ITBInfo("JWT auth failure with autoRetry enabled, pausing task runner")
                        strongSelf.authPaused = true
                    }
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
    
    // MARK: - Auth Bypass Helpers

    /// Returns the first task in the queue (by scheduledAt order) that does not require JWT authentication.
    private func nextTaskNotRequiringAuth() throws -> IterableTask? {
        let allTasks = try persistenceContext.findAllTasks()
        return allTasks
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first { !Self.taskRequiresAuth($0) }
    }

    /// Determines whether a task requires JWT authentication by inspecting its API path.
    /// Uses `task.name` which is set to the API path at scheduling time.
    static func taskRequiresAuth(_ task: IterableTask) -> Bool {
        guard let path = task.name else {
            ITBInfo("Task \(task.id) has no name/path, defaulting to auth-required")
            return true
        }
        return Const.Path.requiresJWTAuth(path)
    }

    deinit {
        ITBInfo()
        connectivityDebounceWorkItem?.cancel()
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
    private var connectivityDebounceWorkItem: DispatchWorkItem?
    private var paused = false
    private var authPaused = false
    private let networkSession: NetworkSessionProtocol
    private let healthMonitor: HealthMonitor
    private let notificationCenter: NotificationCenterProtocol
    private let timeInterval: TimeInterval
    private let connectivityDebounceInterval: TimeInterval
    private let dateProvider: DateProviderProtocol
    private let connectivityManager: NetworkConnectivityManager
    private var running = false
    private(set) var autoRetry: Bool

    func setAutoRetry(_ value: Bool) {
        persistenceContext.perform { [weak self] in
            self?.autoRetry = value
        }
    }

    private let persistenceContext: IterablePersistenceContext
}
