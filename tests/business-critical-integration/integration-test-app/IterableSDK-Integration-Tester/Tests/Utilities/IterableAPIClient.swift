import Foundation

class IterableAPIClient {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let serverKey: String
    private let projectId: String
    private let baseURL: String
    private let session: URLSession
    private var receivedCalls: [String] = []
    
    // Configuration
    private let requestTimeout: TimeInterval = 30.0
    private let retryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    
    // MARK: - Initialization
    
    init(apiKey: String, serverKey: String, projectId: String) {
        self.apiKey = apiKey
        self.serverKey = serverKey
        self.projectId = projectId
        self.baseURL = "https://api.iterable.com"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Call Monitoring
    
    func hasReceivedCall(to endpoint: String) -> Bool {
        return receivedCalls.contains(endpoint)
    }
    
    func clearReceivedCalls() {
        receivedCalls.removeAll()
    }
    
    private func recordAPICall(endpoint: String) {
        receivedCalls.append(endpoint)
    }
    
    // MARK: - User Management
    
    func verifyDeviceRegistration(userEmail: String, completion: @escaping (Bool, String?) -> Void) {
        let endpoint = "/api/users/getByEmail"
        recordAPICall(endpoint: endpoint)
        
        performAPIRequest(
            endpoint: endpoint,
            method: "GET",
            parameters: ["email": userEmail],
            useServerKey: false
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let user = json["user"] as? [String: Any],
                       let devices = user["devices"] as? [[String: Any]] {
                        
                        let deviceToken = devices.first?["token"] as? String
                        completion(devices.count > 0, deviceToken)
                    } else {
                        completion(false, nil)
                    }
                } catch {
                    print("❌ Error parsing device registration response: \(error)")
                    completion(false, nil)
                }
            case .failure(let error):
                print("❌ Error verifying device registration: \(error)")
                completion(false, nil)
            }
        }
    }
    
    func updateUserProfile(email: String, dataFields: [String: Any], completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/users/update"
        recordAPICall(endpoint: endpoint)
        
        let payload: [String: Any] = [
            "email": email,
            "dataFields": dataFields
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("❌ Error updating user profile: \(error)")
                completion(false)
            }
        }
    }
    
    func cleanupTestUser(email: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/users/delete"
        recordAPICall(endpoint: endpoint)
        
        let payload = ["email": email]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("⚠️ Warning: Error cleaning up test user: \(error)")
                completion(true) // Don't fail tests due to cleanup issues
            }
        }
    }
    
    // MARK: - Campaign Management
    
    func createCampaign(payload: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        let endpoint = "/api/campaigns/create"
        recordAPICall(endpoint: endpoint)
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: true
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let campaignId = json?["campaignId"] as? String {
                        completion(true, campaignId)
                    } else if let campaignId = json?["campaignId"] as? Int {
                        completion(true, String(campaignId))
                    } else {
                        completion(false, nil)
                    }
                } catch {
                    print("❌ Error parsing campaign creation response: \(error)")
                    completion(false, nil)
                }
            case .failure(let error):
                print("❌ Error creating campaign: \(error)")
                completion(false, nil)
            }
        }
    }
    
    func deleteCampaign(campaignId: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/campaigns/\(campaignId)"
        recordAPICall(endpoint: endpoint)
        
        performAPIRequest(
            endpoint: endpoint,
            method: "DELETE",
            body: nil,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("⚠️ Warning: Error deleting campaign: \(error)")
                completion(true) // Don't fail tests due to cleanup issues
            }
        }
    }
    
    // MARK: - Push Notifications
    
    func sendPushNotification(to userEmail: String, payload: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        let endpoint = "/api/push/target"
        recordAPICall(endpoint: endpoint)
        
        var pushPayload = payload
        pushPayload["recipientEmail"] = userEmail
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: pushPayload,
            useServerKey: true
        ) { result in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    func sendSilentPush(to userEmail: String, triggerType: String, completion: @escaping (Bool, Error?) -> Void) {
        let payload: [String: Any] = [
            "recipientEmail": userEmail,
            "campaignId": Int.random(in: 10000...99999),
            "dataFields": [
                "silentPush": true,
                "triggerType": triggerType,
                "timestamp": Date().timeIntervalSince1970
            ],
            "sendAt": "immediate",
            "pushPayload": [
                "contentAvailable": true,
                "isGhostPush": true,
                "badge": NSNull(),
                "sound": NSNull(),
                "alert": NSNull()
            ]
        ]
        
        sendPushNotification(to: userEmail, payload: payload, completion: completion)
    }
    
    // MARK: - List Management
    
    func createList(name: String, completion: @escaping (Bool, String?) -> Void) {
        let endpoint = "/api/lists"
        recordAPICall(endpoint: endpoint)
        
        let payload: [String: Any] = [
            "name": name,
            "description": "Integration test list",
            "listType": "Standard"
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let listId = json?["id"] as? String {
                        completion(true, listId)
                    } else if let listId = json?["id"] as? Int {
                        completion(true, String(listId))
                    } else {
                        completion(false, nil)
                    }
                } catch {
                    print("❌ Error parsing list creation response: \(error)")
                    completion(false, nil)
                }
            case .failure(let error):
                print("❌ Error creating list: \(error)")
                completion(false, nil)
            }
        }
    }
    
    func subscribeToList(listId: String, userEmail: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/lists/subscribe"
        recordAPICall(endpoint: endpoint)
        
        let payload: [String: Any] = [
            "listId": Int(listId) ?? 0,
            "subscribers": [
                [
                    "email": userEmail,
                    "dataFields": [
                        "subscribed": true,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                ]
            ]
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("❌ Error subscribing to list: \(error)")
                completion(false)
            }
        }
    }
    
    func unsubscribeFromList(listId: String, userEmail: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/lists/unsubscribe"
        recordAPICall(endpoint: endpoint)
        
        let payload: [String: Any] = [
            "listId": Int(listId) ?? 0,
            "subscribers": [
                ["email": userEmail]
            ]
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("❌ Error unsubscribing from list: \(error)")
                completion(false)
            }
        }
    }
    
    func deleteList(listId: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/lists/\(listId)"
        recordAPICall(endpoint: endpoint)
        
        performAPIRequest(
            endpoint: endpoint,
            method: "DELETE",
            body: nil,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("⚠️ Warning: Error deleting list: \(error)")
                completion(true) // Don't fail tests due to cleanup issues
            }
        }
    }
    
    // MARK: - Event Tracking and Metrics
    
    func getEvents(for userEmail: String, startTime: TimeInterval, endTime: TimeInterval, completion: @escaping (Bool, [[String: Any]]) -> Void) {
        let endpoint = "/api/events/get"
        recordAPICall(endpoint: endpoint)
        
        let parameters: [String: Any] = [
            "email": userEmail,
            "startDateTime": Int(startTime),
            "endDateTime": Int(endTime)
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "GET",
            parameters: parameters,
            useServerKey: false
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let events = json["events"] as? [[String: Any]] {
                        completion(true, events)
                    } else {
                        completion(true, [])
                    }
                } catch {
                    print("❌ Error parsing events response: \(error)")
                    completion(false, [])
                }
            case .failure(let error):
                print("❌ Error getting events: \(error)")
                completion(false, [])
            }
        }
    }
    
    func validateEventExists(userEmail: String, eventType: String, timeWindow: TimeInterval = 300, completion: @escaping (Bool, Int) -> Void) {
        let endTime = Date().timeIntervalSince1970
        let startTime = endTime - timeWindow
        
        getEvents(for: userEmail, startTime: startTime, endTime: endTime) { success, events in
            if success {
                let matchingEvents = events.filter { event in
                    if let eventName = event["eventName"] as? String {
                        return eventName.lowercased().contains(eventType.lowercased())
                    }
                    return false
                }
                completion(true, matchingEvents.count)
            } else {
                completion(false, 0)
            }
        }
    }
    
    // MARK: - In-App Message Management
    
    func getInAppMessages(for userEmail: String, completion: @escaping (Bool, [[String: Any]]) -> Void) {
        let endpoint = "/api/inApp/getMessages"
        recordAPICall(endpoint: endpoint)
        
        let parameters = ["email": userEmail]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "GET",
            parameters: parameters,
            useServerKey: false
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let messages = json["inAppMessages"] as? [[String: Any]] {
                        completion(true, messages)
                    } else {
                        completion(true, [])
                    }
                } catch {
                    print("❌ Error parsing in-app messages response: \(error)")
                    completion(false, [])
                }
            case .failure(let error):
                print("❌ Error getting in-app messages: \(error)")
                completion(false, [])
            }
        }
    }
    
    func clearInAppMessageQueue(for userEmail: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/inApp/target/clear"
        recordAPICall(endpoint: endpoint)
        
        let payload = ["email": userEmail]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("⚠️ Warning: Error clearing in-app message queue: \(error)")
                completion(true) // Don't fail tests due to cleanup issues
            }
        }
    }
    
    // MARK: - Network Request Helpers
    
    private enum APIResult {
        case success(Data)
        case failure(Error)
    }
    
    private func performAPIRequest(
        endpoint: String,
        method: String,
        parameters: [String: Any]? = nil,
        body: [String: Any]? = nil,
        useServerKey: Bool = false,
        completion: @escaping (APIResult) -> Void
    ) {
        var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)")!
        
        // Add query parameters for GET requests
        if let parameters = parameters, method == "GET" {
            urlComponents.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }
        
        guard let url = urlComponents.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Set appropriate API key
        let keyToUse = useServerKey ? serverKey : apiKey
        request.setValue(keyToUse, forHTTPHeaderField: "Api-Key")
        
        // Add body for POST/PUT requests
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        // Perform request with retry logic
        performRequestWithRetry(request: request, completion: completion)
    }
    
    private func performRequestWithRetry(
        request: URLRequest,
        attempt: Int = 1,
        completion: @escaping (APIResult) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                if attempt < self.retryAttempts {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.performRequestWithRetry(request: request, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.invalidResponse))
                return
            }
            
            // Handle rate limiting
            if httpResponse.statusCode == 429 {
                if attempt < self.retryAttempts {
                    let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "5"
                    let delay = TimeInterval(retryAfter) ?? 5.0
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.performRequestWithRetry(request: request, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    completion(.failure(APIError.rateLimited))
                }
                return
            }
            
            // Handle other HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                if attempt < self.retryAttempts && httpResponse.statusCode >= 500 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.performRequestWithRetry(request: request, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    completion(.failure(APIError.httpError(httpResponse.statusCode)))
                }
                return
            }
            
            let responseData = data ?? Data()
            completion(.success(responseData))
        }.resume()
    }
}

