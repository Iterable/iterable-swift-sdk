//
//  UnknownUserManager.swift
//  Iterable-iOS-SDK
//
//  Created by DEV CS on 08/08/23.
//

import Foundation

public class UnknownUserManager: UnknownUserManagerProtocol {
    
    init(config: IterableConfig,
         localStorage: LocalStorageProtocol,
         dateProvider: DateProviderProtocol,
         notificationStateProvider: NotificationStateProviderProtocol) {
        ITBInfo()
        self.config = config
        self.localStorage = localStorage
        self.dateProvider = dateProvider
        self.notificationStateProvider = notificationStateProvider
    }
    deinit {
        ITBInfo()
    }
    
    private var localStorage: LocalStorageProtocol
    private let dateProvider: DateProviderProtocol
    private let notificationStateProvider: NotificationStateProviderProtocol
    private var config: IterableConfig
    private(set) var lastCriteriaFetch: Double = 0
    private var isCriteriaMatched = false

    /// Tracks an unknown user event and store it locally
    public func trackUnknownUserEvent(name: String, dataFields: [AnyHashable: Any]?) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.eventName, value: name)
        body.setValue(for: JsonKey.Body.createdAt, value: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate))
        body.setValue(for: JsonKey.createNewFields, value: true)
        if let dataFields = dataFields {
            body[JsonKey.dataFields] = dataFields
        }
        storeEventData(type: EventType.customEvent, data: body)
    }
    
    /// Tracks an unknown user update event and store it locally
    public func trackUnknownUserUpdateUser(_ dataFields: [AnyHashable: Any]) {
        storeEventData(type: EventType.updateUser, data: dataFields, shouldOverWrite: true)
    }
    
    /// Tracks an unknown user purchase event and store it locally
    public func trackUnknownUserPurchaseEvent(total: NSNumber, items: [CommerceItem], dataFields: [AnyHashable: Any]?) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.Body.createdAt, value:IterableUtil.secondsFromEpoch(for: dateProvider.currentDate))
        body.setValue(for: JsonKey.Commerce.total, value: total.stringValue)
        body.setValue(for: JsonKey.Commerce.items, value: convertCommerceItemsToDictionary(items))
        if let dataFields = dataFields {
            body[JsonKey.dataFields] = dataFields
        }
        storeEventData(type: EventType.purchase, data: body)
    }
    
    /// Tracks an unknown user cart event and store it locally
    public func trackUnknownUserUpdateCart(items: [CommerceItem]) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.Body.createdAt, value: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate))
        body.setValue(for: JsonKey.Commerce.items, value: convertCommerceItemsToDictionary(items))
        storeEventData(type: EventType.updateCart, data: body)
    }
    
    /// Tracks an unknown user token registration event and store it locally
    public func trackUnknownUserTokenRegistration(token: String) {
        var body = [AnyHashable: Any]()
        body.setValue(for: JsonKey.token, value: token)
        storeEventData(type: EventType.tokenRegistration, data: body)
    }
    
    /// Stores an unknown user sessions locally. Updates the last session time each time when new session is created
    public func updateUnknownUserSession() {
        if var sessions = localStorage.unknownUserSessions {
            sessions.itbl_unknown_user_sessions.totalUnknownUserSessionCount += 1
            sessions.itbl_unknown_user_sessions.lastUnknownUserSession = IterableUtil.secondsFromEpoch(for: dateProvider.currentDate)
            localStorage.unknownUserSessions = sessions
        } else {
            // create session object for the first time
            let initialUnknownUserSessions = IterableUnknownUserSessions(totalUnknownUserSessionCount: 1, lastUnknownUserSession: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate), firstUnknownUserSession: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate))
            let unknownUserSessionWrapper = IterableUnknownUserSessionsWrapper(itbl_unknown_user_sessions: initialUnknownUserSessions)
            localStorage.unknownUserSessions = unknownUserSessionWrapper
        }
    }
    
    /// Syncs unsynced data which might have failed to sync when calling syncEvents for the first time after criterias met
    public func syncNonSyncedEvents() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // little delay necessary in case it takes time to store userIdUnknownUser in localstorage
            self.syncEvents()
        }
    }
    
    /// Syncs locally saved data through track APIs
    public func syncEvents() {
        if let events = localStorage.unknownUserEvents {
            for var eventData in events {
                if let eventType = eventData[JsonKey.eventType] as? String {
                    eventData.removeValue(forKey: JsonKey.eventType)
                    switch eventType {
                    case EventType.customEvent:
                        IterableAPI.implementation?.track(eventData[JsonKey.eventName] as? String ?? "", withBody: eventData)
                        break
                    case EventType.purchase:
                        var total = NSNumber(value: 0)
                        if let _total = NumberFormatter().number(from: eventData[JsonKey.Commerce.total] as! String) {
                            total = _total
                        }
                        
                        IterableAPI.implementation?.trackPurchase(
                            total,
                            items: convertCommerceItems(from: eventData[JsonKey.Commerce.items] as! [[AnyHashable: Any]]),
                            dataFields: eventData[JsonKey.dataFields] as? [AnyHashable : Any],
                            createdAt: eventData[JsonKey.Body.createdAt] as? Int ?? 0
                        )
                        break
                    case EventType.updateCart:
                        IterableAPI.implementation?.updateCart(
                            items: convertCommerceItems(from: eventData[JsonKey.Commerce.items] as! [[AnyHashable: Any]]),
                            createdAt: eventData[JsonKey.Body.createdAt] as? Int ?? 0
                        )
                        break
                    default:
                        break
                    }
                }
            }
        }
        
        if var userUpdate = localStorage.unknownUserUpdate {
            if userUpdate[JsonKey.eventType] is String {
                userUpdate.removeValue(forKey: JsonKey.eventType)
            }
            
            IterableAPI.implementation?.updateUser(userUpdate, mergeNestedObjects: false)
        }
    }
    
    public func clearVisitorEventsAndUserData() {
        localStorage.unknownUserEvents = nil
        localStorage.unknownUserSessions = nil
        localStorage.unknownUserUpdate = nil
    }
    
    /// Gets the unknown user criteria and updates the last criteria fetch time in milliseconds
    public func getUnknownUserCriteria() {
        updateLastCriteriaFetch(currentTime: Date().timeIntervalSince1970 * 1000)
        
        IterableAPI.implementation?.getCriteriaData { returnedData in
            self.localStorage.criteriaData = returnedData
        };
    }
    
    /// Gets the last criteria fetch time in milliseconds
    public func getLastCriteriaFetch() -> Double {
        return lastCriteriaFetch
    }
    
    /// Sets the last criteria fetch time in milliseconds
    public func updateLastCriteriaFetch(currentTime: Double) {
        lastCriteriaFetch = currentTime
    }
    
    /// Creates a user after criterias met and login the user and then sync the data through track APIs
    private func createUnknownUser(_ criteriaId: String) {
        var unknownUserSessions = convertToDictionary(data: localStorage.unknownUserSessions?.itbl_unknown_user_sessions)
        let userId = IterableUtil.generateUUID()
        unknownUserSessions[JsonKey.matchedCriteriaId] = Int(criteriaId)
        let appName = Bundle.main.appPackageName ?? ""
        notificationStateProvider.isNotificationsEnabled { isEnabled in
            if !appName.isEmpty && isEnabled {
                unknownUserSessions[JsonKey.mobilePushOptIn] = appName
            }
           
            //track unknown user session for new user
            IterableAPI.implementation?.apiClient.trackUnknownUserSession(
                createdAt: IterableUtil.secondsFromEpoch(for: self.dateProvider.currentDate),
                withUserId: userId,
                dataFields: self.localStorage.unknownUserUpdate,
                requestJson: unknownUserSessions
            ).onError { error in
                self.isCriteriaMatched = false
                if error.httpStatusCode == 409 {
                    self.getUnknownUserCriteria() // refetch the criteria
                }
            }.onSuccess { success in
                self.localStorage.userIdUnknownUser = userId
                self.config.unknownUserHandler?.onUnknownUserCreated(userId: userId)
                
                IterableAPI.implementation?.setUserId(userId, isUnknownUser: true)
                
                // Send consent data after session creation
                self.sendConsentAfterCriteriaMatch(userId: userId)
                
                self.syncNonSyncedEvents()
            }
        }
    }

    /// Checks if criterias are being met and returns criteriaId if it matches the criteria.
    private func evaluateCriteriaAndReturnID() -> String? {
        guard let criteriaData = localStorage.criteriaData else { return nil }
        
        var events = [[AnyHashable: Any]]()
        
        if let unknownUserEvents = localStorage.unknownUserEvents {
            events.append(contentsOf: unknownUserEvents)
        }
        
        if let userUpdate = localStorage.unknownUserUpdate {
            events.append(userUpdate)
        }
        
        guard events.count > 0 else { return nil }
        
        return CriteriaCompletionChecker(unknownUserCriteria: criteriaData, unknownUserEvents: events).getMatchedCriteria()
    }
    
    /// Stores event data locally
    private func storeEventData(type: String, data: [AnyHashable: Any], shouldOverWrite: Bool = false) {
        // Early return if no AUT consent was given
        if !self.localStorage.visitorUsageTracked {
            ITBInfo("UUA CONSENT NOT GIVEN - no events being stored")
            return
        }
        
        if type == EventType.updateUser {
            processAndStoreUserUpdate(data: data)
        } else {
            processAndStoreEvent(type: type, data: data)
        }
        
        if let criteriaId = evaluateCriteriaAndReturnID(), !isCriteriaMatched {
            isCriteriaMatched = true
            createUnknownUser(criteriaId)
        }
    }
    
    /// Stores User Update data
    private func processAndStoreUserUpdate(data: [AnyHashable: Any]) {
        var userUpdate = localStorage.unknownUserUpdate ?? [:]
        
        // Merge new data into userUpdate
        userUpdate.merge(data) { (_, new) in new }
        
        userUpdate.setValue(for: JsonKey.eventType, value: EventType.updateUser)
        userUpdate.setValue(for: JsonKey.eventTimeStamp, value: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate)) 
        
        localStorage.unknownUserUpdate = userUpdate
    }
    
    /// Stores all other event data
    private func processAndStoreEvent(type: String, data: [AnyHashable: Any]) {
        var eventsDataObjects: [[AnyHashable: Any]] = localStorage.unknownUserEvents ?? []
        
        var newEventData = data
        newEventData.setValue(for: JsonKey.eventType, value: type)
        newEventData.setValue(for: JsonKey.eventTimeStamp, value: IterableUtil.secondsFromEpoch(for: dateProvider.currentDate)) // this we use as unique idenfier too
            
        eventsDataObjects.append(newEventData)
        
        if eventsDataObjects.count > config.eventThresholdLimit {
            eventsDataObjects = eventsDataObjects.suffix(config.eventThresholdLimit)
        }
        
        localStorage.unknownUserEvents = eventsDataObjects
    }
    
    /// Sends consent data after user meets criteria and anonymous user is created
    private func sendConsentAfterCriteriaMatch(userId: String) {
        guard let consentTimestamp = localStorage.visitorConsentTimestamp else {
            ITBInfo("No consent timestamp found, skipping consent tracking")
            return
        }
        
        IterableAPI.implementation?.apiClient.trackConsent(
            consentTimestamp: consentTimestamp,
            email: nil,
            userId: userId,
            isUserKnown: false
        ).onSuccess { _ in
            ITBInfo("Consent tracked successfully for criteria match")
        }.onError { error in
            ITBError("Failed to track consent for criteria match: \(error)")
        }
    }
}
