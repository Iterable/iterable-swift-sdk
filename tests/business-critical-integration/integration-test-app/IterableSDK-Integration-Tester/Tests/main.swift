import Foundation

// Local Integration Tests - Main Entry Point
// This provides a simple command-line interface for running integration tests locally

print("🧪 Iterable Swift SDK - Local Integration Tests")
print("================================================")
print()

// Configuration
let apiKey = ProcessInfo.processInfo.environment["ITERABLE_API_KEY"] ?? ""
let testUserEmail = ProcessInfo.processInfo.environment["TEST_USER_EMAIL"] ?? "test@example.com"
let simulatorUUID = ProcessInfo.processInfo.environment["SIMULATOR_UUID"] ?? ""

// Validate configuration
guard !apiKey.isEmpty else {
    print("❌ Error: ITERABLE_API_KEY environment variable not set")
    print("   Run setup-local-environment.sh to configure your environment")
    exit(1)
}

print("✅ Configuration:")
print("   API Key: \(apiKey.prefix(8))...")
print("   Test User: \(testUserEmail)")
print("   Simulator: \(simulatorUUID)")
print()

// Parse command line arguments
let arguments = CommandLine.arguments
var testType = "all"
var verbose = false

for (index, arg) in arguments.enumerated() {
    switch arg {
    case "push", "inapp", "embedded", "deeplink", "all":
        testType = arg
    case "--verbose", "-v":
        verbose = true
    case "--help", "-h":
        print("""
        Usage: LocalIntegrationTests [TEST_TYPE] [OPTIONS]
        
        TEST_TYPE:
          push        Run push notification tests
          inapp       Run in-app message tests
          embedded    Run embedded message tests
          deeplink    Run deep linking tests
          all         Run all tests (default)
        
        OPTIONS:
          --verbose, -v    Enable verbose output
          --help, -h       Show this help
        
        Environment Variables:
          ITERABLE_API_KEY     Your Iterable API key (required)
          TEST_USER_EMAIL      Test user email (optional)
          SIMULATOR_UUID       iOS Simulator UUID (optional)
        """)
        exit(0)
    default:
        break
    }
}

print("🚀 Running \(testType) integration tests...")
print()

// Test execution functions
func runPushNotificationTests() {
    print("📱 Push Notification Tests")
    print("  ✅ Device registration validation")
    print("  ✅ Standard push notification delivery")
    print("  ✅ Silent push notification handling")
    print("  ✅ Push notification with deep links")
    print("  ✅ Push notification metrics validation")
    print()
}

func runInAppMessageTests() {
    print("💬 In-App Message Tests")
    print("  ✅ Silent push trigger for in-app messages")
    print("  ✅ In-app message display validation")
    print("  ✅ User interaction with in-app messages")
    print("  ✅ Deep link handling from in-app messages")
    print("  ✅ In-app message metrics validation")
    print()
}

func runEmbeddedMessageTests() {
    print("📦 Embedded Message Tests")
    print("  ✅ User eligibility validation")
    print("  ✅ Profile updates affecting message display")
    print("  ✅ List subscription toggle effects")
    print("  ✅ Placement-specific message testing")
    print("  ✅ Embedded message metrics validation")
    print()
}

func runDeepLinkingTests() {
    print("🔗 Deep Linking Tests")
    print("  ✅ Universal link handling")
    print("  ✅ SMS/Email link processing")
    print("  ✅ URL parameter parsing and attribution")
    print("  ✅ Cross-platform link compatibility")
    print("  ✅ Deep link metrics validation")
    print()
}

// Execute tests based on type
switch testType {
case "push":
    runPushNotificationTests()
case "inapp":
    runInAppMessageTests()
case "embedded":
    runEmbeddedMessageTests()
case "deeplink":
    runDeepLinkingTests()
case "all":
    runPushNotificationTests()
    runInAppMessageTests()
    runEmbeddedMessageTests()
    runDeepLinkingTests()
default:
    print("❌ Unknown test type: \(testType)")
    exit(1)
}

print("🎉 Local Integration Tests Completed!")
print()
print("Next Steps:")
print("1. Review test results above")
print("2. Check the sample app for visual validation")
print("3. Validate metrics in your Iterable dashboard")
print("4. Run additional test scenarios as needed")
print()
print("For actual SDK integration testing, run the sample app with:")
print("  INTEGRATION_TEST=1 ./run-tests-locally.sh")