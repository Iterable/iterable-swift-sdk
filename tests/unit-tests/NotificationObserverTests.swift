import XCTest
@testable import IterableSDK

class NotificationObserverTests: XCTestCase {
    private var internalAPI: InternalIterableAPI!
    private var mockNotificationStateProvider: MockNotificationStateProvider!
    private var mockLocalStorage: MockLocalStorage!
    private var mockNotificationCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        
        mockNotificationStateProvider = MockNotificationStateProvider(enabled: false)
        mockLocalStorage = MockLocalStorage()
        mockNotificationCenter = MockNotificationCenter()
        
        let config = IterableConfig()
        internalAPI = InternalIterableAPI.initializeForTesting(
            config: config,
            notificationStateProvider: mockNotificationStateProvider,
            localStorage: mockLocalStorage,
            notificationCenter: mockNotificationCenter
        )
    }
    
    func testNotificationStateChangeUpdatesStorage() {
        // Arrange
        internalAPI.email = "johnappleseed@iterable.com"
        
        mockLocalStorage.isNotificationsEnabled = false
        mockNotificationStateProvider.enabled = true
        
        // Act
        mockNotificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil, userInfo: nil)
        
        // Small delay to allow async operation to complete
        let expectation = XCTestExpectation(description: "Wait for state update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(mockLocalStorage.isNotificationsEnabled)
    }
} 
