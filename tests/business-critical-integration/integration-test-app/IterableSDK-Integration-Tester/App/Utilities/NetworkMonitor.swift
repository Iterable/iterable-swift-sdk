import Foundation
import UIKit
import ObjectiveC.runtime

// MARK: - Network Request Model

struct NetworkRequest {
    let id: UUID
    let url: URL
    let method: String
    let headers: [String: String]
    let body: Data?
    let timestamp: Date
    var response: NetworkResponse?
    
    init(request: URLRequest) {
        self.id = UUID()
        self.url = request.url ?? URL(string: "unknown")!
        self.method = request.httpMethod ?? "GET"
        self.headers = request.allHTTPHeaderFields ?? [:]
        
        // Try to capture body from httpBody first, then from httpBodyStream
        if let httpBody = request.httpBody {
            self.body = httpBody
        } else if let bodyStream = request.httpBodyStream {
            // Try to read from stream
            bodyStream.open()
            defer { bodyStream.close() }
            
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            var data = Data()
            while bodyStream.hasBytesAvailable {
                let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data.append(buffer, count: bytesRead)
                } else {
                    break
                }
            }
            self.body = data.isEmpty ? nil : data
        } else {
            self.body = nil
        }
        
        self.timestamp = Date()
    }
    
    init(id: UUID, url: URL, method: String, headers: [String: String], body: Data?, timestamp: Date) {
        self.id = id
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timestamp = timestamp
    }
    
    var statusCodeColor: UIColor {
        guard let response = response else { return .systemOrange }
        switch response.statusCode {
        case 200..<300: return .systemGreen
        case 300..<400: return .systemOrange
        case 400..<500: return .systemRed
        case 500...: return .systemPurple
        default: return .systemGray
        }
    }
    
    var duration: TimeInterval? {
        guard let response = response else { return nil }
        return response.timestamp.timeIntervalSince(timestamp)
    }
}

struct NetworkResponse {
    let statusCode: Int
    let headers: [String: String]
    let data: Data?
    let timestamp: Date
    let error: Error?
    
    init(response: HTTPURLResponse?, data: Data?, error: Error?) {
        self.statusCode = response?.statusCode ?? 0
        self.headers = response?.allHeaderFields as? [String: String] ?? [:]
        self.data = data
        self.timestamp = Date()
        self.error = error
    }
    
    var jsonString: String? {
        guard let data = data else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8)
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }
}

// MARK: - Network Monitor

class NetworkMonitor: NSObject {
    static let shared = NetworkMonitor()

    /// Additional URLProtocol classes to inject into all sessions alongside NetworkMonitorURLProtocol.
    /// Set by MockAPIServer to add MockAPIServerURLProtocol.
    static var additionalProtocolClasses: [AnyClass] = []

    private var requests: [NetworkRequest] = []
    private let queue = DispatchQueue(label: "networkmonitor", attributes: .concurrent)
    
    var onRequestAdded: ((NetworkRequest) -> Void)?
    var onRequestUpdated: ((NetworkRequest) -> Void)?
    
    override private init() {
        super.init()
    }
    
    func startMonitoring() {
        // Register our custom protocol to intercept requests
        URLProtocol.registerClass(NetworkMonitorURLProtocol.self)
        
        // Swizzle URLSessionConfiguration to inject our protocol into ALL sessions
        URLSessionConfiguration.swizzleProtocolClasses()
        
        //print("🔍 NetworkMonitor: Started monitoring with URLProtocol registration and swizzling")
    }
    
    func addRequest(_ request: NetworkRequest) {
        queue.async(flags: .barrier) {
            self.requests.append(request)
            
            DispatchQueue.main.async {
                self.onRequestAdded?(request)
            }
        }
    }
    
    func updateRequest(id: UUID, response: NetworkResponse) {
        queue.async(flags: .barrier) {
            if let index = self.requests.firstIndex(where: { $0.id == id }) {
                self.requests[index].response = response
                
                DispatchQueue.main.async {
                    self.onRequestUpdated?(self.requests[index])
                }
            }
        }
    }
    
