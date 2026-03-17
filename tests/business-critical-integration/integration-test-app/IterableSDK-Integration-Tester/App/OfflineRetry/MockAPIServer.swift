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

    /// Returns a mock response for the given request, or nil to pass through to real network.
    func mockResponse(for request: URLRequest) -> MockResponse? {
        guard isActive, let url = request.url else { return nil }

        let path = url.path

        // GET requests (getMessages, etc.) get a generic empty success
        // so they don't hit the real API with fake JWT tokens.
        // getRemoteConfiguration is handled separately by ConfigOverrideURLProtocol.
        if request.httpMethod == "GET" {
            if path.contains("getRemoteConfiguration") {
                return nil // let ConfigOverrideURLProtocol handle it
            }
            return emptySuccessResponse(for: path)
        }

        // API endpoints — depends on response mode
        guard url.host?.contains("iterable.com") == true else { return nil }

        requestCount += 1

        switch apiResponseMode {
        case .normal:
            return nil

        case .jwt401:
            return jwt401Response()

        case .server500:
            return server500Response(for: path)

        case .connectionError:
            return connectionErrorResponse()
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

    private func server500Response(for path: String) -> MockResponse {
        let json: [String: Any] = [
            "code": "InternalServerError",
            "msg": "Internal server error"
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()
        print("[MOCK SERVER] Returning 500 for \(path)")
        return MockResponse(
            statusCode: 500,
            data: data,
            headers: ["Content-Type": "application/json"]
        )
    }

    private func connectionErrorResponse() -> MockResponse {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "Mock: not connected to the Internet"]
        )
        print("[MOCK SERVER] Returning connection error")
        return MockResponse(
            statusCode: 0,
            data: Data(),
            headers: [:],
            error: error
        )
    }

    private func emptySuccessResponse(for path: String) -> MockResponse {
        let data = (try? JSONSerialization.data(withJSONObject: [String: Any]())) ?? Data()
        print("[MOCK SERVER] Returning 200 empty for GET \(path)")
        return MockResponse(
            statusCode: 200,
            data: data,
            headers: ["Content-Type": "application/json"]
        )
    }
}
