//
//  MockAnonymousUserManager.swift
//  swift-sdk
//
//  Created by HARDIK MASHRU on 26/03/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
@testable import IterableSDK

class MockAnonymousUserManager: AnonymousUserManagerProtocol {
    
    private let mockDataWithOr = """
    {
       "count":1,
       "criteriaList":[
          {
             "criteriaId":12345,
             "searchQuery":{
                "combinator":"Or",
                "searchQueries":[
                 {
                    "dataType":"purchase",
                    "searchCombo":{
                       "combinator":"Or",
                       "searchQueries":[
                          {
                             "field":"shoppingCartItems.price",
                             "fieldType":"double",
                             "comparatorType":"Equals",
                             "dataType":"purchase",
                             "id":2,
                             "value":"5.9"
                          },
                          {
                             "field":"shoppingCartItems.quantity",
                             "fieldType":"long",
                             "comparatorType":"GreaterThan",
                             "dataType":"purchase",
                             "id":3,
                             "valueLong":2,
                             "value":"2"
                          },
                          {
                             "field":"total",
                             "fieldType":"long",
                             "comparatorType":"GreaterThanOrEqualTo",
                             "dataType":"purchase",
                             "id":4,
                             "valueLong":10,
                             "value":"10"
                          }
                       ]
                    }
                 }
              ]
             }
          }
       ]
    }
    """
    
    init(localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol,
         notificationStateProvider: NotificationStateProviderProtocol, apiClient: ApiClient) {
        ITBInfo()
        
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.notificationStateProvider = notificationStateProvider
        self.mockApiClient = apiClient
    }
    
    deinit {
        ITBInfo()
    }
    
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    private let notificationStateProvider: NotificationStateProviderProtocol
    private let mockApiClient: ApiClient
    
    func trackAnonEvent(name: String, dataFields: [AnyHashable : Any]?) {}
    
    func trackAnonPurchaseEvent(total: NSNumber, items: [IterableSDK.CommerceItem], dataFields: [AnyHashable : Any]?) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.Body.createdAt, value: Int(dateProvider.currentDate.timeIntervalSince1970) * 1000)
        body.setValue(for: JsonKey.Commerce.total, value: total.stringValue)
        body.setValue(for: JsonKey.Commerce.items, value: convertCommerceItemsToDictionary(items))
        if let dataFields = dataFields {
            body[JsonKey.dataFields] = dataFields
        }
        storeEventData(type: EventType.purchase, data: body)
    }
    
    func trackAnonUpdateCart(items: [IterableSDK.CommerceItem]) {}
    
    func trackAnonTokenRegistration(token: String) {}
    
    func trackAnonUpdateUser(_ dataFields: [AnyHashable : Any]) {}
    
    func updateAnonSession() {
        if var sessions = localStorage.anonymousSessions {
            sessions.itbl_anon_sessions.totalAnonSessionCount += 1
            sessions.itbl_anon_sessions.lastAnonSession = (Int(self.dateProvider.currentDate.timeIntervalSince1970) * 1000)
            localStorage.anonymousSessions = sessions
        } else {
            // create session object for the first time
            let initialAnonSessions = IterableAnonSessions(totalAnonSessionCount: 1, lastAnonSession: (Int(self.dateProvider.currentDate.timeIntervalSince1970) * 1000), firstAnonSession: (Int(self.dateProvider.currentDate.timeIntervalSince1970) * 1000))
            let anonSessionWrapper = IterableAnonSessionsWrapper(itbl_anon_sessions: initialAnonSessions)
            localStorage.anonymousSessions = anonSessionWrapper
        }
    }
    
    func getAnonCriteria() {
        self.localStorage.criteriaData = mockDataWithOr.data(using: .utf8)
    }
    
    func syncNonSyncedEvents() {}
    
    private func createKnownUserIfCriteriaMatched(criteriaId: String?) {
        if (criteriaId != nil) {
            var anonSessions = convertToDictionary(data: localStorage.anonymousSessions?.itbl_anon_sessions)
            let userId = IterableUtil.generateUUID()
            IterableAPI.setUserId(userId)
            anonSessions["matchedCriteriaId"] = criteriaId
            var appName = ""
            notificationStateProvider.isNotificationsEnabled { isEnabled in
                if (isEnabled) {
                    appName = Bundle.main.appPackageName ?? ""
                }
                if (!appName.isEmpty) {
                    anonSessions["mobilePushOptIn"] = appName
                }
                
                let response = self.mockApiClient.trackAnonSession(createdAt: (Int(self.dateProvider.currentDate.timeIntervalSince1970) * 1000), withUserId: userId, requestJson: anonSessions)
                response.onError { error in
                    print("response:: \(error.httpStatusCode)")
                }
                response.onSuccess {success in
                    print("response:: success")

                }
            }
        }
    }
    
    private func storeEventData(type: String, data: [AnyHashable: Any], shouldOverWrite: Bool? = false) {
        let storedData = localStorage.anonymousUserEvents
        var eventsDataObjects: [[AnyHashable: Any]] = [[:]]
        
        if let _storedData = storedData {
            eventsDataObjects = _storedData
        }
        var appendData = data
        appendData.setValue(for: JsonKey.eventType, value: type)
        appendData.setValue(for: JsonKey.eventTimeStamp, value: Int(dateProvider.currentDate.timeIntervalSince1970)) // this we use as unique idenfier too

        if shouldOverWrite == true {
            eventsDataObjects = eventsDataObjects.map { var subDictionary = $0; subDictionary[type] = data; return subDictionary }
        } else {
            eventsDataObjects.append(appendData)
        }
        localStorage.anonymousUserEvents = eventsDataObjects
        createKnownUserIfCriteriaMatched(criteriaId: "1234")
    }
    
    func logout() {}
    
}