    func getAllRequests() -> [NetworkRequest] {
        return queue.sync {
            return requests.reversed() // Show newest first
        }
    }
    
    func clearRequests() {
        queue.async(flags: .barrier) {
            self.requests.removeAll()
        }
    }
}

// MARK: - Custom URL Protocol for Interception

class NetworkMonitorURLProtocol: URLProtocol {
    private var dataTask: URLSessionDataTask?
    private var requestId: UUID?
    
    private static let networkMonitorKey = "NetworkMonitorURLProtocol"
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Avoid infinite recursion
        if URLProtocol.property(forKey: networkMonitorKey, in: request) != nil {
            return false
        }
        
        // Only monitor HTTP/HTTPS requests
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        guard scheme == "http" || scheme == "https" else { return false }
        
        // IMPORTANT: Don't intercept Iterable deep link redirect requests
        // These need to be handled by SDK's custom RedirectNetworkSession delegate
        // to properly capture redirect locations for link unwrapping
        if let urlString = request.url?.absoluteString,
           urlString.contains("/a/") && (urlString.contains("links.") || urlString.contains("iterable.")) {
            print("🔍 URLProtocol: Skipping Iterable deep link redirect request: \(urlString)")
            return false
        }
        
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        // Debug the original request
        print("🔍 ORIGINAL REQUEST DEBUG:")
        print("🔍 Method: \(request.httpMethod ?? "nil")")
        print("🔍 URL: \(request.url?.absoluteString ?? "nil")")
        print("🔍 httpBody: \(request.httpBody != nil ? "\(request.httpBody!.count) bytes" : "nil")")
        print("🔍 httpBodyStream: \(request.httpBodyStream != nil ? "exists" : "nil")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("🔍 Original body content: \(String(bodyString.prefix(200)))")
        }
        
        // Create NSMutableURLRequest properly to avoid recursion
        let mutableRequest = NSMutableURLRequest(url: request.url!)
        mutableRequest.httpMethod = request.httpMethod ?? "GET"
        mutableRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        mutableRequest.cachePolicy = request.cachePolicy
        mutableRequest.timeoutInterval = request.timeoutInterval
        
        // Handle body - convert stream to data if needed
        var capturedBodyData: Data? = nil
        if let httpBody = request.httpBody {
            mutableRequest.httpBody = httpBody
            capturedBodyData = httpBody
            print("🔍 Using httpBody directly")
        } else if let bodyStream = request.httpBodyStream {
            // Read stream into data and set both
            let streamData = readDataFromStream(bodyStream)
            capturedBodyData = streamData
            mutableRequest.httpBody = streamData
            print("🔍 Converted httpBodyStream to httpBody: \(streamData?.count ?? 0) bytes")
        }
        
        // Mark to avoid infinite recursion
        URLProtocol.setProperty(true, forKey: NetworkMonitorURLProtocol.networkMonitorKey, in: mutableRequest)
        
        print("🔍 AFTER COPY:")
        print("🔍 Copied httpBody: \(mutableRequest.httpBody != nil ? "\(mutableRequest.httpBody!.count) bytes" : "nil")")
        print("🔍 Copied httpBodyStream: \(mutableRequest.httpBodyStream != nil ? "exists" : "nil")")
        
        // Create network request with captured body data
        var networkRequest = NetworkRequest(request: mutableRequest as URLRequest)
        // Override body with our captured data if we read from stream
        if let capturedData = capturedBodyData {
            networkRequest = NetworkRequest(
                id: networkRequest.id,
                url: networkRequest.url,
                method: networkRequest.method,
                headers: networkRequest.headers,
                body: capturedData,
                timestamp: networkRequest.timestamp
            )
        }
        requestId = networkRequest.id
        
