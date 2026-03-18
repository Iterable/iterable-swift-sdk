import CryptoKit
import Foundation

enum JwtExpiry: String, CaseIterable {
    case oneSec = "1s"
    case thirtySec = "30s"
    case oneMin = "60s"
    case oneHour = "1hr"

    var seconds: TimeInterval {
        switch self {
        case .oneSec: return 1
        case .thirtySec: return 30
        case .oneMin: return 60
        case .oneHour: return 3600
        }
    }
}

struct JwtHelper {
    static var expiry: JwtExpiry = .thirtySec

    /// Generates a signed JWT for the given email using HMAC-SHA256.
    /// Returns nil if the secret is empty.
    static func generateToken(email: String, secret: String, expired: Bool = false) -> String? {
        guard !secret.isEmpty else { return nil }

        let now = Date()
        let exp: Date
        if expired {
            // Already expired — real Iterable API will return 401
            exp = now.addingTimeInterval(-10)
        } else {
            exp = now.addingTimeInterval(expiry.seconds)
        }

        let header: [String: Any] = ["alg": "HS256", "typ": "JWT"]
        let payload: [String: Any] = [
            "email": email,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(exp.timeIntervalSince1970)
        ]

        guard let headerData = try? JSONSerialization.data(withJSONObject: header),
              let payloadData = try? JSONSerialization.data(withJSONObject: payload) else {
            return nil
        }

        let headerB64 = headerData.base64URLEncoded()
        let payloadB64 = payloadData.base64URLEncoded()
        let signingInput = "\(headerB64).\(payloadB64)"

        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(signingInput.utf8), using: key)
        let signatureB64 = Data(signature).base64URLEncoded()

        return "\(signingInput).\(signatureB64)"
    }

    /// Decodes the expiration from a JWT token and returns seconds remaining.
    /// Returns nil if token is invalid or has no exp claim.
    static func remainingSeconds(token: String) -> TimeInterval? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }

        // Base64URL decode the payload
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad to multiple of 4
        while base64.count % 4 != 0 { base64.append("=") }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? Int else {
            return nil
        }

        return TimeInterval(exp) - Date().timeIntervalSince1970
    }

    static func remainingLabel(token: String?) -> String {
        guard let token = token, let remaining = remainingSeconds(token: token) else {
            return "No Token"
        }
        if remaining <= 0 { return "Expired" }
        let secs = Int(remaining)
        if secs >= 60 {
            return "\(secs / 60)m\(secs % 60)s"
        }
        return "\(secs)s"
    }
}

extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
