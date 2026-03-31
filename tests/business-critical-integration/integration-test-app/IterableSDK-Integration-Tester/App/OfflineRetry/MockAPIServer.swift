import Foundation

final class MockAPIServer {
    static let shared = MockAPIServer()

    // MARK: - API Response Mode (controlled by JWT Auth Retry panel)

    enum APIResponseMode: String, CaseIterable {
        case normal = "Normal"
        case jwt401 = "401"
        case server500 = "500"
        case connectionError = "Conn Err"
    }

    var apiResponseMode: APIResponseMode = .normal

    // MARK: - State

    private(set) var isActive: Bool = false
    private(set) var requestCount: Int = 0
    private var authObserver: NSObjectProtocol?

    private init() {}

    // MARK: - Activation

    func activate() {
        guard !isActive else { return }
        isActive = true
        requestCount = 0

        NetworkMonitor.registerProtocolClass(MockAPIServerURLProtocol.self)

        print("[MOCK SERVER] Activated")
    }

    func deactivate() {
        guard isActive else { return }
        isActive = false
        requestCount = 0

        NetworkMonitor.unregisterProtocolClass(MockAPIServerURLProtocol.self)

        if let observer = authObserver {
            NotificationCenter.default.removeObserver(observer)
            authObserver = nil
        }

        print("[MOCK SERVER] Deactivated")
    }

    // MARK: - Mock Response Generation

    struct MockResponse {
        let statusCode: Int
        let data: Data
        let headers: [String: String]
        let error: Error? // non-nil for connection errors

        init(statusCode: Int, data: Data, headers: [String: String], error: Error? = nil) {
            self.statusCode = statusCode
            self.data = data
            self.headers = headers
            self.error = error
        }
    }

    /// Returns true if this request should be intercepted (not passed through to real network).
    func shouldIntercept(request: URLRequest) -> Bool {
        guard isActive, let url = request.url else { return false }

        // getRemoteConfiguration always passes through to ConfigOverrideURLProtocol
        if url.path.contains("getRemoteConfiguration") {
            return false
        }

        // All other Iterable API requests are intercepted
        guard url.host?.contains("iterable.com") == true else { return false }
        return true
    }

    /// Returns a mock response for the given request, or nil to pass through.
    /// Matches Android behavior: same response mode applies to ALL requests
    /// (GET and POST) uniformly. Only getRemoteConfiguration is exempt.
    func mockResponse(for request: URLRequest) -> MockResponse? {
        guard isActive, let url = request.url else { return nil }

        let path = url.path

        // getRemoteConfiguration handled by ConfigOverrideURLProtocol
        if path.contains("getRemoteConfiguration") {
            return nil
        }

        // Non-Iterable requests pass through
        guard url.host?.contains("iterable.com") == true else { return nil }

        requestCount += 1

        let endpoint = path.split(separator: "/").last.map(String.init) ?? path

        // Same response mode for GET and POST — matches Android MockServer.serve()
        switch apiResponseMode {
        case .normal:
            return successResponse(for: path)

        case .jwt401:
            return jwt401Response(endpoint: endpoint)

        case .server500:
            return server500Response(endpoint: endpoint)

        case .connectionError:
            return connectionErrorResponse()
        }
    }

    // MARK: - Response Helpers (matching Android response bodies)

    private func successResponse(for path: String) -> MockResponse {
        // Return endpoint-specific valid JSON for Decodable types,
        // generic success for everything else (matching Android).
        let json: [String: Any]
        if path.contains("embedded-messaging/messages") {
            json = ["placements": []]
        } else if path.contains("getMessages") {
            json = ["inAppMessages": []]
        } else {
            json = ["msg": "Success", "code": "Success", "successCount": 1]
        }
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        let endpoint = path.split(separator: "/").last.map(String.init) ?? path
        print("[MOCK SERVER] 200 \(endpoint)")
        LogStore.shared.log("📤 \(endpoint) → 200 ✅")
        return MockResponse(
            statusCode: 200,
            data: data,
            headers: ["Content-Type": "application/json", "Connection": "close"]
        )
    }

    private func jwt401Response(endpoint: String) -> MockResponse {
        let json: [String: Any] = [
            "code": "InvalidJwtPayload",
            "msg": "JWT token is expired"
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        print("[MOCK SERVER] 401 \(endpoint)")
        LogStore.shared.log("📤 \(endpoint) → 401 ❌")
        return MockResponse(
            statusCode: 401,
            data: data,
            headers: ["Content-Type": "application/json", "Connection": "close"]
        )
    }

    private func server500Response(endpoint: String) -> MockResponse {
        let json: [String: Any] = [
            "code": "InternalServerError",
            "msg": "Mock 500 response"
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        print("[MOCK SERVER] 500 \(endpoint)")
        LogStore.shared.log("📤 \(endpoint) → 500 ❌")
        return MockResponse(
            statusCode: 500,
            data: data,
            headers: ["Content-Type": "application/json", "Connection": "close"]
        )
    }

    private func connectionErrorResponse() -> MockResponse {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "Mock: not connected to the Internet"]
        )
        print("[MOCK SERVER] Connection error")
        LogStore.shared.log("📤 → Conn Err ❌")
        return MockResponse(
            statusCode: 0,
            data: Data(),
            headers: [:],
            error: error
        )
    }
}