        // Add request to monitor
        print("📡 NetworkMonitor: Intercepted \(mutableRequest.httpMethod ?? "GET") request to \(networkRequest.url.absoluteString)")
        if let body = mutableRequest.httpBody {
            print("📡 NetworkMonitor: Request body size: \(body.count) bytes")
            if let bodyString = String(data: body, encoding: .utf8) {
                print("📡 NetworkMonitor: Request body preview: \(String(bodyString.prefix(200)))")
            }
        } else {
            print("📡 NetworkMonitor: No request body found")
        }
        NetworkMonitor.shared.addRequest(networkRequest)
        
        // Create session to make actual request
        // IMPORTANT: Use .ephemeral to avoid interfering with SDK's custom session delegates
        let config = URLSessionConfiguration.ephemeral
        // Don't follow redirects automatically - let the SDK handle them
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        dataTask = session.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self, let requestId = self.requestId else { return }
            
            // Create response
            let networkResponse = NetworkResponse(
                response: response as? HTTPURLResponse,
                data: data,
                error: error
            )
            
            // Update monitor
            NetworkMonitor.shared.updateRequest(id: requestId, response: networkResponse)
            
            // Forward to client
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = response {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                
                if let data = data {
                    self.client?.urlProtocol(self, didLoad: data)
                }
                
                self.client?.urlProtocolDidFinishLoading(self)
            }
        }
        
        dataTask?.resume()
    }
    
    override func stopLoading() {
        dataTask?.cancel()
    }
    
    private func readDataFromStream(_ stream: InputStream) -> Data? {
        stream.open()
        defer { stream.close() }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        var data = Data()
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        
        return data.isEmpty ? nil : data
    }
}

// MARK: - URLSessionConfiguration Swizzling

extension URLSessionConfiguration {
    private static var hasSwizzled = false
    
    static func swizzleProtocolClasses() {
        guard !hasSwizzled else { return }
        hasSwizzled = true
        
        swizzleDefault()
        swizzleEphemeral()
        swizzleBackground()
    }
    
    private static func swizzleDefault() {
        let originalMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
        let swizzledMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.swizzled_default))
        
        if let original = originalMethod, let swizzled = swizzledMethod {
            method_exchangeImplementations(original, swizzled)
        }
    }
    
    private static func swizzleEphemeral() {
        let originalMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.ephemeral))
        let swizzledMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.swizzled_ephemeral))
        
        if let original = originalMethod, let swizzled = swizzledMethod {
            method_exchangeImplementations(original, swizzled)
        }
    }
    
    private static func swizzleBackground() {
        let originalMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.background(withIdentifier:)))
        let swizzledMethod = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.swizzled_background(withIdentifier:)))
        
        if let original = originalMethod, let swizzled = swizzledMethod {
            method_exchangeImplementations(original, swizzled)
        }
    }
    
    @objc class func swizzled_default() -> URLSessionConfiguration {
        let config = swizzled_default() // This calls the original method
        config.injectNetworkMonitorProtocol()
        return config
    }
    
    @objc class func swizzled_ephemeral() -> URLSessionConfiguration {
        let config = swizzled_ephemeral() // This calls the original method
        config.injectNetworkMonitorProtocol()
        return config
    }
    
    @objc class func swizzled_background(withIdentifier identifier: String) -> URLSessionConfiguration {
        let config = swizzled_background(withIdentifier: identifier) // This calls the original method
        config.injectNetworkMonitorProtocol()
        return config
    }
    
    private func injectNetworkMonitorProtocol() {
        var protocols = protocolClasses ?? []

        // Only add if not already present
        if !protocols.contains(where: { $0 == NetworkMonitorURLProtocol.self }) {
            protocols.insert(NetworkMonitorURLProtocol.self, at: 0)
        }

        // Append any additional protocol classes (e.g. MockAPIServerURLProtocol)
        for protocolClass in NetworkMonitor.additionalProtocolClasses {
            if !protocols.contains(where: { $0 === protocolClass }) {
                protocols.append(protocolClass)
            }
        }

        protocolClasses = protocols
    }
}
