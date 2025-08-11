
import UIKit
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
    
}
