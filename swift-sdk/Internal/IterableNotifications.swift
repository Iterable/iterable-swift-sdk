//
//  Created by Tapash Majumder on 8/18/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

protocol NotificationCenterProtocol {
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object: Any?)
    func removeObserver(_ observer: Any)
    func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?)
}

extension NotificationCenter: NotificationCenterProtocol {}

extension Notification.Name {
    static let iterableTaskFinishedWithSuccess = Notification.Name(rawValue: "itbl_task_finished_with_success")
    static let iterableTaskFinishedWithRetry = Notification.Name(rawValue: "itbl_task_finished_with_retry")
    static let iterableTaskFinishedWithNoRetry = Notification.Name(rawValue: "itbl_task_finished_with_no_retry")
}

