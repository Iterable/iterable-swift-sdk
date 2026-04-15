import Foundation
import IterableSDK

/// URLProtocol that routes Iterable API requests per MockAPIServer.apiResponseMode:
/// - .normal          → NOT intercepted; SDK talks to api.iterable.com directly
/// - .jwt401          → intercepted and proxied to api.iterable.com with the
///                      Authorization header rewritten to an expired JWT, so the
///                      real backend returns a real 401 InvalidJwtPayload
/// - .server500       → local synthesized 500
/// - .connectionError → local synthesized NSURLErrorNotConnectedToInternet
///
/// Registered globally via URLProtocol.registerClass() and injected into
/// URLSessionConfiguration via swizzling, so it's in the chain for every
/// URLSession — but it opts out (canInit → false) when the mode is .normal.
final class MockAPIServerURLProtocol: URLProtocol {

    private static let handledKey = "MockAPIServerURLProtocol.handled"

    private var forwardTask: URLSessionDataTask?

    override class func canInit(with request: URLRequest) -> Bool {
        guard MockAPIServer.shared.isActive else { return false }

        // Normal mode = the whole point is to let the SDK hit the real backend.
        // Opt out of interception entirely so URLSession routes the request
        // straight to api.iterable.com — no proxying required.
        guard MockAPIServer.shared.apiResponseMode != .normal else { return false }

        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }
        guard let host = request.url?.host, host.contains("iterable.com") else { return false }
        guard MockAPIServer.shared.shouldIntercept(request: request) else { return false }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        switch MockAPIServer.shared.apiResponseMode {
        case .server500, .connectionError:
            serveLocal()
        case .jwt401:
            proxyWithExpiredJwt()
        case .normal:
            // canInit returns false for .normal, so this is unreachable — but
            // belt-and-suspenders in case the mode flips between canInit and here.
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        forwardTask?.cancel()
        forwardTask = nil
    }

    // MARK: - Local synthesis (500 / connection error only)

    private func serveLocal() {
        guard let mockResponse = MockAPIServer.shared.mockResponse(for: request),
              let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        if let error = mockResponse.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        ) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        client?.urlProtocol(self, didLoad: mockResponse.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    // MARK: - Proxy with expired JWT (.jwt401 only)

    private func proxyWithExpiredJwt() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        // Mark handled so our canInit skips the re-issued request (avoids recursion).
        URLProtocol.setProperty(true, forKey: MockAPIServerURLProtocol.handledKey, in: mutableRequest)

        // Match MockAuthDelegate's email source so the forged expired JWT
        // identifies the same user the SDK signed for — otherwise Iterable
        // can return `jwtUserIdentifiersMismatched` instead of
        // `InvalidJwtPayload`, exercising the wrong retry branch.
        let email = IterableAPI.email ?? AppDelegate.currentTestEmail ?? ""
        let secret = MockAPIServer.shared.jwtSecret ?? ""
        let expired = JwtHelper.generateToken(email: email, secret: secret, expired: true) ?? "expired"
        mutableRequest.setValue("Bearer \(expired)", forHTTPHeaderField: "Authorization")

        let endpoint = request.url?.path.split(separator: "/").last.map(String.init)
            ?? request.url?.path
            ?? "?"

        let task = URLSession.shared.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                // stopLoading() cancels the forwarded task; URLProtocol contract
                // forbids further client callbacks after that, so swallow the
                // cancellation instead of surfacing a false-negative failure.
                if (error as NSError).code == NSURLErrorCancelled { return }

                LogStore.shared.log("📤 \(endpoint) → error: \(error.localizedDescription)")
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let emoji = (200..<300).contains(httpResponse.statusCode) ? "✅" : "❌"
                LogStore.shared.log("📤 \(endpoint) → \(httpResponse.statusCode) \(emoji) (expired JWT)")
                self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            }

            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }

            self.client?.urlProtocolDidFinishLoading(self)
        }
        self.forwardTask = task
        task.resume()
    }
}
