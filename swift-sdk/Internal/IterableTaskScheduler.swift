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
                  scheduledAt: Date? = nil) throws -> String {
        ITBInfo()
        let taskId = IterableUtil.generateUUID()
        let data = try JSONEncoder().encode(apiCallRequest)

        try persistenceContext.create(task: IterableTask(id: taskId,
                                                         name: apiCallRequest.getPath(),
                                                         type: .apiCall,
                                                         scheduledAt: scheduledAt ?? dateProvider.currentDate,
                                                         data: data,
                                                         requestedAt: dateProvider.currentDate))
        try persistenceContext.save()

        notificationCenter.post(name: .iterableTaskScheduled, object: self, userInfo: nil)
        
        return taskId
    }
    
    private let persistenceContextProvider: IterablePersistenceContextProvider
    private let notificationCenter: NotificationCenterProtocol
    private let dateProvider: DateProviderProtocol

    private lazy var persistenceContext: IterablePersistenceContext = {
        return persistenceContextProvider.newBackgroundContext()
    }()
}
