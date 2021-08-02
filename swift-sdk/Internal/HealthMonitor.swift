//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

protocol HealthMonitorDataProviderProtocol {
    var maxTasks: Int { get }
    func countTasks() throws -> Int
}

struct HealthMonitorDataProvider: HealthMonitorDataProviderProtocol {
    init(maxTasks: Int,
         persistenceContextProvider: IterablePersistenceContextProvider) {
        self.maxTasks = maxTasks
        self.persistenceContextProvider = persistenceContextProvider
    }
    
    let maxTasks: Int

    func countTasks() throws -> Int {
        return try persistenceContextProvider.newBackgroundContext().countTasks()
    }
    
    private let persistenceContextProvider: IterablePersistenceContextProvider
}

protocol HealthMonitorDelegate: AnyObject {
    func onDBError()
}

@available(iOSApplicationExtension, unavailable)
class HealthMonitor {
    init(dataProvider: HealthMonitorDataProviderProtocol,
         dateProvider: DateProviderProtocol,
         networkSession: NetworkSessionProtocol) {
        ITBInfo()
        self.dataProvider = dataProvider
        self.dateProvider = dateProvider
        self.networkSession = networkSession
    }
    
    deinit {
        ITBInfo()
    }
    
    weak var delegate: HealthMonitorDelegate?
    
    func canSchedule() -> Bool {
        ITBInfo()
        // do not schedule further on error
        guard errored == false else {
            return false
        }

        do {
            let count = try dataProvider.countTasks()
            return count < dataProvider.maxTasks
        } catch let error {
            ITBError("DBError: " + error.localizedDescription)
            onError()
            return false
        }
    }
    
    func canProcess() -> Bool {
        ITBInfo()
        return !errored
    }
    
    func onScheduleError(apiCallRequest: IterableAPICallRequest) {
        ITBInfo()
        let currentDate = dateProvider.currentDate
        let apiCallRequest = apiCallRequest.addingCreatedAt(currentDate)
        if let urlRequest = apiCallRequest.convertToURLRequest(sentAt: currentDate) {
            _ = RequestSender.sendRequest(urlRequest, usingSession: networkSession)
        }
        onError()
    }
    
    func onDeleteError(task: IterableTask) {
        ITBInfo()
        onError()
    }
    
    func onNextTaskError() {
        ITBInfo()
        onError()
    }
    
    func onDeleteAllTasksError() {
        ITBInfo()
        onError()
    }
    
    private func onError() {
        errored = true
        delegate?.onDBError()
    }
    
    private var errored = false
    private let dataProvider: HealthMonitorDataProviderProtocol
    private let dateProvider: DateProviderProtocol
    private let networkSession: NetworkSessionProtocol
}
