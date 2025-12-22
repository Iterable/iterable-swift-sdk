import Foundation
@testable import IterableSDK

// MARK: - Mock URL Delegate

class MockIterableURLDelegate: IterableURLDelegate {
    
    // MARK: - Properties
    
    var handleCallCount = 0
    var lastHandledURL: URL?
    var lastContext: IterableActionContext?
    var shouldReturnTrue = true
    var capturedURLs: [URL] = []
    var capturedContexts: [IterableActionContext] = []
    
    // Callbacks for verification
    var onHandleURL: ((URL, IterableActionContext) -> Bool)?
    
    // MARK: - IterableURLDelegate
    
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        handleCallCount += 1
        lastHandledURL = url
        lastContext = context
        capturedURLs.append(url)
        capturedContexts.append(context)
        
        print("🎭 MockIterableURLDelegate.handle called")
        print("   URL: \(url.absoluteString)")
        print("   Context: \(context)")
        print("   Call count: \(handleCallCount)")
        
        // Call custom callback if set
        if let callback = onHandleURL {
            return callback(url, context)
        }
        
        return shouldReturnTrue
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        handleCallCount = 0
        lastHandledURL = nil
        lastContext = nil
        capturedURLs.removeAll()
        capturedContexts.removeAll()
        onHandleURL = nil
        shouldReturnTrue = true
        print("🔄 MockIterableURLDelegate reset")
    }
    
    func wasCalledWith(url: URL) -> Bool {
        return capturedURLs.contains(where: { $0.absoluteString == url.absoluteString })
    }
    
    func wasCalledWith(scheme: String) -> Bool {
        return capturedURLs.contains(where: { $0.scheme == scheme })
    }
    
    func wasCalledWith(host: String) -> Bool {
        return capturedURLs.contains(where: { $0.host == host })
    }
    
    func printCallHistory() {
        print("📝 MockIterableURLDelegate Call History:")
        print("   Total calls: \(handleCallCount)")
        for (index, url) in capturedURLs.enumerated() {
            print("   [\(index)] \(url.absoluteString)")
        }
    }
}

// MARK: - Mock Custom Action Delegate

class MockIterableCustomActionDelegate: IterableCustomActionDelegate {
    
    // MARK: - Properties
    
    var handleCallCount = 0
    var lastHandledAction: IterableAction?
    var lastContext: IterableActionContext?
    var shouldReturnTrue = true
    var capturedActions: [IterableAction] = []
    var capturedContexts: [IterableActionContext] = []
    
    // Callbacks for verification
    var onHandleAction: ((IterableAction, IterableActionContext) -> Bool)?
    
    // MARK: - IterableCustomActionDelegate
    
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        handleCallCount += 1
        lastHandledAction = action
        lastContext = context
        capturedActions.append(action)
        capturedContexts.append(context)
        
        print("🎭 MockIterableCustomActionDelegate.handle called")
        print("   Action type: \(action.type)")
        print("   Action data: \(action.data ?? "nil")")
        print("   Context: \(context)")
        print("   Call count: \(handleCallCount)")
        
        // Call custom callback if set
        if let callback = onHandleAction {
            return callback(action, context)
        }
        
        return shouldReturnTrue
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        handleCallCount = 0
        lastHandledAction = nil
        lastContext = nil
        capturedActions.removeAll()
        capturedContexts.removeAll()
        onHandleAction = nil
        shouldReturnTrue = true
        print("🔄 MockIterableCustomActionDelegate reset")
    }
    
    func wasCalledWith(actionType: String) -> Bool {
        return capturedActions.contains(where: { $0.type == actionType })
    }
    
    func wasCalledWith(actionData: String) -> Bool {
        return capturedActions.contains(where: { $0.data == actionData })
    }
    
    func getActionTypes() -> [String] {
        return capturedActions.map { $0.type }
    }
    
    func printCallHistory() {
        print("📝 MockIterableCustomActionDelegate Call History:")
        print("   Total calls: \(handleCallCount)")
        for (index, action) in capturedActions.enumerated() {
            print("   [\(index)] Type: \(action.type), Data: \(action.data ?? "nil")")
        }
    }
}

