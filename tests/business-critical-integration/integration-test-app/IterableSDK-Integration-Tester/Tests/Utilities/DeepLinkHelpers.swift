import XCTest
import Foundation

// MARK: - Alert Expectation

struct AlertExpectation {
    let title: String
    let message: String?
    let messageContains: String?
    let timeout: TimeInterval
    
    init(title: String, message: String? = nil, messageContains: String? = nil, timeout: TimeInterval = 10.0) {
        self.title = title
        self.message = message
        self.messageContains = messageContains
        self.timeout = timeout
    }
}

// MARK: - Deep Link Test Helper

class DeepLinkTestHelper {
    
    private let app: XCUIApplication
    private let testCase: XCTestCase
    
    // MARK: - Initialization
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        self.testCase = testCase
    }
    
    // MARK: - Alert Validation
    
    /// Wait for an alert to appear and validate its content
    func waitForAlert(_ expectation: AlertExpectation) -> Bool {
        let alert = app.alerts[expectation.title]
        
        guard alert.waitForExistence(timeout: expectation.timeout) else {
            print("❌ Alert '\(expectation.title)' did not appear within \(expectation.timeout) seconds")
            return false
        }
        
        print("✅ Alert '\(expectation.title)' appeared")
        
        // Validate message if specified
        if let expectedMessage = expectation.message {
            let messageElement = alert.staticTexts.element(boundBy: 1)
            if messageElement.label != expectedMessage {
                print("❌ Alert message mismatch. Expected: '\(expectedMessage)', Got: '\(messageElement.label)'")
                return false
            }
            print("✅ Alert message matches: '\(expectedMessage)'")
        }
        
        // Validate message contains substring if specified
        if let containsText = expectation.messageContains {
            let messageElement = alert.staticTexts.element(boundBy: 1)
            if !messageElement.label.contains(containsText) {
                print("❌ Alert message does not contain '\(containsText)'. Got: '\(messageElement.label)'")
                return false
            }
            print("✅ Alert message contains: '\(containsText)'")
        }
        
        return true
    }
    
    /// Dismiss an alert if it's present
    func dismissAlertIfPresent(withTitle title: String, buttonTitle: String = "OK") {
        let alert = app.alerts[title]
        if alert.exists {
            let okButton = alert.buttons[buttonTitle]
            if okButton.exists {
                okButton.tap()
                print("✅ Dismissed alert '\(title)'")
            } else {
                print("⚠️ Alert '\(title)' exists but '\(buttonTitle)' button not found")
            }
        }
    }
    
    /// Wait for alert to dismiss
    func waitForAlertToDismiss(_ title: String, timeout: TimeInterval = 5.0) -> Bool {
        let alert = app.alerts[title]
        let notExistsPredicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: notExistsPredicate, object: alert)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        if result == .completed {
            print("✅ Alert '\(title)' dismissed")
            return true
        } else {
            print("❌ Alert '\(title)' did not dismiss within \(timeout) seconds")
            return false
        }
    }
    
    /// Compare alert content with expected values
    func validateAlertContent(title: String, expectedMessage: String) -> Bool {
        let alert = app.alerts[title]
        
        guard alert.exists else {
            print("❌ Alert '\(title)' does not exist")
            return false
        }
        
        let messageElement = alert.staticTexts.element(boundBy: 1)
        let actualMessage = messageElement.label
        
        if actualMessage == expectedMessage {
            print("✅ Alert message matches expected: '\(expectedMessage)'")
            return true
        } else {
            print("❌ Alert message mismatch")
            print("   Expected: '\(expectedMessage)'")
            print("   Actual: '\(actualMessage)'")
            return false
        }
    }
    
    // MARK: - URL Validation
    
    /// Extract URL from alert message
    func extractURLFromAlert(title: String) -> URL? {
        let alert = app.alerts[title]
        
        guard alert.exists else {
            print("❌ Alert '\(title)' does not exist")
            return nil
        }
        
        let messageElement = alert.staticTexts.element(boundBy: 1)
        let message = messageElement.label
        
        // Try to find URL in the message
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: message, range: NSRange(message.startIndex..., in: message))
        
        if let match = matches?.first, let url = match.url {
            print("✅ Extracted URL from alert: \(url.absoluteString)")
            return url
        }
        
        print("❌ No URL found in alert message: '\(message)'")
        return nil
    }
    
    /// Validate URL components
    func validateURL(_ url: URL, expectedScheme: String? = nil, expectedHost: String? = nil, expectedPath: String? = nil) -> Bool {
        var isValid = true
        
        if let expectedScheme = expectedScheme {
            if url.scheme != expectedScheme {
                print("❌ URL scheme mismatch. Expected: '\(expectedScheme)', Got: '\(url.scheme ?? "nil")'")
                isValid = false
            } else {
                print("✅ URL scheme matches: '\(expectedScheme)'")
            }
        }
        
        if let expectedHost = expectedHost {
            if url.host != expectedHost {
                print("❌ URL host mismatch. Expected: '\(expectedHost)', Got: '\(url.host ?? "nil")'")
                isValid = false
            } else {
                print("✅ URL host matches: '\(expectedHost)'")
            }
        }
        
        if let expectedPath = expectedPath {
            if url.path != expectedPath {
                print("❌ URL path mismatch. Expected: '\(expectedPath)', Got: '\(url.path)'")
                isValid = false
            } else {
                print("✅ URL path matches: '\(expectedPath)'")
            }
        }
        
        return isValid
    }
    
    /// Compare two URLs
    func compareURLs(_ url1: URL, _ url2: URL) -> URLComparisonResult {
        let result = URLComparisonResult(
            url1: url1,
            url2: url2,
            schemeMatches: url1.scheme == url2.scheme,
            hostMatches: url1.host == url2.host,
            pathMatches: url1.path == url2.path,
            queryMatches: url1.query == url2.query
        )
        
        if result.isFullMatch {
            print("✅ URLs match completely")
        } else {
            print("⚠️ URL comparison result:")
            print("   Scheme: \(result.schemeMatches ? "✓" : "✗")")
            print("   Host: \(result.hostMatches ? "✓" : "✗")")
            print("   Path: \(result.pathMatches ? "✓" : "✗")")
            print("   Query: \(result.queryMatches ? "✓" : "✗")")
        }
        
        return result
    }
}

// MARK: - URL Comparison Result

struct URLComparisonResult {
    let url1: URL
    let url2: URL
    let schemeMatches: Bool
    let hostMatches: Bool
    let pathMatches: Bool
    let queryMatches: Bool
    
    var isFullMatch: Bool {
        return schemeMatches && hostMatches && pathMatches && queryMatches
    }
    
    var matchPercentage: Double {
        let matches = [schemeMatches, hostMatches, pathMatches, queryMatches].filter { $0 }.count
        return Double(matches) / 4.0
    }
}
