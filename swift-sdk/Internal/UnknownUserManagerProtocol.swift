//
//  UnknownUserManagerProtocol.swift
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
    func updateUnknownSession()
    func getLastCriteriaFetch() -> Double
    func updateLastCriteriaFetch(currentTime: Double)
    func getUnknownCriteria()
    func syncEvents()
    func clearVisitorEventsAndUserData()

    // MARK: - Deprecated aliases (remove in next major)

    @available(*, deprecated, renamed: "trackUnknownEvent(name:dataFields:)")
    func trackUnknownUserEvent(name: String, dataFields: [AnyHashable: Any]?)
    @available(*, deprecated, renamed: "trackUnknownPurchaseEvent(total:items:dataFields:)")
    func trackUnknownUserPurchaseEvent(total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?)
    @available(*, deprecated, renamed: "trackUnknownUpdateCart(items:)")
    func trackUnknownUserUpdateCart(items: [CommerceItem])
    @available(*, deprecated, renamed: "trackUnknownTokenRegistration(token:)")
    func trackUnknownUserTokenRegistration(token: String)
    @available(*, deprecated, renamed: "trackUnknownUpdateUser(_:)")
    func trackUnknownUserUpdateUser(_ dataFields: [AnyHashable: Any])
    @available(*, deprecated, renamed: "updateUnknownSession()")
    func updateUnknownUserSession()
    @available(*, deprecated, renamed: "getUnknownCriteria()")
    func getUnknownUserCriteria()
}
