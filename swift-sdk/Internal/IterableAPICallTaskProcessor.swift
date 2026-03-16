//
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

struct IterableAPICallTaskProcessor: IterableTaskProcessor {
    let networkSession: NetworkSessionProtocol
    let autoRetry: Bool

    init(networkSession: NetworkSessionProtocol,
         dateProvider: DateProviderProtocol = SystemDateProvider(),
         autoRetry: Bool = false) {
        self.networkSession = networkSession
        self.dateProvider = dateProvider
        self.autoRetry = autoRetry
    }

    func process(task: IterableTask) throws -> Pending<IterableTaskResult, IterableTaskError> {
        ITBInfo()
        guard let data = task.data else {
            return IterableTaskError.createErroredFuture(reason: "expecting data")
        }

        let decodedIterableRequest = try JSONDecoder().decode(IterableAPICallRequest.self, from: data)
        let iterableRequest = decodedIterableRequest.addingCreatedAt(task.scheduledAt)

        guard let urlRequest = iterableRequest.convertToURLRequest(sentAt: dateProvider.currentDate, processorType: .offline) else {
            return IterableTaskError.createErroredFuture(reason: "could not convert to url request")
        }

        let result = Fulfill<IterableTaskResult, IterableTaskError>()
        RequestSender.sendRequest(urlRequest, usingSession: networkSession)
            .onSuccess { sendRequestValue in
                ITBInfo("Task finished successfully")
                result.resolve(with: .success(detail: sendRequestValue))
            }
            .onError { sendRequestError in
                if autoRetry && IterableAPICallTaskProcessor.isJWTAuthFailure(sendRequestError: sendRequestError) {
                    ITBInfo("JWT auth failure, retaining task for retry")
                    result.resolve(with: .failureWithRetry(retryAfter: nil, detail: sendRequestError))
                } else if IterableAPICallTaskProcessor.isPermanentFailure(sendRequestError: sendRequestError) {
                    ITBInfo("Permanent client error (HTTP \(sendRequestError.httpStatusCode ?? 0)), deleting task")
                    result.resolve(with: .failureWithNoRetry(detail: sendRequestError))
                } else {
                    ITBInfo("Transient failure, retaining task for retry")
                    result.resolve(with: .failureWithRetry(retryAfter: nil, detail: sendRequestError))
                }
            }

        return result
    }

    private let dateProvider: DateProviderProtocol
    
    /// Returns true for permanent client errors (4xx, excluding 429) that should NOT be retried.
    /// Network-level errors (no HTTP status), server errors (5xx), and 429 (rate limit) are transient.
    private static func isPermanentFailure(sendRequestError: SendRequestError) -> Bool {
        guard let statusCode = sendRequestError.httpStatusCode else {
            // No HTTP status code → network-level error (timeout, DNS, connection reset).
            // Always transient.
            return false
        }
        // 429 Too Many Requests is transient — the server is asking us to retry later.
        if statusCode == 429 {
            return false
        }
        return statusCode >= 400 && statusCode < 500
    }

    static func isJWTAuthFailure(sendRequestError: SendRequestError) -> Bool {
        sendRequestError.httpStatusCode == 401 && RequestProcessorUtil.matchesJWTErrorCode(sendRequestError.iterableCode)
    }
}
