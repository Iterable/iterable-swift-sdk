import Foundation

/// URLProtocol that intercepts Iterable API requests and returns
/// mock responses from MockAPIServer.
///
/// Registered globally via URLProtocol.registerClass() and also
/// injected into URLSessionConfiguration via swizzling, so it
/// intercepts requests from ALL URLSessions including the SDK's
/// offline task queue.
final class MockAPIServerURLProtocol: URLProtocol {

    private static let handledKey = "MockAPIServerURLProtocol.handled"

    override class func canInit(with request: URLRequest) -> Bool {
        // Only intercept when mock server is active
        guard MockAPIServer.shared.isActive else { return false }

        // Don't handle if already handled (prevent double-handling)
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }

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
        // Mark as handled
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: MockAPIServerURLProtocol.handledKey, in: mutableRequest)

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