// MARK: - API Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .rateLimited:
            return "Rate limited"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}

// MARK: - Extensions

extension IterableAPIClient {
    
    // Convenience method for testing specific event types
    func waitForEvent(userEmail: String, eventType: String, timeout: TimeInterval = 60.0, completion: @escaping (Bool) -> Void) {
        let startTime = Date()
        
        func checkForEvent() {
            validateEventExists(userEmail: userEmail, eventType: eventType) { success, count in
                if success && count > 0 {
                    completion(true)
                } else {
                    let elapsed = Date().timeIntervalSince(startTime)
                    if elapsed < timeout {
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                            checkForEvent()
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        }
        
        checkForEvent()
    }
    
    // Batch operation for creating multiple campaigns
    func createMultipleCampaigns(payloads: [[String: Any]], completion: @escaping ([String]) -> Void) {
        var campaignIds: [String] = []
        let group = DispatchGroup()
        
        for payload in payloads {
            group.enter()
            createCampaign(payload: payload) { success, campaignId in
                if success, let id = campaignId {
                    campaignIds.append(id)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(campaignIds)
        }
    }
    
    // Batch cleanup operation
    func cleanupCampaigns(campaignIds: [String], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var allSucceeded = true
        
        for campaignId in campaignIds {
            group.enter()
            deleteCampaign(campaignId: campaignId) { success in
                if !success {
                    allSucceeded = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(allSucceeded)
        }
    }
}