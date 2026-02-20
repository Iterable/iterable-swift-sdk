import Foundation

final class MockAPIServer {
    static let shared = MockAPIServer()

    // MARK: - Remote Config Overrides (controlled by Remote Config Override panel)

    var overrideOfflineMode: Bool = true
    var overrideAutoRetry: Bool = true

    // MARK: - API Response Mode (controlled by Offline Retry panel)

    enum APIResponseMode: String, CaseIterable {
        case passThrough = "Pass Through"
        case jwt401ThenSuccess = "401 > Success"
        case alwaysJwt401 = "Always 401"
        case alwaysSuccess = "Always 200"
    }

    var apiResponseMode: APIResponseMode = .jwt401ThenSuccess

    // MARK: - State

    private(set) var isActive: Bool = false
    private(set) var authHasRefreshed: Bool = false
    private(set) var requestCount: Int = 0
    private var authObserver: NSObjectProtocol?

    private init() {}

    // MARK: - Activation

    func activate() {
        guard !isActive else { return }
        isActive = true
        authHasRefreshed = false
        requestCount = 0

        NetworkMonitor.additionalProtocolClasses = [MockAPIServerURLProtocol.self]

        authObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("itbl_auth_token_refreshed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.authHasRefreshed = true
            print("[MOCK SERVER] Auth token refreshed — switching to success responses")
        }

        print("[MOCK SERVER] Activated")
    }

    func deactivate() {
        guard isActive else { return }
        isActive = false
        authHasRefreshed = false
        requestCount = 0

        NetworkMonitor.additionalProtocolClasses = []

        if let observer = authObserver {
            NotificationCenter.default.removeObserver(observer)
            authObserver = nil
        }

        print("[MOCK SERVER] Deactivated")
    }

    func resetAuthState() {
        authHasRefreshed = false
    }

    // MARK: - Mock Response Generation

    struct MockResponse {
        let statusCode: Int
        let data: Data
        let headers: [String: String]
    }

    /// Returns a mock response for the given request, or nil to pass through to real network.
    func mockResponse(for request: URLRequest) -> MockResponse? {
        guard isActive, let url = request.url else { return nil }

        let path = url.path

        // Remote config endpoint — always return overridden values
        if path.contains("mobile/getRemoteConfiguration") {
            requestCount += 1
            let json: [String: Any] = [
                "offlineMode": overrideOfflineMode,
                "autoRetry": overrideAutoRetry
            ]
            let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
            print("[MOCK SERVER] Remote config → offlineMode: \(overrideOfflineMode), autoRetry: \(overrideAutoRetry)")
            return MockResponse(
                statusCode: 200,
                data: data,
                headers: ["Content-Type": "application/json"]
            )
        }

        // API endpoints — depends on response mode
        guard url.host?.contains("iterable.com") == true else { return nil }

        switch apiResponseMode {
        case .passThrough:
            return nil

        case .jwt401ThenSuccess:
            requestCount += 1
            if authHasRefreshed {
                return successResponse(for: path)
            } else {
                return jwt401Response()
            }

        case .alwaysJwt401:
            requestCount += 1
            return jwt401Response()

        case .alwaysSuccess:
            requestCount += 1
            return successResponse(for: path)
        }
    }

    // MARK: - Response Helpers

    private func jwt401Response() -> MockResponse {
        let json: [String: Any] = [
            "code": "InvalidJwtPayload",
            "msg": "Invalid JWT payload"
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        print("[MOCK SERVER] Returning 401 JWT error")
        return MockResponse(
            statusCode: 401,
            data: data,
            headers: ["Content-Type": "application/json"]
        )
    }

    private func successResponse(for path: String) -> MockResponse {
        let json: [String: Any] = [
            "msg": "success",
            "code": "Success"
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        print("[MOCK SERVER] Returning 200 success for \(path)")
        return MockResponse(
            statusCode: 200,
            data: data,
            headers: ["Content-Type": "application/json"]
        )
    }
}
