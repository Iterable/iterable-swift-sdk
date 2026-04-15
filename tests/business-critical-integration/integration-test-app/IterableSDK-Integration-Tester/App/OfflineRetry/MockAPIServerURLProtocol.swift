import Foundation
import IterableSDK

/// URLProtocol that routes Iterable API requests per MockAPIServer.apiResponseMode:
/// - .normal          → proxy to real Iterable API with the SDK's JWT
/// - .jwt401          → proxy to real Iterable API, but with Authorization swapped
///                      to an expired JWT (real backend returns a real 401
///                      InvalidJwtPayload)
/// - .server500       → local synthesized 500
/// - .connectionError → local synthesized NSURLErrorNotConnectedToInternet
///
/// Registered globally via URLProtocol.registerClass() and injected into
/// URLSessionConfiguration via swizzling, so it intercepts requests from every
/// URLSession — including the SDK's offline task queue.
final class MockAPIServerURLProtocol: URLProtocol {

    private static let handledKey = "MockAPIServerURLProtocol.handled"

    private var forwardTask: URLSessionDataTask?

    override class func canInit(with request: URLRequest) -> Bool {
        guard MockAPIServer.shared.isActive else { return false }
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
        case .normal:
            proxyToRealBackend(swapExpiredJwt: false)
        case .jwt401:
            proxyToRealBackend(swapExpiredJwt: true)
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

    // MARK: - Proxy to real backend (mirrors Android MockServer.proxy())

    private func proxyToRealBackend(swapExpiredJwt: Bool) {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        // Mark handled so our canInit skips the re-issued request (avoids recursion).
        URLProtocol.setProperty(true, forKey: MockAPIServerURLProtocol.handledKey, in: mutableRequest)

        if swapExpiredJwt {
            // Match MockAuthDelegate's email source so the forged expired JWT
            // identifies the same user the SDK signed for — otherwise Iterable
            // can return `jwtUserIdentifiersMismatched` instead of
            // `InvalidJwtPayload`, exercising the wrong retry branch.
            let email = IterableAPI.email ?? AppDelegate.currentTestEmail ?? ""
            let secret = MockAPIServer.shared.jwtSecret ?? ""
            let expired = JwtHelper.generateToken(email: email, secret: secret, expired: true) ?? "expired"
            mutableRequest.setValue("Bearer \(expired)", forHTTPHeaderField: "Authorization")
        }

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
                let tag = swapExpiredJwt ? " (expired JWT)" : ""
                LogStore.shared.log("📤 \(endpoint) → \(httpResponse.statusCode) \(emoji)\(tag)")
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
