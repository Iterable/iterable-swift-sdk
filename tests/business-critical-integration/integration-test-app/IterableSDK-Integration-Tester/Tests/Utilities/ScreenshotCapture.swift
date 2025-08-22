import Foundation
import XCTest

class ScreenshotCapture {
    
    // MARK: - Properties
    
    private let testCase: XCTestCase
    private var screenshotCounter = 0
    private let screenshotDirectory: URL
    
    // MARK: - Initialization
    
    init(testCase: XCTestCase) {
        self.testCase = testCase
        
        // Create screenshots directory in the project's screenshots folder
        // Check for SCREENSHOTS_DIR environment variable first, then use project path
        var screenshotsPath: String
        
        if let envPath = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] {
            screenshotsPath = envPath
        } else {
            // Use project screenshots directory
            screenshotsPath = "/Users/sumeru.chatterjee/Projects/swift-sdk/tests/business-critical-integration/screenshots"
        }
        
        let projectURL = URL(fileURLWithPath: screenshotsPath)
        
        // Check if we can write to the project screenshots directory
        if FileManager.default.fileExists(atPath: screenshotsPath) || 
           (try? FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)) != nil {
            self.screenshotDirectory = projectURL
        } else {
            // Fallback to documents directory
            print("⚠️ Cannot write to project screenshots directory, using Documents folder")
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.screenshotDirectory = documentsPath.appendingPathComponent("Screenshots")
        }
        
        // Create the directory if it doesn't exist
        try? FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
        
        print("📸 Screenshot capture initialized. Saving to: \(screenshotDirectory.path)")
    }
    
    // MARK: - Screenshot Capture
    
    func captureScreenshot(named name: String) {
        screenshotCounter += 1
        
        let timestamp = DateFormatter().apply {
            $0.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        }.string(from: Date())
        
        let filename = "\(String(format: "%03d", screenshotCounter))_\(name)_\(timestamp).png"
        
        // Capture screenshot using XCTest
        let screenshot = XCUIScreen.main.screenshot()
        
        // Save to documents directory
        let fileURL = screenshotDirectory.appendingPathComponent(filename)
        
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("📸 Screenshot saved: \(filename)")
            
            // Also attach to test results for Xcode
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            testCase.add(attachment)
            
        } catch {
            print("❌ Failed to save screenshot \(filename): \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    func getScreenshotsDirectory() -> URL {
        return screenshotDirectory
    }
    
    func clearScreenshots() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: screenshotDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            screenshotCounter = 0
            print("📸 Screenshots cleared")
        } catch {
            print("❌ Failed to clear screenshots: \(error)")
        }
    }
    
    func getScreenshotCount() -> Int {
        return screenshotCounter
    }
}

// MARK: - Extension for Fluent API

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}
