import Foundation

final class MockAPIServer {
    static let shared = MockAPIServer()

    // MARK: - API Response Mode (controlled by JWT Auth Retry panel)
    //
    // - .normal          → NOT intercepted; SDK talks to api.iterable.com directly
    //                      (MockAPIServerURLProtocol.canInit returns false)
    // - .jwt401          → intercepted and proxied to api.iterable.com with the
    //                      Authorization header swapped to an expired JWT; real
    //                      backend returns a real 401 InvalidJwtPayload
    // - .server500       → local synthesized 500 (can't force 500 from prod)
    // - .connectionError → local synthesized connection error (iOS equivalent of
    //                      Android's DEAD_PORT trick)

    enum APIResponseMode: String, CaseIterable {
        case normal = "Normal"
        case jwt401 = "401"
        case server500 = "500"
        case connectionError = "Conn Err"
    }

    var apiResponseMode: APIResponseMode = .normal

    /// JWT signing secret used by MockAPIServerURLProtocol when forging the
    /// expired token for `.jwt401`. Populated by AppDelegate during SDK re-init.
    var jwtSecret: String?

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

    /// Returns a locally-synthesized mock response for `.server500` / `.connectionError`.
    /// For `.normal` / `.jwt401` the request is proxied to the real Iterable API by
    /// MockAPIServerURLProtocol; this method returns nil in those cases.
    func mockResponse(for request: URLRequest) -> MockResponse? {
        guard isActive, let url = request.url else { return nil }

        if url.path.contains("getRemoteConfiguration") { return nil }
        guard url.host?.contains("iterable.com") == true else { return nil }

        requestCount += 1

        let endpoint = url.path.split(separator: "/").last.map(String.init) ?? url.path

        switch apiResponseMode {
        case .normal, .jwt401:
            return nil // handled by proxy
        case .server500:
            return server500Response(endpoint: endpoint)
        case .connectionError:
            return connectionErrorResponse()
        }
    }

    // MARK: - Response Helpers

    private func server500Response(endpoint: String) -> MockResponse {
        let json: [String: Any] = [
            "code": "InternalServerError",
            "msg": "Mock 500 response"
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        print("[MOCK SERVER] 500 \(endpoint)")
        LogStore.shared.log("📤 \(endpoint) → 500 ❌ (mocked)")
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
