//
//  UnknownUserManagerProtocol.swift
//
//
//  Created by HARDIK MASHRU on 09/11/23.
//
import Foundation
@objc public protocol UnknownUserManagerProtocol {
    func trackUnknownUserEvent(name: String, dataFields: [AnyHashable: Any]?)
    func trackUnknownUserPurchaseEvent(total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?)
    func trackUnknownUserUpdateCart(items: [CommerceItem])
    func trackUnknownUserTokenRegistration(token: String)
    func trackUnknownUserUpdateUser(_ dataFields: [AnyHashable: Any])
    func updateUnknownUserSession()
    func getLastCriteriaFetch() -> Double
    func updateLastCriteriaFetch(currentTime: Double)
    func getUnknownUserCriteria()
    func syncEvents()
    func clearVisitorEventsAndUserData()
}
