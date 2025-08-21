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
        
        // Create URLSession for backend requests (will be monitored)
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
        // Use the same endpoint as getUserByEmail to get consistent structure
        let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userEmail
        let endpoint = "/api/users/\(encodedEmail)"
        recordAPICall(endpoint: endpoint)
        
        performAPIRequest(
            endpoint: endpoint,
            method: "GET",
            body: nil,
            useServerKey: true
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let user = json["user"] as? [String: Any],
                       let dataFields = user["dataFields"] as? [String: Any],
                       let devices = dataFields["devices"] as? [[String: Any]] {
                        
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
    
    func getTestUserDetails(completion: @escaping (Bool, [String: Any]?) -> Void) {
        guard let testUserEmail = AppDelegate.loadTestUserEmailFromConfig() else {
            print("❌ Could not load test user email from config")
            completion(false, nil)
            return
        }
        
        print("🔍 Getting details for test user: \(testUserEmail)")
        
        // Use the /api/users/getByEmail endpoint to get specific user details
        getUserByEmail(email: testUserEmail, completion: completion)
    }
    
    private func getUserByEmail(email: String, completion: @escaping (Bool, [String: Any]?) -> Void) {
        // URL encode the email to handle special characters
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
        let endpoint = "/api/users/\(encodedEmail)"
        recordAPICall(endpoint: endpoint)
        
        performAPIRequest(
            endpoint: endpoint,
            method: "GET", 
            body: nil,
            useServerKey: true
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let user = json["user"] as? [String: Any],
                       let dataFields = user["dataFields"] as? [String: Any] {
                        
                        // Create a flattened user object that combines user info and dataFields
                        var flattenedUser: [String: Any] = [:]
                        
                        // Add basic user info
                        flattenedUser["email"] = user["email"]
                        
                        // Add dataFields content
                        for (key, value) in dataFields {
                            flattenedUser[key] = value
                        }
                        
                        // Handle devices specifically - they're in dataFields
                        if let devices = dataFields["devices"] as? [[String: Any]] {
                            flattenedUser["devices"] = devices
                        }
                        
                        completion(true, flattenedUser)
                    } else {
                        print("❌ Error: Expected JSON structure with user.dataFields not found")
                        completion(false, nil)
                    }
                } catch {
                    print("❌ Error parsing user response: \(error)")
                    completion(false, nil)
                }
            case .failure(let error):
                print("❌ Error getting user by email: \(error)")
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
    
    func disableAllUserDevices(email: String, completion: @escaping (Bool, Int) -> Void) {
        // First get all devices for the user
        getUserDevices(email: email) { [weak self] devices in
            guard let self = self, let devices = devices, !devices.isEmpty else {
                print("ℹ️ No devices found for user: \(email)")
                completion(true, 0)
                return
            }
            
            print("📱 Found \(devices.count) device(s) to disable for user: \(email)")
            
            let dispatchGroup = DispatchGroup()
            var successCount = 0
            var failureCount = 0
            
            for device in devices {
                if let token = device["token"] as? String {
                    dispatchGroup.enter()
                    self.disableDevice(email: email, token: token) { success in
                        if success {
                            successCount += 1
                            print("✅ Disabled device: \(String(token.prefix(16)))...")
                        } else {
                            failureCount += 1
                            print("❌ Failed to disable device: \(String(token.prefix(16)))...")
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                let totalDevices = successCount + failureCount
                print("📊 Device disable results: \(successCount)/\(totalDevices) successful")
                completion(failureCount == 0, successCount)
            }
        }
    }
    
    func reenableAllUserDevices(email: String, completion: @escaping (Bool, Int) -> Void) {
        // First get all devices for the user
        getUserDevices(email: email) { [weak self] devices in
            guard let self = self, let devices = devices, !devices.isEmpty else {
                print("ℹ️ No devices found for user: \(email)")
                completion(true, 0)
                return
            }
            
            // Filter for disabled devices only
            let disabledDevices = devices.filter { device in
                let endpointEnabled = device["endpointEnabled"] as? Bool ?? false
                let notificationsEnabled = device["notificationsEnabled"] as? Bool ?? false
                return !endpointEnabled || !notificationsEnabled
            }
            
            guard !disabledDevices.isEmpty else {
                print("ℹ️ No disabled devices found for user: \(email)")
                completion(true, 0)
                return
            }
            
            print("📱 Found \(disabledDevices.count) disabled device(s) to re-enable for user: \(email)")
            
            let dispatchGroup = DispatchGroup()
            var successCount = 0
            var failureCount = 0
            
            for device in disabledDevices {
                if let token = device["token"] as? String {
                    dispatchGroup.enter()
                    self.enableDevice(email: email, token: token) { success in
                        if success {
                            successCount += 1
                            print("✅ Re-enabled device: \(String(token.prefix(16)))...")
                        } else {
                            failureCount += 1
                            print("❌ Failed to re-enable device: \(String(token.prefix(16)))...")
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                let totalDevices = successCount + failureCount
                print("📊 Device re-enable results: \(successCount)/\(totalDevices) successful")
                completion(failureCount == 0, successCount)
            }
        }
    }
    
    private func getUserDevices(email: String, completion: @escaping ([[String: Any]]?) -> Void) {
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
        let endpoint = "/api/users/\(encodedEmail)"
        
        performAPIRequest(
            endpoint: endpoint,
            method: "GET",
            body: nil,
            useServerKey: true
        ) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let user = json["user"] as? [String: Any],
                       let dataFields = user["dataFields"] as? [String: Any],
                       let devices = dataFields["devices"] as? [[String: Any]] {
                        completion(devices)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("❌ Error parsing user devices: \(error)")
                    completion(nil)
                }
            case .failure(let error):
                print("❌ Error fetching user devices: \(error)")
                completion(nil)
            }
        }
    }
    
    private func disableDevice(email: String, token: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/users/disableDevice"
        recordAPICall(endpoint: endpoint)
        
        let payload: [String: Any] = [
            "email": email,
            "token": token
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false  // Use mobile API key instead of server key
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("❌ Error disabling device: \(error)")
                completion(false)
            }
        }
    }
    
    private func enableDevice(email: String, token: String, completion: @escaping (Bool) -> Void) {
        let endpoint = "/api/users/registerDeviceToken"
        recordAPICall(endpoint: endpoint)
        
        let payload: [String: Any] = [
            "email": email,
            "device": [
                "token": token,
                "platform": "APNS_SANDBOX", // Default to sandbox for testing
                "applicationName": "com.sumeru.IterableSDK-Integration-Tester",
                "dataFields": [:]
            ]
        ]
        
        performAPIRequest(
            endpoint: endpoint,
            method: "POST",
            body: payload,
            useServerKey: false  // Use mobile API key
        ) { result in
            switch result {
            case .success(_):
                completion(true)
            case .failure(let error):
                print("❌ Error enabling device: \(error)")
                completion(false)
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
            "campaignId": 14679102,
            "allowRepeatMarketingSends": true,
            "dataFields": [:],
            "metadata": [:]
        ]
        
        sendPushNotification(to: userEmail, payload: payload, completion: completion)
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
