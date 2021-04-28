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
        do {
            let count = try dataProvider.countTasks()
            return count <= dataProvider.maxTasks
        } catch let error {
            ITBError("DBError: " + error.localizedDescription)
            return false
        }
    }
    
    func onScheduleError(apiCallRequest: IterableAPICallRequest) {
        let currentDate = dateProvider.currentDate
        let apiCallRequest = apiCallRequest.addingCreatedAt(currentDate)
        if let urlRequest = apiCallRequest.convertToURLRequest(sentAt: currentDate) {
            _ = RequestSender.sendRequest(urlRequest, usingSession: networkSession)
        }
        delegate?.onDBError()
    }
    
    private let dataProvider: HealthMonitorDataProviderProtocol
    private let dateProvider: DateProviderProtocol
    private let networkSession: NetworkSessionProtocol
}
