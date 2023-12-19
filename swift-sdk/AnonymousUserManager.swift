//
//  AnonymousUserManager.swift
//  Iterable-iOS-SDK
//
//  Created by DEV CS on 08/08/23.
//

import Foundation

@objc public protocol AnonymousUserManagerProtocol {
    func trackAnonEvent(name: String, dataFields: [AnyHashable: Any]?)
    func trackAnonPurchaseEvent(total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?)
    func trackAnonUpdateCart(items: [CommerceItem])
    func trackAnonTokenRegistration(token: String)
    func updateAnonSession()
    func createKnownUser()
    func getAnonCriteria()
    func syncNonSyncedEvents()
    func logout()
}

public class AnonymousUserManager: AnonymousUserManagerProtocol {
    
    init(localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol) {
        ITBInfo()
        
        self.localStorage = localStorage
        self.dateProvider = dateProvider
    }
    
    deinit {
        ITBInfo()
    }
    
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    
    // Tracks an anonymous event and store it locally
    public func trackAnonEvent(name: String, dataFields: [AnyHashable: Any]?) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.eventName, value: name)
        body.setValue(for: JsonKey.Body.createdAt, value: Int(dateProvider.currentDate.timeIntervalSince1970))
        body.setValue(for: JsonKey.createNewFields, value: true)
        if let dataFields = dataFields {
            body[JsonKey.dataFields] = dataFields
        }
        storeEventData(type: EventType.track, data: body)
    }
    
    // Convert commerce items to dictionaries
    private func convertCommerceItemsToDictionary(_ items: [CommerceItem]) -> [[AnyHashable:Any]] {
        let dictionaries = items.map { item in
            return item.toDictionary()
        }
        return dictionaries
    }
    
    // Convert to commerce items from dictionaries
    private func convertCommerceItems(from dictionaries: [[AnyHashable: Any]]) -> [CommerceItem] {
        return dictionaries.compactMap { dictionary in
            let item = CommerceItem(id: dictionary[JsonKey.CommerceItem.id] as? String ?? "", name: dictionary[JsonKey.CommerceItem.name] as? String ?? "", price: dictionary[JsonKey.CommerceItem.price] as? NSNumber ?? 0, quantity: dictionary[JsonKey.CommerceItem.quantity] as? UInt ?? 0)
            item.sku = dictionary[JsonKey.CommerceItem.sku] as? String
            item.itemDescription = dictionary[JsonKey.CommerceItem.description] as? String
            item.url = dictionary[JsonKey.CommerceItem.url] as? String
            item.imageUrl = dictionary[JsonKey.CommerceItem.imageUrl] as? String
            item.categories = dictionary[JsonKey.CommerceItem.categories] as? [String]
            item.dataFields = dictionary[JsonKey.CommerceItem.dataFields] as? [AnyHashable: Any]

            return item
        }
    }
    
    // Tracks an anonymous purchase event and store it locally
    public func trackAnonPurchaseEvent(total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.Body.createdAt, value: Int(dateProvider.currentDate.timeIntervalSince1970))
        body.setValue(for: JsonKey.Commerce.total, value: total.stringValue)
        body.setValue(for: JsonKey.Commerce.items, value: convertCommerceItemsToDictionary(items))
        if let dataFields = dataFields {
            body[JsonKey.dataFields] = dataFields
        }
        storeEventData(type: EventType.trackPurchase, data: body)
    }
    
    // Tracks an anonymous cart event and store it locally
    public func trackAnonUpdateCart(items: [CommerceItem]) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.Commerce.items, value: convertCommerceItemsToDictionary(items))
        storeEventData(type: EventType.cartUpdate, data: body)
    }
    
    // Tracks an anonymous token registration event and store it locally
    public func trackAnonTokenRegistration(token: String) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.token, value: token)
        storeEventData(type: EventType.tokenRegistration, data: body)
    }
    
    // Stores an anonymous sessions locally. Updates the last session time each time when new session is created
    public func updateAnonSession() {
        if var sessions = localStorage.anonymousSessions {
            sessions.itbl_anon_sessions.number_of_sessions += 1
            sessions.itbl_anon_sessions.last_session = getUTCDateTime()
            localStorage.anonymousSessions = sessions
        } else {
            // create session object for the first time
            let initialAnonSessions = IterableAnonSessions(number_of_sessions: 1, last_session: getUTCDateTime(), first_session: getUTCDateTime())
            let anonSessionWrapper = IterableAnonSessionsWrapper(itbl_anon_sessions: initialAnonSessions)
            localStorage.anonymousSessions = anonSessionWrapper
        }
    }
    
    func convertToDictionary(data: Codable) -> [AnyHashable: Any] {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(data)
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any] {
                return dictionary
            }
        } catch {
            print("Error converting to dictionary: \(error)")
        }
        return [:]
    }
    
    // Creates a user after criterias met and login the user and then sync the data through track APIs
    public func createKnownUser() {
        let userId = IterableUtil.generateUUID()
        print("userID: \(userId)")
        IterableAPI.setUserId(userId)
        IterableAPI.updateUser(convertToDictionary(data: localStorage.anonymousSessions), mergeNestedObjects: false, onSuccess: { result in
            self.syncEvents()
        })
    }
    
    // Syncs unsynced data which might have failed to sync when calling syncEvents for the first time after criterias met
    public func syncNonSyncedEvents() {
        syncEvents()
    }
    
    // Reset the locally saved data when user logs out to make sure no old data is left
    public func logout() {
        localStorage.anonymousSessions = nil
        localStorage.anonymousUserEvents = nil
    }
    
    // Syncs locally saved data through track APIs
    private func syncEvents() {
        let events = localStorage.anonymousUserEvents
        var successfulSyncedData: [Int] = []
        
        if let _events = events {
            for var eventData in _events {
                if let eventType = eventData[JsonKey.eventType] as? String {
                    eventData.removeValue(forKey: JsonKey.eventType)
                    switch eventType {
                    case EventType.track:
                        IterableAPI.implementation?.track(eventData[JsonKey.eventName] as? String ?? "", withBody: eventData, onSuccess: {result in
                            successfulSyncedData.append(eventData[JsonKey.eventTimeStamp] as? Int ?? 0)
                        })
                        break
                    case EventType.trackPurchase:
                        var userDict = [AnyHashable: Any]()
                        userDict[JsonKey.userId] = localStorage.userId
                        userDict[JsonKey.preferUserId] = true
                        userDict[JsonKey.createNewFields] = true
                        var total = NSNumber(value: 0)
                        if let _total = NumberFormatter().number(from: eventData[JsonKey.Commerce.total] as! String) {
                            total = _total
                        } else {
                            print("Conversion failed")
                        }
                        
                        IterableAPI.implementation?.trackPurchase(total, items: convertCommerceItems(from: eventData[JsonKey.Commerce.items] as! [[AnyHashable: Any]]), dataFields: eventData[JsonKey.dataFields] as? [AnyHashable : Any], withUser: userDict, createdAt: eventData[JsonKey.Body.createdAt] as? Int ?? 0, onSuccess: {result in
                            successfulSyncedData.append(eventData[JsonKey.eventTimeStamp] as? Int ?? 0)
                        })
                        break
                    case EventType.cartUpdate:
                        var userDict = [AnyHashable: Any]()
                        userDict[JsonKey.userId] = localStorage.userId
                        userDict[JsonKey.createNewFields] = true
                        IterableAPI.implementation?.updateCart(items: convertCommerceItems(from: eventData[JsonKey.Commerce.items] as! [[AnyHashable: Any]]), withUser: userDict, createdAt: eventData[JsonKey.Body.createdAt] as? Int ?? 0, onSuccess: {result in
                            successfulSyncedData.append(eventData[JsonKey.eventTimeStamp] as? Int ?? 0)
                        })
                        break
                    default:
                        break
                    }
                }
            }
            
            // commenting this code for now as we need to execute this code in some other place so after all events are suceesfully synced as this code will execute too promptly right after the above loop so we simply clear all the data where or not the APIs were successful or not
            /* let notSynchedData = filterEvents(excludingTimestamps: successfulSyncedData)
            if let _ = notSynchedData {
                localStorage.anonymousUserEvents = notSynchedData
            } else {
                localStorage.anonymousUserEvents = nil
            } */
            
            localStorage.anonymousUserEvents = nil
            localStorage.anonymousSessions = nil
        }
    }
    
    // Checks if criterias are being met.
    private func checkCriteriaCompletion() -> Bool {
        var isCriteriaMet = false
        let criteriaData = localStorage.criteriaData
        if let _criteriaData = criteriaData {
            for criteria in _criteriaData {
                for criteriaItem in criteria.criteriaList {
                    // right now we are considering track events only which has eventname. // we will later on consider other eventtypes and add related logic here
                    if let events = filterEvents(byType: criteriaItem.criteriaType, andName: criteriaItem.name) {
                        if events.count >= criteriaItem.aggregateCount ?? 1 {
                            isCriteriaMet = true
                            break
                        }
                    }
                }
            }
        }
        return isCriteriaMet
    }
    
    // Filter non-synced data
    private func filterEvents(excludingTimestamps excludedTimestamps: [Int]) -> [[AnyHashable: Any]]? {
        guard let events = localStorage.anonymousUserEvents else {
            return nil
        }
        
        let filteredEvents = events.filter { eventData in
            if let eventTimestamp = eventData[JsonKey.eventTimeStamp] as? Int,
               !excludedTimestamps.contains(eventTimestamp) {
                return true
            }
            return false
        }
        
        return filteredEvents.isEmpty ? nil : filteredEvents
    }
    
    // Filter events by type
    private func filterEvents(byType type: String) -> [[AnyHashable: Any]]? {
        guard let events = localStorage.anonymousUserEvents else {
            return nil
        }
        
        let filteredEvents = events.filter { eventData in
            if let eventType = eventData[JsonKey.eventType] as? String, eventType == type {
                return true
            }
            return false
        }
        
        return filteredEvents.isEmpty ? nil : filteredEvents
    }
    
    // Filter events by type and name
    private func filterEvents(byType type: String, andName name: String?) -> [[AnyHashable: Any]]? {
        guard let events = localStorage.anonymousUserEvents else {
            return nil
        }
        
        let filteredEvents = events.filter { eventData in
            if let eventType = eventData[JsonKey.eventType] as? String, eventType == type {
                if let eventName = eventData[JsonKey.eventName] as? String {
                    if let filterName = name {
                        return eventName == filterName
                    } else {
                        return true
                    }
                } else {
                    return true
                }
            }
            return false
        }
            
        return filteredEvents.isEmpty ? nil : filteredEvents
    }
    
    // Converts UTC Datetime from current time
    private func getUTCDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let utcDate = Date()
        return dateFormatter.string(from: utcDate)
    }
    
    // Gets the anonymous criteria
    public func getAnonCriteria() {
        // call API when it is available and save data in userdefaults, until then just save the data in userdefaults using static data
        let data: [Criteria] = [
            Criteria(criteriaId: "12", criteriaList: [
                CriteriaItem(criteriaType: "track", comparator: "equal", name: "viewedMocha", aggregateCount: 5, total: nil),
                CriteriaItem(criteriaType: "track", comparator: "equal", name: "viewedCappuccino", aggregateCount: 3, total: nil)
            ]),
            Criteria(criteriaId: "13", criteriaList: [
                CriteriaItem(criteriaType: "trackPurchase", comparator: nil, name: nil, aggregateCount: nil, total: 3),
                CriteriaItem(criteriaType: "cartUpdate", comparator: nil, name: nil, aggregateCount: nil, total: nil),
            ])
        ]
        localStorage.criteriaData = data
    }
    
    // Stores event data locally
    private func storeEventData(type: String, data: [AnyHashable: Any]) {
        let storedData = localStorage.anonymousUserEvents
        var eventsDataObjects: [[AnyHashable: Any]] = [[:]]
        
        if let _storedData = storedData {
            eventsDataObjects = _storedData
        }
        var appendData = data
        appendData.setValue(for: JsonKey.eventType, value: type)
        appendData.setValue(for: JsonKey.eventTimeStamp, value: Int(dateProvider.currentDate.timeIntervalSince1970)) // this we use as unique idenfier too

        eventsDataObjects.append(appendData)
        localStorage.anonymousUserEvents = eventsDataObjects
        if (checkCriteriaCompletion()) {
            createKnownUser()
        }
    }
}
