//
//  AnonymousUserManagerProtocol.swift
//
//
//  Created by HARDIK MASHRU on 09/11/23.
//
import Foundation
@objc public protocol UnknownUserManagerProtocol {
    func trackUnknownEvent(name: String, dataFields: [AnyHashable: Any]?)
    func trackUnknownPurchaseEvent(total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?)
    func trackUnknownUpdateCart(items: [CommerceItem])
    func trackUnknownTokenRegistration(token: String)
    func trackUnknownUpdateUser(_ dataFields: [AnyHashable: Any])
    func updateUnknownUserSession()
    func getLastCriteriaFetch() -> Double
    func updateLastCriteriaFetch(currentTime: Double)
    func getUnknownUserCriteria()
    func syncEvents()
    func clearVisitorEventsAndUserData()
}
