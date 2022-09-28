//
//  Copyright © 2022 Iterable. All rights reserved.
//

import Foundation

@testable import IterableSDK

class MockNotificationCenter: NotificationCenterProtocol {
    init() {
        ITBInfo()
    }
    
    deinit {
        ITBInfo()
    }
    
    func addObserver(_ observer: Any, selector: Selector, name: Notification.Name?, object _: Any?) {
        observers.append(Observer(observer: observer as! NSObject,
                                  notificationName: name!,
                                  selector: selector))
    }
    
    func removeObserver(_: Any) {}
    
    func post(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?) {
        _ = observers.filter { $0.notificationName == name }.map {
            let notification = Notification(name: name, object: object, userInfo: userInfo)
            _ = $0.observer?.perform($0.selector, with: notification)
        }
    }
    
    class CallbackReference {
        init(callbackId: String,
             callbackClass: NSObject) {
            self.callbackId = callbackId
            self.callbackClass = callbackClass
        }
        
        let callbackId: String
        private let callbackClass: NSObject
    }
    
    func addCallback(forNotification notification: Notification.Name, callback: @escaping (Notification) -> Void) -> CallbackReference {
        class CallbackClass: NSObject {
            let callback: (Notification) -> Void
            
            init(callback: @escaping (Notification) -> Void) {
                self.callback = callback
            }
            
            @objc func onNotification(notification: Notification) {
                callback(notification)
            }
        }
        
        let id = IterableUtil.generateUUID()
        let callbackClass = CallbackClass(callback: callback)
        
        observers.append(Observer(id: id,
                                  observer: callbackClass,
                                  notificationName: notification,
                                  selector: #selector(callbackClass.onNotification(notification:))))
        return CallbackReference(callbackId: id, callbackClass: callbackClass)
    }
    
    func removeCallbacks(withIds ids: String...) {
        observers.removeAll { ids.contains($0.id) }
    }
    
    private class Observer: NSObject {
        let id: String
        weak var observer: NSObject?
        let notificationName: Notification.Name
        let selector: Selector
        
        init(id: String = IterableUtil.generateUUID(),
             observer: NSObject,
             notificationName: Notification.Name,
             selector: Selector) {
            self.id = id
            self.observer = observer
            self.notificationName = notificationName
            self.selector = selector
        }
    }
    
    private var observers = [Observer]()
}
