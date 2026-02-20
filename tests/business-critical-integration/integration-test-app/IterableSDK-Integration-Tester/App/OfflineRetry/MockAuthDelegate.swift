import Foundation
import IterableSDK

/// Mock auth delegate that returns fake JWT tokens for testing the
/// offline retry flow without requiring a real JWT-enabled API key.
final class MockAuthDelegate: NSObject, IterableAuthDelegate {

    private(set) var tokenRequestCount = 0
    private(set) var lastFailure: AuthFailure?

    /// Called when a new token is requested — use for UI logging
    var onTokenRequested: (() -> Void)?
    /// Called on auth failure — use for UI logging
    var onAuthFailureCallback: ((AuthFailure) -> Void)?

    func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
        tokenRequestCount += 1
        let count = tokenRequestCount
        print("[MOCK AUTH] Token requested (#\(count)), responding in 0.5s...")

        // Simulate real-world latency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onTokenRequested?()
            completion("mock-jwt-token-\(count)")
            print("[MOCK AUTH] Provided mock token #\(count)")
        }
    }

    func onAuthFailure(_ authFailure: AuthFailure) {
        lastFailure = authFailure
        onAuthFailureCallback?(authFailure)
        print("[MOCK AUTH] Auth failure: \(authFailure.failureReason)")
    }

    func reset() {
        tokenRequestCount = 0
        lastFailure = nil
    }
}
