import Foundation

/// URLProtocol that intercepts requests forwarded by NetworkMonitorURLProtocol
/// and returns mock responses from MockAPIServer.
///
/// This sits in the URLProtocol chain after NetworkMonitorURLProtocol:
/// SDK request → NetworkMonitorURLProtocol (logs) → MockAPIServerURLProtocol (mocks) → response flows back
///
/// Only intercepts requests that have the NetworkMonitorURLProtocol marker property,
/// so the Network Monitor always captures both request and response.
final class MockAPIServerURLProtocol: URLProtocol {

    private static let networkMonitorKey = "NetworkMonitorURLProtocol"

    override class func canInit(with request: URLRequest) -> Bool {
        // Only intercept when mock server is active
        guard MockAPIServer.shared.isActive else { return false }

        // Only intercept requests forwarded by NetworkMonitorURLProtocol
        // (they have the marker property set to avoid recursion in the monitor)
        guard URLProtocol.property(forKey: networkMonitorKey, in: request) != nil else { return false }

        // Only intercept Iterable API requests
        guard let host = request.url?.host, host.contains("iterable.com") else { return false }

        // Only intercept if we have a mock response for this request
        guard MockAPIServer.shared.mockResponse(for: request) != nil else { return false }

        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let mockResponse = MockAPIServer.shared.mockResponse(for: request),
              let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        // Create HTTP response
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )

        if let response = httpResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        client?.urlProtocol(self, didLoad: mockResponse.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // Responses are synchronous, nothing to cancel
    }
}
