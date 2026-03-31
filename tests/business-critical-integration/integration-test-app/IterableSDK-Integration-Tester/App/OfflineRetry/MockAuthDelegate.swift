import Foundation
import IterableSDK

/// Auth delegate that generates real JWT tokens locally using the project's
/// JWT secret. Tokens are signed with HMAC-SHA256 and accepted by the real
/// Iterable API.
///
/// Set `forceExpired = true` to generate already-expired tokens, which causes
/// the real API to return 401 InvalidJwtPayload.
final class MockAuthDelegate: NSObject, IterableAuthDelegate {

    private let jwtSecret: String
    private(set) var tokenRequestCount = 0
    private(set) var lastFailure: AuthFailure?
    /// The most recently generated token — use for UI countdown display
    private(set) var lastGeneratedToken: String?

    /// When true, generates expired JWTs so real API returns 401.
    var forceExpired: Bool = false

    /// Called when a new token is generated — use for UI logging
    var onTokenRequested: ((String?) -> Void)?
    /// Called on auth failure — use for UI logging
    var onAuthFailureCallback: ((AuthFailure) -> Void)?

    init(jwtSecret: String) {
        self.jwtSecret = jwtSecret
        super.init()
    }

    func onAuthTokenRequested(completion: @escaping AuthTokenRetrievalHandler) {
        tokenRequestCount += 1
        let count = tokenRequestCount

        guard let email = IterableAPI.email ?? AppDelegate.currentTestEmail else {
            print("[AUTH] Token #\(count): no email set, returning nil")
            LogStore.shared.log("🔑 Auth: no email, returning nil")
            onTokenRequested?(nil)
            completion(nil)
            return
        }

        let token = JwtHelper.generateToken(
            email: email,
            secret: jwtSecret,
            expired: forceExpired
        )

        lastGeneratedToken = token

        let expiryLabel = forceExpired ? "EXPIRED" : JwtHelper.expiry.rawValue
        print("[AUTH] Token #\(count): generated for \(email) (\(expiryLabel))")
        LogStore.shared.log("🔑 Auth: JWT generated for \(email) (\(expiryLabel))")
        onTokenRequested?(token) // callback only — don't double-log
        completion(token)
    }

    func onAuthFailure(_ authFailure: AuthFailure) {
        lastFailure = authFailure
        onAuthFailureCallback?(authFailure)

        // If no email is set yet, auth failures are expected (pre-login state).
        // Don't log them as errors — matches Android behavior where null token
        // before login is handled gracefully.
        let hasEmail = (IterableAPI.email ?? AppDelegate.currentTestEmail) != nil
        if hasEmail {
            print("[AUTH] Failure: \(authFailure.failureReason)")
            LogStore.shared.log("❌ Auth failure: \(authFailure.failureReason)")
        } else {
            print("[AUTH] Failure (no email set, expected): \(authFailure.failureReason)")
        }
    }

    func reset() {
        tokenRequestCount = 0
        lastFailure = nil
        forceExpired = false
    }
}
