import Foundation

/// URLProtocol that intercepts only `getRemoteConfiguration` requests
/// and returns overridden flag values. Independent of MockAPIServer.
///
/// This allows config overrides (offlineMode, autoRetry) to work
/// whether or not the mock JWT server is active.
final class ConfigOverrideURLProtocol: URLProtocol {

    private static let handledKey = "ConfigOverrideURLProtocol.handled"

    override class func canInit(with request: URLRequest) -> Bool {
        // Don't handle if already handled (avoid recursion)
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }

        // Only intercept when overrides are enabled
        guard ConfigOverrideManager.shared.isEnabled else { return false }

        // Only intercept getRemoteConfiguration
        guard let path = request.url?.path, path.contains("mobile/getRemoteConfiguration") else { return false }

        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Mark as handled
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: ConfigOverrideURLProtocol.handledKey, in: mutableRequest)

        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        let manager = ConfigOverrideManager.shared
        let json: [String: Any] = [
            "offlineMode": manager.overrideOfflineMode,
            "autoRetry": manager.overrideAutoRetry
        ]
        let data = (try? JSONSerialization.data(withJSONObject: json)) ?? Data()

        print("[CONFIG OVERRIDE] Remote config → offlineMode: \(manager.overrideOfflineMode), autoRetry: \(manager.overrideAutoRetry)")

        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )

        if let response = httpResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
