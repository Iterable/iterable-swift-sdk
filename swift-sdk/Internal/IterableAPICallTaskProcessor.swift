//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableAPICallTaskProcessor: IterableTaskProcessor {
    let networkSession: NetworkSessionProtocol
    
    init(networkSession: NetworkSessionProtocol, dateProvider: DateProviderProtocol = SystemDateProvider()) {
        self.networkSession = networkSession
        self.dateProvider = dateProvider
    }
    
    func process(task: IterableTask) throws -> Pending<IterableTaskResult, IterableTaskError> {
        ITBInfo()
        guard let data = task.data else {
            return IterableTaskError.createErroredFuture(reason: "expecting data")
        }
        
        let decodedIterableRequest = try JSONDecoder().decode(IterableAPICallRequest.self, from: data)
        let iterableRequest = decodedIterableRequest.addingCreatedAt(task.scheduledAt)
        
        guard let urlRequest = iterableRequest.convertToURLRequest(sentAt: dateProvider.currentDate, processorType: .offline) else {
            let endpoint = decodedIterableRequest.endpoint
            let path = decodedIterableRequest.getPath()
            let errorMessage = "Could not convert to URL request - endpoint: '\(endpoint)', path: '\(path)'"
            ITBError(errorMessage)
            return IterableTaskError.createErroredFuture(reason: errorMessage)
        }
        
        let result = Fulfill<IterableTaskResult, IterableTaskError>()
        RequestSender.sendRequest(urlRequest, usingSession: networkSession)
            .onSuccess { sendRequestValue in
                ITBInfo("Task finished successfully")
                result.resolve(with: .success(detail: sendRequestValue))
            }
            .onError { sendRequestError in
                if IterableAPICallTaskProcessor.isNetworkUnavailable(sendRequestError: sendRequestError) {
                    ITBInfo("Network is unavailable")
                    result.resolve(with: .failureWithRetry(retryAfter: nil, detail: sendRequestError))
                } else {
                    ITBInfo("Unrecoverable error")
                    result.resolve(with: .failureWithNoRetry(detail: sendRequestError))
                }
            }
        
        return result
    }
    
    private let dateProvider: DateProviderProtocol
    
    private static func isNetworkUnavailable(sendRequestError: SendRequestError) -> Bool {
        // Check for NSURLError codes that indicate network issues
        if let nsError = sendRequestError.originalError as? NSError {
            if nsError.domain == NSURLErrorDomain {
                let networkErrorCodes: Set<Int> = [
                    NSURLErrorNotConnectedToInternet, // -1009
                    NSURLErrorNetworkConnectionLost,  // -1005
                    NSURLErrorTimedOut,               // -1001
                    NSURLErrorCannotConnectToHost,    // -1004
                    NSURLErrorDNSLookupFailed,        // -1006
                    NSURLErrorDataNotAllowed,         // -1020 (cellular data disabled)
                    NSURLErrorInternationalRoamingOff // -1018
                ]
                if networkErrorCodes.contains(nsError.code) {
                    ITBInfo("Network error detected: code=\(nsError.code), description=\(nsError.localizedDescription)")
                    return true
                }
            }
        }
        
        // Fallback to string check for other network-related errors
        if let originalError = sendRequestError.originalError {
            let description = originalError.localizedDescription.lowercased()
            let isNetworkError = description.contains("offline") || 
                                description.contains("network") ||
                                description.contains("internet") ||
                                description.contains("connection")
            if isNetworkError {
                ITBInfo("Network error detected via description: \(originalError.localizedDescription)")
            }
            return isNetworkError
        }
        
        return false
    }
}
