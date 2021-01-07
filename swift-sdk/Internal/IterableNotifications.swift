//
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
    static let iterableTaskScheduled = Notification.Name(rawValue: "itbl_task_scheduled")
    static let iterableTaskFinishedWithSuccess = Notification.Name(rawValue: "itbl_task_finished_with_success")
    static let iterableTaskFinishedWithRetry = Notification.Name(rawValue: "itbl_task_finished_with_retry")
    static let iterableTaskFinishedWithNoRetry = Notification.Name(rawValue: "itbl_task_finished_with_no_retry")
    static let iterableNetworkOffline = Notification.Name(rawValue: "itbl_network_offline")
    static let iterableNetworkOnline = Notification.Name(rawValue: "itbl_network_online")
}

struct TaskSendRequestValue {
    let taskId: String
    let sendRequestValue: SendRequestValue
}

struct TaskSendRequestError {
    let taskId: String
    let sendRequestError: SendRequestError
}

struct IterableNotificationUtil {
    static func sendRequestValueToUserInfo(_ sendRequestValue: SendRequestValue, taskId: String) -> [AnyHashable: Any] {
        var userInfo = [AnyHashable: Any]()
        userInfo[Key.taskId] = taskId
        userInfo[Key.sendRequestValue] = sendRequestValue
        return userInfo
    }

    static func sendRequestErrorToUserInfo(_ sendRequestError: SendRequestError, taskId: String) -> [AnyHashable: Any] {
        var userInfo = [AnyHashable: Any]()
        userInfo[Key.taskId] = taskId
        userInfo[Key.sendRequestError] = sendRequestError
        return userInfo
    }

    static func notificationToTaskSendRequestValue(_ notification: Notification) -> TaskSendRequestValue? {
        guard let userInfo = notification.userInfo else {
            return nil
        }
        guard let taskId = userInfo[Key.taskId] as? String else {
            return nil
        }
        guard let sendRequestValue = userInfo[Key.sendRequestValue] as? SendRequestValue else {
            return nil
        }
        
        return TaskSendRequestValue(taskId: taskId, sendRequestValue: sendRequestValue)
    }

    static func notificationToTaskSendRequestError(_ notification: Notification) -> TaskSendRequestError? {
        guard let userInfo = notification.userInfo else {
            return nil
        }
        guard let taskId = userInfo[Key.taskId] as? String else {
            return nil
        }
        guard let sendRequestError = userInfo[Key.sendRequestError] as? SendRequestError else {
            return nil
        }
        
        return TaskSendRequestError(taskId: taskId, sendRequestError: sendRequestError)
    }

    private enum Key {
        static let taskId = "taskId"
        static let sendRequestValue = "sendRequestValue"
        static let sendRequestError = "sendRequestError"
    }
    
}
