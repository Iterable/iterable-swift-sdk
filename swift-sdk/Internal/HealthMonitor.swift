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

struct HealthMonitor {
    init(dataProvider: HealthMonitorDataProviderProtocol) {
        self.dataProvider = dataProvider
    }
    
    func canSchedule() -> Bool {
        do {
            let count = try dataProvider.countTasks()
            return count <= dataProvider.maxTasks
        } catch let error {
            ITBError("DBError: " + error.localizedDescription)
            return false
        }
    }
    
    func onDBError() {
        
    }
    
    private let dataProvider: HealthMonitorDataProviderProtocol
}
