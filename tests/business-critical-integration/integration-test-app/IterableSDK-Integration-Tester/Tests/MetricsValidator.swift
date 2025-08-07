import Foundation

class MetricsValidator {
    
    // MARK: - Properties
    
    private let apiClient: IterableAPIClient
    private let userEmail: String
    private var expectedEvents: [EventExpectation] = []
    private var validatedEvents: [ValidatedEvent] = []
    
    // Configuration
    private let defaultTimeout: TimeInterval = 60.0
    private let pollInterval: TimeInterval = 3.0
    private let maxRetryAttempts = 20
    
    // MARK: - Initialization
    
    init(apiClient: IterableAPIClient, userEmail: String) {
        self.apiClient = apiClient
        self.userEmail = userEmail
    }
    
    // MARK: - Data Structures
    
    struct EventExpectation {
        let eventType: String
        let expectedCount: Int
        let timeWindow: TimeInterval
        let requiredFields: [String]
        let optionalValidations: [(String, Any) -> Bool]
        let createdAt: Date
        var status: ExpectationStatus = .pending
        
        enum ExpectationStatus {
            case pending
            case validating
            case fulfilled
            case failed(String)
            case timeout
        }
    }
    
    struct ValidatedEvent {
        let eventName: String
        let eventData: [String: Any]
        let timestamp: Date
        let validationResult: ValidationResult
        
        enum ValidationResult {
            case passed
            case failed(String)
            case warning(String)
        }
    }
    
    struct MetricsReport {
        let totalEventsValidated: Int
        let passedValidations: Int
        let failedValidations: Int
        let warningValidations: Int
        let timeWindow: TimeInterval
        let validatedEvents: [ValidatedEvent]
        let unfulfilledExpectations: [EventExpectation]
    }
    
    // MARK: - Event Validation
    
    func validateEventCount(
        eventType: String,
        expectedCount: Int,
        timeout: TimeInterval = 60.0,
        completion: @escaping (Bool, Int) -> Void
    ) {
        let expectation = EventExpectation(
            eventType: eventType,
            expectedCount: expectedCount,
            timeWindow: timeout,
            requiredFields: [],
            optionalValidations: [],
            createdAt: Date()
        )
        
        expectedEvents.append(expectation)
        
        validateEventExpectation(expectation) { [weak self] success, actualCount in
            if success {
                self?.updateExpectationStatus(eventType: eventType, status: .fulfilled)
            } else {
                self?.updateExpectationStatus(eventType: eventType, status: .failed("Expected \(expectedCount), found \(actualCount)"))
            }
            completion(success, actualCount)
        }
    }
    
    func validateEventExists(
        eventType: String,
        requiredFields: [String] = [],
        timeout: TimeInterval = 60.0,
        completion: @escaping (Bool, [String: Any]?) -> Void
    ) {
        let expectation = EventExpectation(
            eventType: eventType,
            expectedCount: 1,
            timeWindow: timeout,
            requiredFields: requiredFields,
            optionalValidations: [],
            createdAt: Date()
        )
        
        expectedEvents.append(expectation)
        
        validateEventExistence(expectation) { [weak self] success, eventData in
            if success {
                self?.updateExpectationStatus(eventType: eventType, status: .fulfilled)
            } else {
                self?.updateExpectationStatus(eventType: eventType, status: .failed("Event not found or missing required fields"))
            }
            completion(success, eventData)
        }
    }
    
    func validateEventWithCustomValidation(
        eventType: String,
        timeout: TimeInterval = 60.0,
        customValidation: @escaping ([String: Any]) -> (Bool, String?),
        completion: @escaping (Bool, String?) -> Void
    ) {
        let expectation = EventExpectation(
            eventType: eventType,
            expectedCount: 1,
            timeWindow: timeout,
            requiredFields: [],
            optionalValidations: [],
            createdAt: Date()
        )
        
        expectedEvents.append(expectation)
        
        validateEventWithCustomLogic(expectation, customValidation: customValidation) { [weak self] success, message in
            if success {
                self?.updateExpectationStatus(eventType: eventType, status: .fulfilled)
            } else {
                self?.updateExpectationStatus(eventType: eventType, status: .failed(message ?? "Custom validation failed"))
            }
            completion(success, message)
        }
    }
    
    // MARK: - Specific Event Type Validations
    
