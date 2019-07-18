//
//
//  Created by Tapash Majumder on 9/5/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest
import OHHTTPStubs

@testable import IterableSDK

class IterableAPIResponseTests: XCTestCase {
    func testPlatformAndVersionHeaderInGetRequest() {
        let request = IterableRequestUtil.createGetRequest(forApiEndPoint: .ITBL_ENDPOINT_API,
                                                           path: "",
                                                           args: [AnyHashable.ITBL_KEY_API_KEY: "api_key_here"])!
        
        XCTAssertEqual(request.value(forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_PLATFORM), .ITBL_PLATFORM_IOS)
        XCTAssertEqual(request.value(forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_VERSION), IterableAPI.sdkVersion)
    }
    
    func testPlatformAndVersionHeaderInPostRequest() {
        let request = IterableRequestUtil.createPostRequest(forApiEndPoint: .ITBL_ENDPOINT_API,
                                                            path: "",
                                                            args: [AnyHashable.ITBL_HEADER_API_KEY: "api_key_here"],
                                                            body: [:])!
        
        XCTAssertEqual(request.value(forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_PLATFORM), .ITBL_PLATFORM_IOS)
        XCTAssertEqual(request.value(forHTTPHeaderField: AnyHashable.ITBL_HEADER_SDK_VERSION), IterableAPI.sdkVersion)
    }
    
    func testResponseCode200() {
        let xpectation = expectation(description: "response code 200")
        let networkSession = MockNetworkSession(statusCode: 200)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onSuccess { (json) in
            xpectation.fulfill()
        }

        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testResponseCode200WithNoData() {
        let xpectation = expectation(description: "no data")
        let networkSession = MockNetworkSession(statusCode: 200, data: nil)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("no data"))
        }

        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testResponseCode200WithInvalidJson() {
        let xpectation = expectation(description: "invalid json")
        let data = "{'''}}".data(using: .utf8)!
        let networkSession = MockNetworkSession(statusCode: 200, data: data)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))

        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("could not parse json"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testResponseCode400WithoutMessage() { // 400 = bad reqeust
        let xpectation = expectation(description: "400 without message")
        let networkSession = MockNetworkSession(statusCode: 400)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("invalid request"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testResponseCode400WitMessage() {
        let xpectation = expectation(description: "400 with message")
        let networkSession = MockNetworkSession(statusCode: 400, json: ["msg" : "Test error"])
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("test error"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testResponseCode401() { // 401 = unauthorized
        let xpectation = expectation(description: "401")
        let networkSession = MockNetworkSession(statusCode: 401)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("invalid api key"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testResponseCode500() { // 500 = internal server error
        let xpectation = expectation(description: "500")
        let networkSession = MockNetworkSession(statusCode: 500)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("internal server error"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testNon200ResponseCode() { // 302 = redirection
        let xpectation = expectation(description: "non 200")
        let networkSession = MockNetworkSession(statusCode: 302)
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("non-200 response"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testNoNetworkResponse() {
        let xpectation = expectation(description: "no network response")
        let networkSession = NoNetworkNetworkSession()
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        createApiClient(networkSession: networkSession).send(iterableRequest: iterableRequest).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("nsurlerrordomain"))
        }
        
        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    func testNetworkTimeoutResponse() {
        let xpectation = expectation(description: "timeout network response")
        
        let responseTime = 2.0
        let timeout = 0.1
        
        OHHTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return true
        }) { (request) -> OHHTTPStubsResponse in
            let response = OHHTTPStubsResponse(data: try! JSONSerialization.data(withJSONObject: [:], options: []), statusCode: 200, headers: nil)
            response.requestTime = 0.0
            response.responseTime = responseTime
            return response
        }
        let networkSession = URLSession(configuration: URLSessionConfiguration.default)
        
        let iterableRequest = IterableRequest.post(PostRequest(path: "", args: nil, body: [:]))
        
        let apiClient = createApiClient(networkSession: networkSession)
        var urlRequest = apiClient.convertToURLRequest(iterableRequest: iterableRequest)!
        urlRequest.timeoutInterval = timeout

        NetworkHelper.sendRequest(urlRequest, usingSession: networkSession).onError { (sendError) in
            xpectation.fulfill()
            XCTAssert(sendError.reason!.lowercased().contains("timed out"))
        }

        wait(for: [xpectation], timeout: testExpectationTimeout)
    }
    
    private func createApiClient(networkSession: NetworkSessionProtocol) -> ApiClient {
        class AuthProviderImpl: AuthProvider {
            let auth: Auth = Auth(userId: nil, email: "user@example.com")
        }
        
        return ApiClient(apiKey: "",
                         authProvider: AuthProviderImpl(),
                         endPoint: .ITBL_ENDPOINT_API,
                         networkSession: networkSession,
                         deviceId: "")
    }    
}
