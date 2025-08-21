
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
        
    static func initializeIterableSDK() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ Failed to get AppDelegate")
            return
        }
        
        // ITBL: Initialize API
        let config = IterableConfig()
        config.customActionDelegate = appDelegate
        config.urlDelegate = appDelegate
        config.inAppDisplayInterval = 1
        
        let apiKey = loadApiKeyFromConfig()
        IterableAPI.initialize(apiKey: apiKey,
                               launchOptions: nil,
                               config: config)
        
        print("✅ SDK initialized for testing")
    }
    
    static func registerEmailToIterableSDK(email: String) {
        IterableAPI.email = email
        print("✅ Test user email configured: \(email)")
    }
    
    static func registerUserIDToIterableSDK(userId: String) {
        IterableAPI.userId = userId
        print("✅ Test user id configured: \(userId)")
    }
    
    static func logoutFromIterableSDK() {
        // This will clear email, userId, and authToken from keychain
        IterableAPI.logoutUser()
        print("✅ User logged out - keychain cleared")
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
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ Push notification authorization denied")
                }
            }
        }
    }
    
    // MARK: - Device Token Management
    
    static func registerDeviceToken(_ deviceToken: Data) {
        // Save device token to UserDefaults for later retrieval
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenString, forKey: "IterableDeviceToken")
        UserDefaults.standard.set(Date(), forKey: "IterableDeviceTokenTimestamp")
        
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
        print("🗑️ Device token cleared from UserDefaults")
    }
    
}
