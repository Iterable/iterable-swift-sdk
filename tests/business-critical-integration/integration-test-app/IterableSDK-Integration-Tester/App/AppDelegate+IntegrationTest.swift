
import UIKit
import UserNotifications
import IterableSDK

// MARK: - AppDelegate Integration Test Extensions

extension AppDelegate {
    
    static func loadApiKeyFromConfig() -> String {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiKey = json["mobileApiKey"] as? String,
              !apiKey.isEmpty else {
            fatalError("❌ Could not load API key from test-config.json")
        }
        print("✅ Loaded API key from test-config.json")
        return apiKey
    }
    
    static func loadTestUserEmailFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["testUserEmail"] as? String,
              !email.isEmpty else {
            fatalError("❌ Could not load test user email from test-config.json")
        }
        print("✅ Loaded test user email from test-config.json")
        return email
    }
    
    static func loadServerKeyFromConfig() -> String {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let serverKey = json["serverApiKey"] as? String,
              !serverKey.isEmpty else {
            fatalError("❌ Could not load server key from test-config.json")
        }
        print("✅ Loaded server key from test-config.json")
        return serverKey
    }

    static func loadJWTApiKeyFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let jwtKey = json["jwtApiKey"] as? String,
              !jwtKey.isEmpty else {
            print("⚠️ No JWT API key found in test-config.json — will use regular API key for JWT testing")
            return nil
        }
        print("✅ Loaded JWT API key from test-config.json")
        return jwtKey
    }

    static func loadJWTSecretFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let jwtSecret = json["jwtSecret"] as? String,
              !jwtSecret.isEmpty else {
            print("⚠️ No JWT secret found in test-config.json")
            return nil
        }
        print("✅ Loaded JWT secret from test-config.json")
        return jwtSecret
    }
    
    static func loadProjectIdFromConfig() -> String {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let projectId = json["projectId"] as? String,
              !projectId.isEmpty else {
            fatalError("❌ Could not load project ID from test-config.json")
        }
        print("✅ Loaded project ID from test-config.json: \(projectId)")
        return projectId
    }
    
    static func loadCIModeFromConfig() -> Bool {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let testing = json["testing"] as? [String: Any],
              let ciMode = testing["ciMode"] as? Bool else {
            print("⚠️ Could not load ciMode from test-config.json, defaulting to false")
            return false
        }
        print("✅ Loaded CI mode from test-config.json: \(ciMode)")
        return ciMode
    }
        
    static func initializeIterableSDK() {
        lastInitMode = .standard
        LogStore.shared.log("🔧 SDK initializing...")
        print("🚀 [SDK INIT] Starting SDK initialization...")
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ [SDK INIT] Failed to get AppDelegate")
            return
        }
        
        print("✅ [SDK INIT] Got AppDelegate instance")
        print("🔍 [SDK INIT] AppDelegate conforms to IterableURLDelegate: \(appDelegate is IterableURLDelegate)")
        print("🔍 [SDK INIT] AppDelegate conforms to IterableCustomActionDelegate: \(appDelegate is IterableCustomActionDelegate)")
        
        // ITBL: Initialize API
        let config = IterableConfig()
        config.customActionDelegate = appDelegate
        config.urlDelegate = appDelegate
        config.inAppDisplayInterval = 1
        config.autoPushRegistration = false  // Disable automatic push registration for testing control
        config.allowedProtocols = ["tester", "https", "http"]  // Allow custom tester:// and https:// deep link schemes
        config.enableEmbeddedMessaging = true
        config.logDelegate = SDKLogCapture.shared

        print("✅ [SDK INIT] Config created with delegates:")
        print("   - URL delegate: \(String(describing: config.urlDelegate))")
        print("   - Custom action delegate: \(String(describing: config.customActionDelegate))")
        print("   - Allowed protocols: \(config.allowedProtocols ?? [])")
        
        let apiKey = loadApiKeyFromConfig()
        print("🔑 [SDK INIT] API key loaded: \(apiKey.prefix(8))...")
        
        print("🚀 [SDK INIT] Calling IterableAPI.initialize...")
        IterableAPI.initialize(apiKey: apiKey,
                               launchOptions: nil,
                               config: config)
        
        print("✅ [SDK INIT] SDK initialized for testing")
        print("✅ [SDK INIT] Initialization complete")
        LogStore.shared.log("✅ SDK initialized")

        // Log remote config values after they've been fetched (async)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let offlineMode = UserDefaults.standard.bool(forKey: "itbl_offline_mode")
            let autoRetry = UserDefaults.standard.bool(forKey: "itbl_auto_retry")
            print("🔄 [SDK INIT] Remote config values - offlineMode: \(offlineMode), autoRetry: \(autoRetry)")
            LogStore.shared.log("⚙️ Config: offlineMode=\(offlineMode), autoRetry=\(autoRetry)")
        }
    }
    
    // MARK: - SDK Init Mode Tracking

    enum SDKInitMode {
        case standard
        case jwt
    }

    static var lastInitMode: SDKInitMode = .standard

    /// Reinitialize the SDK using the same mode it was last initialized with.
    static func reinitializeSDKWithCurrentMode() {
        switch lastInitMode {
        case .standard:
            initializeIterableSDK()
        case .jwt:
            reinitializeSDKWithJWTOnly()
        }
    }

    // MARK: - JWT Auth Testing

    static var mockAuthDelegate: MockAuthDelegate?
    static var currentTestEmail: String?

    /// Initialize SDK with JWT auth but no email — user will login separately.
    static func reinitializeSDKWithJWTOnly() {
        reinitializeSDKWithMockJWT(email: nil)
    }

    static func reinitializeSDKWithMockJWT(email: String?) {
        lastInitMode = .jwt
        // Set email so the auth delegate can generate a JWT when SDK requests one.
        currentTestEmail = email

        LogStore.shared.log("🔧 SDK reinitializing with JWT auth...")
        print("[SDK INIT] Reinitializing SDK with JWT auth delegate...")

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("[SDK INIT] Failed to get AppDelegate")
            return
        }

        guard let jwtSecret = loadJWTSecretFromConfig(), !jwtSecret.isEmpty else {
            print("[SDK INIT] No JWT secret in test-config.json — cannot generate tokens")
            return
        }

        let config = IterableConfig()
        config.customActionDelegate = appDelegate
        config.urlDelegate = appDelegate
        config.inAppDisplayInterval = 1
        config.autoPushRegistration = false
        config.allowedProtocols = ["tester", "https", "http"]
        config.enableEmbeddedMessaging = true
        config.expiringAuthTokenRefreshPeriod = 1.0 // refresh 1s before expiry
        config.logDelegate = SDKLogCapture.shared

        // Set up auth delegate that generates real JWTs locally
        let authDelegate = MockAuthDelegate(jwtSecret: jwtSecret)
        config.authDelegate = authDelegate
        mockAuthDelegate = authDelegate

        let apiKey = loadJWTApiKeyFromConfig() ?? loadApiKeyFromConfig()

        // Activate mock server BEFORE init so requests route through it. Depending
        // on `apiResponseMode` the protocol will either proxy to the real Iterable
        // API (.normal / .jwt401) or synthesize locally (.server500 / .connectionError).
        MockAPIServer.shared.jwtSecret = jwtSecret
        MockAPIServer.shared.activate()

        IterableAPI.initialize(apiKey: apiKey, launchOptions: nil, config: config)

        // Only set email if provided — otherwise user will login separately
        if let email = email {
            // Force a clean login: clear any stale email first so setEmail
            // doesn't early-return when the same email is already persisted.
            IterableAPI.email = nil
            IterableAPI.email = email
        }

        print("[SDK INIT] Reinitialized with JWT auth (secret: \(jwtSecret.prefix(4))...)")
        LogStore.shared.log("✅ SDK initialized with JWT auth")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let offlineMode = UserDefaults.standard.bool(forKey: "itbl_offline_mode")
            let autoRetry = UserDefaults.standard.bool(forKey: "itbl_auto_retry")
            print("[SDK INIT] Remote config values - offlineMode: \(offlineMode), autoRetry: \(autoRetry)")
        }
    }

    static func registerEmailToIterableSDK(email: String) {
        print("📧 [SDK INIT] Registering email with SDK: \(email)")
        IterableAPI.email = email
        LogStore.shared.log("📧 Email set: \(email)")
        print("✅ [SDK INIT] Test user email configured: \(email)")
        print("🔍 [SDK INIT] IterableAPI.email is now: \(IterableAPI.email ?? "nil")")
    }
    
    static func registerUserIDToIterableSDK(userId: String) {
        IterableAPI.userId = userId
        print("✅ Test user id configured: \(userId)")
    }
    
    static func logoutFromIterableSDK() {
        // This will clear email, userId, and authToken from keychain
        IterableAPI.logoutUser()
        
        // Also clear device token from UserDefaults and reset session flag
        clearDeviceToken()
        hasReceivedTokenInCurrentSession = false
        
        print("✅ User logged out - keychain and device token cleared")
    }
    
    // CI Environment Detection
    static var isRunningInCI: Bool {
        // Check config file (updated by script)
        let isCI = loadCIModeFromConfig()
        
        if isCI {
            print("🤖 [APP] CI ENVIRONMENT DETECTED - Mock push notifications enabled")
        } else {
            print("📱 [APP] LOCAL ENVIRONMENT DETECTED - Real APNS push notifications enabled")
        }
        
        return isCI
    }
    
    static func registerForPushNotifications() {
        print("🔔 Requesting push notification authorization...")
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Push notification authorization error: \(error.localizedDescription)")
                    return
                }
                
                if granted {
                    print("✅ Push notification authorization granted")
                    
                    // Check if running in CI environment
                    if isRunningInCI {
                        print("🤖 [APP] CI MODE: Generating mock device token instead of real APNS registration")
                        // Generate a fake device token for CI
                        let mockTokenString = generateMockDeviceToken()
                        let mockTokenData = mockTokenString.hexStringToData()
                        
                        print("🎭 [APP] Mock device token created: \(mockTokenString)")
                        print("🔄 [APP] Simulating device token registration callback in 3 seconds...")
                        
                        // Simulate the device token registration callback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            print("📞 [APP] Triggering mock didRegisterForRemoteNotificationsWithDeviceToken callback")
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                appDelegate.application(UIApplication.shared, didRegisterForRemoteNotificationsWithDeviceToken: mockTokenData)
                            }
                        }
                    } else {
                        print("📱 [APP] LOCAL MODE: Registering for real APNS push notifications")
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Push notification authorization denied")
                }
            }
        }
    }
    
    // Generate a realistic fake device token for CI
    private static func generateMockDeviceToken() -> String {
        // Generate a 64-byte (128 character) hex token similar to real device tokens
        let mockToken = (0..<64).map { _ in String(format: "%02x", Int.random(in: 0...255)) }.joined()
        print("🎭 [APP] Generated 64-byte mock device token for CI testing: \(mockToken)")
        return mockToken
    }
    
    // MARK: - Device Token Management
    
    // Session-based flag to track if we received a token in current app session
    private static var hasReceivedTokenInCurrentSession = false
    
    static func registerDeviceToken(_ deviceToken: Data) {
        // Save device token to UserDefaults for later retrieval
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenString, forKey: "IterableDeviceToken")
        UserDefaults.standard.set(Date(), forKey: "IterableDeviceTokenTimestamp")
        
        // Mark that we received a token in this session
        hasReceivedTokenInCurrentSession = true
        
        // Register with Iterable SDK
            IterableAPI.register(token: deviceToken)

        print("✅ Device token registered and saved: \(tokenString)")
    }
    
    static func getRegisteredDeviceToken() -> String? {
        return UserDefaults.standard.string(forKey: "IterableDeviceToken")
    }
    
    static func getDeviceTokenTimestamp() -> Date? {
        return UserDefaults.standard.object(forKey: "IterableDeviceTokenTimestamp") as? Date
    }
    
    static func clearDeviceToken() {
        UserDefaults.standard.removeObject(forKey: "IterableDeviceToken")
        UserDefaults.standard.removeObject(forKey: "IterableDeviceTokenTimestamp")
        hasReceivedTokenInCurrentSession = false
        print("🗑️ Device token cleared from UserDefaults")
    }
    
    /// Returns true only if we received a device token in the current app session
    static func hasValidDeviceTokenInCurrentSession() -> Bool {
        return hasReceivedTokenInCurrentSession && getRegisteredDeviceToken() != nil
    }
    
    /// Reset the session state on app launch to ensure clean testing
    static func resetDeviceTokenSessionState() {
        hasReceivedTokenInCurrentSession = false
        print("🔄 Device token session state reset on app launch")
    }
    
}

// MARK: - String Extensions for Mock Token Conversion

extension String {
    func hexStringToData() -> Data {
        let hex = self.replacingOccurrences(of: " ", with: "")
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            index = nextIndex
        }
        return data
    }
}
