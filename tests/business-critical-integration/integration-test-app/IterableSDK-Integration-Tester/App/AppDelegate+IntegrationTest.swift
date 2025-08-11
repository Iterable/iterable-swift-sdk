
import UIKit
import IterableSDK

// MARK: - AppDelegate Integration Test Extensions

extension AppDelegate {
    
    // ITBL: Load API key from test config file
    private static func getIterableApiKey () -> String {
        guard let configApiKey = loadApiKeyFromConfig() else {
            fatalError("❌ Required test-config.json file not found or missing mobileApiKey")
        }
        return configApiKey
    }
    
    private static func loadApiKeyFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let apiKey = json["mobileApiKey"] as? String,
              !apiKey.isEmpty else {
            print("❌ Could not load API key from test-config.json")
            return nil
        }
        print("✅ Loaded API key from test-config.json")
        return apiKey
    }
    
    private static func loadTestUserEmailFromConfig() -> String? {
        guard let path = Bundle.main.path(forResource: "test-config", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["testUserEmail"] as? String,
              !email.isEmpty else {
            print("❌ Could not load test user email from test-config.json")
            return nil
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
        
        let apiKey = getIterableApiKey()
        IterableAPI.initialize(apiKey: apiKey,
                               launchOptions: nil,
                               config: config)
        
        print("✅ SDK initialized for testing")
    }
    
    static func addTestUserForTesting() {
        // Set user email from test config
        guard let email = AppDelegate.loadTestUserEmailFromConfig() else {
            print("❌ Failed to load test user email from config")
            return
        }
        
        IterableAPI.email = email
        print("✅ Test user configured: \(email)")
    }
    
}