    func validatePushMetrics(
        messageId: String? = nil,
        expectedEventTypes: [String] = ["pushSend", "pushOpen"],
        timeout: TimeInterval = 60.0,
        completion: @escaping (Bool, [String]) -> Void
    ) {
        var foundEvents: [String] = []
        var remainingEvents = expectedEventTypes
        let startTime = Date()
        
        func checkPushEvents() {
            let timeWindow = Date().timeIntervalSince(startTime)
            if timeWindow >= timeout {
                completion(false, foundEvents)
                return
            }
            
            apiClient.getEvents(for: userEmail, startTime: startTime.timeIntervalSince1970 - 300, endTime: Date().timeIntervalSince1970) { success, events in
                if success {
                    let pushEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        
                        // Check if it's a push-related event
                        let isPushEvent = expectedEventTypes.contains { expectedType in
                            eventName.lowercased().contains(expectedType.lowercased())
                        }
                        
                        // If messageId is provided, also check for matching message
                        if let msgId = messageId, isPushEvent {
                            if let eventMessageId = event["messageId"] as? String {
                                return eventMessageId == msgId
                            }
                        }
                        
                        return isPushEvent
                    }
                    
                    // Update found events
                    for event in pushEvents {
                        if let eventName = event["eventName"] as? String {
                            for expectedType in expectedEventTypes {
                                if eventName.lowercased().contains(expectedType.lowercased()) && !foundEvents.contains(expectedType) {
                                    foundEvents.append(expectedType)
                                    remainingEvents.removeAll { $0 == expectedType }
                                }
                            }
                        }
                    }
                    
                    // Record validated events
                    for event in pushEvents {
                        self.recordValidatedEvent(event: event, validationResult: .passed)
                    }
                    
                    if remainingEvents.isEmpty {
                        completion(true, foundEvents)
                    } else {
                        DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                            checkPushEvents()
                        }
                    }
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                        checkPushEvents()
                    }
                }
            }
        }
        
        checkPushEvents()
    }
    
    func validateInAppMessageMetrics(
        expectedEventTypes: [String] = ["inAppOpen", "inAppClick", "inAppClose"],
        timeout: TimeInterval = 60.0,
        completion: @escaping (Bool, [String]) -> Void
    ) {
        validateMessagingMetrics(
            eventPrefix: "inApp",
            expectedEventTypes: expectedEventTypes,
            timeout: timeout,
            completion: completion
        )
    }
    
    func validateEmbeddedMessageMetrics(
        placementId: String? = nil,
        expectedEventTypes: [String] = ["embeddedMessageReceived", "embeddedClick", "embeddedMessageImpression"],
        timeout: TimeInterval = 60.0,
        completion: @escaping (Bool, [String]) -> Void
    ) {
        var foundEvents: [String] = []
        var remainingEvents = expectedEventTypes
        let startTime = Date()
        
        func checkEmbeddedEvents() {
            let timeWindow = Date().timeIntervalSince(startTime)
            if timeWindow >= timeout {
                completion(false, foundEvents)
                return
            }
            
            apiClient.getEvents(for: userEmail, startTime: startTime.timeIntervalSince1970 - 300, endTime: Date().timeIntervalSince1970) { success, events in
                if success {
                    let embeddedEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        
                        let isEmbeddedEvent = expectedEventTypes.contains { expectedType in
                            eventName.lowercased().contains(expectedType.lowercased())
                        }
                        
                        // If placementId is provided, check for matching placement
                        if let placement = placementId, isEmbeddedEvent {
                            if let eventPlacement = event["placementId"] as? String {
                                return eventPlacement == placement
                            }
                        }
                        
                        return isEmbeddedEvent
                    }
                    
                    // Update found events
                    for event in embeddedEvents {
                        if let eventName = event["eventName"] as? String {
                            for expectedType in expectedEventTypes {
                                if eventName.lowercased().contains(expectedType.lowercased()) && !foundEvents.contains(expectedType) {
                                    foundEvents.append(expectedType)
                                    remainingEvents.removeAll { $0 == expectedType }
                                }
                            }
                        }
                    }
                    
                    // Record validated events
                    for event in embeddedEvents {
                        self.recordValidatedEvent(event: event, validationResult: .passed)
                    }
                    
                    if remainingEvents.isEmpty {
                        completion(true, foundEvents)
                    } else {
                        DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                            checkEmbeddedEvents()
                        }
                    }
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                        checkEmbeddedEvents()
                    }
                }
            }
        }
        
        checkEmbeddedEvents()
    }
    
    func validateDeepLinkMetrics(
        deepLinkURL: String? = nil,
        expectedEventTypes: [String] = ["deepLinkClick", "linkClick"],
        timeout: TimeInterval = 60.0,
        completion: @escaping (Bool, [String]) -> Void
    ) {
        var foundEvents: [String] = []
        var remainingEvents = expectedEventTypes
        let startTime = Date()
        
        func checkDeepLinkEvents() {
            let timeWindow = Date().timeIntervalSince(startTime)
            if timeWindow >= timeout {
                completion(false, foundEvents)
                return
            }
            
            apiClient.getEvents(for: userEmail, startTime: startTime.timeIntervalSince1970 - 300, endTime: Date().timeIntervalSince1970) { success, events in
                if success {
                    let deepLinkEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        
                        let isDeepLinkEvent = expectedEventTypes.contains { expectedType in
                            eventName.lowercased().contains(expectedType.lowercased()) ||
                            eventName.lowercased().contains("click") ||
                            eventName.lowercased().contains("link")
                        }
                        
                        // If deepLinkURL is provided, check for matching URL
                        if let url = deepLinkURL, isDeepLinkEvent {
                            if let eventURL = event["url"] as? String {
                                return eventURL.contains(url) || url.contains(eventURL)
                            }
                            if let dataFields = event["dataFields"] as? [String: Any],
                               let eventURL = dataFields["url"] as? String {
                                return eventURL.contains(url) || url.contains(eventURL)
                            }
                        }
                        
                        return isDeepLinkEvent
                    }
                    
                    // Update found events
                    for event in deepLinkEvents {
                        if let eventName = event["eventName"] as? String {
                            for expectedType in expectedEventTypes {
                                if (eventName.lowercased().contains(expectedType.lowercased()) ||
                                    (expectedType.lowercased().contains("click") && eventName.lowercased().contains("click"))) &&
                                   !foundEvents.contains(expectedType) {
                                    foundEvents.append(expectedType)
                                    remainingEvents.removeAll { $0 == expectedType }
                                }
                            }
                        }
                    }
                    
                    // Record validated events
                    for event in deepLinkEvents {
                        self.recordValidatedEvent(event: event, validationResult: .passed)
                    }
                    
                    if remainingEvents.isEmpty {
                        completion(true, foundEvents)
                    } else {
                        DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                            checkDeepLinkEvents()
                        }
                    }
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                        checkDeepLinkEvents()
                    }
                }
            }
        }
        
        checkDeepLinkEvents()
    }
    
    // MARK: - Comprehensive Validation
    
    func validateCompleteWorkflow(
        workflowType: WorkflowType,
        timeout: TimeInterval = 120.0,
        completion: @escaping (Bool, MetricsReport) -> Void
    ) {
        let startTime = Date()
        
        let expectedEvents: [String] = {
            switch workflowType {
            case .pushNotification:
                return ["pushSend", "pushOpen", "pushBounce"].compactMap { $0 }
            case .inAppMessage:
                return ["inAppOpen", "inAppClick", "inAppClose"]
            case .embeddedMessage:
                return ["embeddedMessageReceived", "embeddedMessageImpression", "embeddedClick"]
            case .deepLinking:
                return ["deepLinkClick", "linkClick", "universalLinkOpen"]
            case .fullIntegration:
                return ["pushSend", "pushOpen", "inAppOpen", "embeddedMessageReceived", "deepLinkClick"]
            }
        }()
        
        func validateWorkflowEvents() {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= timeout {
                let report = generateMetricsReport(timeWindow: elapsed)
                completion(false, report)
                return
            }
            
            validateMultipleEventTypes(eventTypes: expectedEvents, timeWindow: elapsed + 300) { [weak self] success, foundEventCounts in
                if success && foundEventCounts.values.allSatisfy({ $0 > 0 }) {
                    let report = self?.generateMetricsReport(timeWindow: elapsed) ?? MetricsReport(
                        totalEventsValidated: 0,
                        passedValidations: 0,
                        failedValidations: 0,
                        warningValidations: 0,
                        timeWindow: elapsed,
                        validatedEvents: [],
                        unfulfilledExpectations: []
                    )
                    completion(true, report)
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(self?.pollInterval ?? 3.0))) {
                        validateWorkflowEvents()
                    }
                }
            }
        }
        
        validateWorkflowEvents()
    }
    
    enum WorkflowType {
        case pushNotification
        case inAppMessage
        case embeddedMessage
        case deepLinking
        case fullIntegration
    }
    
    // MARK: - Helper Methods
    
    private func validateEventExpectation(
        _ expectation: EventExpectation,
        completion: @escaping (Bool, Int) -> Void
    ) {
        let startTime = Date()
        
        func checkEvents() {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= expectation.timeWindow {
                completion(false, 0)
                return
            }
            
            apiClient.validateEventExists(
                userEmail: userEmail,
                eventType: expectation.eventType,
                timeWindow: expectation.timeWindow
            ) { [weak self] success, count in
                if success && count >= expectation.expectedCount {
                    completion(true, count)
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(self?.pollInterval ?? 3.0))) {
                        checkEvents()
                    }
                }
            }
        }
        
        checkEvents()
    }
    
    private func validateEventExistence(
        _ expectation: EventExpectation,
        completion: @escaping (Bool, [String: Any]?) -> Void
    ) {
        let startTime = Date()
        
        func checkEventExists() {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= expectation.timeWindow {
                completion(false, nil)
                return
            }
            
            apiClient.getEvents(
                for: userEmail,
                startTime: startTime.timeIntervalSince1970 - expectation.timeWindow,
                endTime: Date().timeIntervalSince1970
            ) { [weak self] success, events in
                if success {
                    let matchingEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        return eventName.lowercased().contains(expectation.eventType.lowercased())
                    }
                    
                    for event in matchingEvents {
                        // Check required fields
                        var hasAllRequiredFields = true
                        for field in expectation.requiredFields {
                            if event[field] == nil {
                                hasAllRequiredFields = false
                                break
                            }
                        }
                        
                        if hasAllRequiredFields {
                            self?.recordValidatedEvent(event: event, validationResult: .passed)
                            completion(true, event)
                            return
                        }
                    }
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(self?.pollInterval ?? 3.0))) {
                        checkEventExists()
                    }
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(self?.pollInterval ?? 3.0))) {
                        checkEventExists()
                    }
                }
            }
        }
        
        checkEventExists()
    }
    
    private func validateEventWithCustomLogic(
        _ expectation: EventExpectation,
        customValidation: @escaping ([String: Any]) -> (Bool, String?),
        completion: @escaping (Bool, String?) -> Void
    ) {
        let startTime = Date()
        
        func checkEventWithCustomLogic() {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= expectation.timeWindow {
                completion(false, "Timeout reached")
                return
            }
            
            apiClient.getEvents(
                for: userEmail,
                startTime: startTime.timeIntervalSince1970 - expectation.timeWindow,
                endTime: Date().timeIntervalSince1970
            ) { [weak self] success, events in
                if success {
                    let matchingEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        return eventName.lowercased().contains(expectation.eventType.lowercased())
                    }
                    
                    for event in matchingEvents {
                        let (isValid, message) = customValidation(event)
                        if isValid {
                            self?.recordValidatedEvent(event: event, validationResult: .passed)
                            completion(true, message)
                            return
                        } else {
                            self?.recordValidatedEvent(event: event, validationResult: .failed(message ?? "Custom validation failed"))
                        }
                    }
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(self?.pollInterval ?? 3.0))) {
                        checkEventWithCustomLogic()
                    }
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(self?.pollInterval ?? 3.0))) {
                        checkEventWithCustomLogic()
                    }
                }
            }
        }
        
        checkEventWithCustomLogic()
    }
    
    private func validateMessagingMetrics(
        eventPrefix: String,
        expectedEventTypes: [String],
        timeout: TimeInterval,
        completion: @escaping (Bool, [String]) -> Void
    ) {
        var foundEvents: [String] = []
        var remainingEvents = expectedEventTypes
        let startTime = Date()
        
        func checkMessagingEvents() {
            let timeWindow = Date().timeIntervalSince(startTime)
            if timeWindow >= timeout {
                completion(false, foundEvents)
                return
            }
            
            apiClient.getEvents(for: userEmail, startTime: startTime.timeIntervalSince1970 - 300, endTime: Date().timeIntervalSince1970) { success, events in
                if success {
                    let messagingEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        
                        return expectedEventTypes.contains { expectedType in
                            eventName.lowercased().contains(expectedType.lowercased()) ||
                            eventName.lowercased().contains(eventPrefix.lowercased())
                        }
                    }
                    
                    // Update found events
                    for event in messagingEvents {
                        if let eventName = event["eventName"] as? String {
                            for expectedType in expectedEventTypes {
                                if eventName.lowercased().contains(expectedType.lowercased()) && !foundEvents.contains(expectedType) {
                                    foundEvents.append(expectedType)
                                    remainingEvents.removeAll { $0 == expectedType }
                                }
                            }
                        }
                    }
                    
                    // Record validated events
                    for event in messagingEvents {
                        self.recordValidatedEvent(event: event, validationResult: .passed)
                    }
                    
                    if remainingEvents.isEmpty {
                        completion(true, foundEvents)
                    } else {
                        DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                            checkMessagingEvents()
                        }
                    }
                } else {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.pollInterval) {
                        checkMessagingEvents()
                    }
                }
            }
        }
        
        checkMessagingEvents()
    }
    
    private func validateMultipleEventTypes(
        eventTypes: [String],
        timeWindow: TimeInterval,
        completion: @escaping (Bool, [String: Int]) -> Void
    ) {
        apiClient.getEvents(
            for: userEmail,
            startTime: Date().timeIntervalSince1970 - timeWindow,
            endTime: Date().timeIntervalSince1970
        ) { [weak self] success, events in
            if success {
                var eventCounts: [String: Int] = [:]
                
                for eventType in eventTypes {
                    let matchingEvents = events.filter { event in
                        guard let eventName = event["eventName"] as? String else { return false }
                        return eventName.lowercased().contains(eventType.lowercased())
                    }
                    eventCounts[eventType] = matchingEvents.count
                    
                    // Record all matching events
                    for event in matchingEvents {
                        self?.recordValidatedEvent(event: event, validationResult: .passed)
                    }
                }
                
                let allFound = eventCounts.values.allSatisfy { $0 > 0 }
                completion(allFound, eventCounts)
            } else {
                completion(false, [:])
            }
        }
    }
    
    private func recordValidatedEvent(event: [String: Any], validationResult: ValidatedEvent.ValidationResult) {
        let validatedEvent = ValidatedEvent(
            eventName: event["eventName"] as? String ?? "unknown",
            eventData: event,
            timestamp: Date(),
            validationResult: validationResult
        )
        validatedEvents.append(validatedEvent)
    }
    
    private func updateExpectationStatus(eventType: String, status: EventExpectation.ExpectationStatus) {
        for i in 0..<expectedEvents.count {
            if expectedEvents[i].eventType == eventType {
                expectedEvents[i].status = status
                break
            }
        }
    }
    
    private func generateMetricsReport(timeWindow: TimeInterval) -> MetricsReport {
        let passedValidations = validatedEvents.filter {
            if case .passed = $0.validationResult { return true }
            return false
        }.count
        
        let failedValidations = validatedEvents.filter {
            if case .failed = $0.validationResult { return true }
            return false
        }.count
        
        let warningValidations = validatedEvents.filter {
            if case .warning = $0.validationResult { return true }
            return false
        }.count
        
        let unfulfilledExpectations = expectedEvents.filter {
            if case .fulfilled = $0.status { return false }
            return true
        }
        
        return MetricsReport(
            totalEventsValidated: validatedEvents.count,
            passedValidations: passedValidations,
            failedValidations: failedValidations,
            warningValidations: warningValidations,
            timeWindow: timeWindow,
            validatedEvents: validatedEvents,
            unfulfilledExpectations: unfulfilledExpectations
        )
    }
    
    // MARK: - Public Interface
    
    func clearValidationHistory() {
        expectedEvents.removeAll()
        validatedEvents.removeAll()
    }
    
    func getValidationReport() -> MetricsReport {
        return generateMetricsReport(timeWindow: 0)
    }
    
    func getValidatedEvents(ofType eventType: String) -> [ValidatedEvent] {
        return validatedEvents.filter { $0.eventName.lowercased().contains(eventType.lowercased()) }
    }
    
    func hasValidatedEvent(ofType eventType: String) -> Bool {
        return validatedEvents.contains { $0.eventName.lowercased().contains(eventType.lowercased()) }
    }
}